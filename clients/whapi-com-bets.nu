# Auto-generated client for Bets API v2.0.0
# Source: https://api.apis.guru/v2/specs/whapi.com/bets/2.0.0/openapi.json
# Auth: --token flag or $env.BETS_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/bets"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BETS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox.whapi.com/v2/bets"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bet-complex create-place" } } | get name | first)
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

# Places a multiple or a complex bet.
#
# POST /bet/complex
# operationId: placeComplexBet
# --bets item shape: {delayedBetId?: string, freeBetId?: string, legs: list, number: int, stake: float, typeCode: string}
export def "bet-complex create-place" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma Separated List)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
  --bets: list # A collection of bets — item shape: {delayedBetId?: string, freeBetId?: string, legs: list, number: int, stake: float, typeCode: string}
]: any -> table<id: string, numLines: int, number: float, placedDateTime: string, receipt: string, totalStake: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/bet/complex" $qp $auth.query)
  let req_body = {"bets": $bets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"fields": $fields, "include": $include, "exclude": $exclude} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Places a single bet
#
# POST /bet/single
# operationId: placeSingleBet
export def "bet-single create-place" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma Separated List)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
  --delayed-bet-id: string # The delayed bet identifier
  --free-bet-id: string # The ID number of the free bet token if used in conjunction with this bet
  --price-den: int # When the odds are shown in vulgar fractions this is the denominator of the fraction. For example: 2 in 5/2
  --price-num: int # When the odds are shown in vulgar fractions this is the numerator of the fraction. For example: 5 in 5/2
  price_type: string # The type of price taken by the customer when the bet is made. Can be one of the following: L - Live Fixed price, S - Starting price - Horse and Greyhound racing or G - Guaranteed best price.
  selection_id: string # The unique ID for the selection of the bet
  stake: float # The amount of the stake placed on the bet (format: double)
  type: string # The type of bet placed. Can be one of the following: W - Win or E- EachWay
]: any -> table<id: string, numLines: int, number: float, placedDateTime: string, receipt: string, totalStake: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/bet/single" $qp $auth.query)
  let req_body = {"delayedBetId": $delayed_bet_id, "freeBetId": $free_bet_id, "priceDen": $price_den, "priceNum": $price_num, "priceType": $price_type, "selectionId": $selection_id, "stake": $stake, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"fields": $fields, "include": $include, "exclude": $exclude} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Organises the betslip when one or more selections are made. It returns a bet slip structure organised by betting opportunities.
#
# POST /betslips
# operationId: validateBetslip
# --legs item shape: {parts: list, sort?: string, type: string}
export def "betslips validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expanded: string # Allows for all bets for given selections to be returned - not just the specified type
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --legs: list # item shape: {parts: list, sort?: string, type: string}
]: any -> record<betslip: table<betMultiplier: float, freeBets: list, legs: list, maxStake: float, minStake: float, numLines: float, number: int, typeCode: string, typeName: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expanded" $expanded "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/betslips" $qp $auth.query)
  let req_body = {"legs": $legs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expanded": $expanded} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns available free bets
#
# GET /freebets
# operationId: getFreeBets
export def "freebets get-free-bets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # Specify an absolute field list to return (Comma Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma Separated List)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
]: nothing -> table<awardDateTime: string, displayText: string, expiryDateTime: string, id: int, offerDesc: string, offerId: int, offerName: string, startDateTime: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/freebets" $qp $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Retrieves the customer’s bet history.
#
# GET /history
# operationId: getBetHistory
export def "history get-bet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The UTC FROM datetime from bets to be returned. (yyyy-MM-ddTHH:mm:ss)
  --date-to: string # The UTC TO datetime for bets to be returned. (yyyy-MM-ddTHH:mm:ss)
  --fields: list<string> # Specify an absolute field list to return (Comma Separated List)
  --include: list<string> # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list<string> # Specify fields from the default to exclude (Comma Separated List)
  --page: float # The index of the page to return (default: 1)
  --page-size: float # The number of results per page (default: 100)
  --qp-sort: string # The order the response will be retuned by. i.e. transDateTime,desc. Only transDateTime can be used currently (default: transDateTime,asc)
  --settled: oneof<nothing, bool> # Filter by settled bets. If omitted, both settled and unsettled will be returned.
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
]: nothing -> record<bets: table<cashinValue: float, estimatedReturns: float, freeBetValue: float, id: string, legs: list, numLines: int, numSelections: int, receipt: string, settled: bool, stake: float, stakePerLine: float, status: string, transDateTime: string, typeCode: string, typeName: string, winnings: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "settled" $settled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/history" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"dateFrom": $date_from, "dateTo": $date_to, "fields": $fields, "include": $include, "exclude": $exclude, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "settled": $settled} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Allows a trusted application to cash in a bet (take a return on a bet) on behalf of the customer
#
# PUT /{betId}/cashin
# operationId: cashin
export def "cashin update" [
  bet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cash-in-value: float # The cash in value of the bet (format: double)
  --cashin-bet-delay-id: string # The ID of this bet delay
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($bet_id | is-empty) { error make --unspanned { msg: "path parameter 'betId' must be non-empty" } }
  let qp = [(serialize-qp "cashInValue" $cash_in_value "scalar") (serialize-qp "cashinBetDelayId" $cashin_bet_delay_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bet_id: (encode-path-segment $bet_id)} | format pattern "/{bet_id}/cashin") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"cashInValue": $cash_in_value, "cashinBetDelayId": $cashin_bet_delay_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}
