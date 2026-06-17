# Auto-generated client for Bets API v2.0.0
# Source: https://api.apis.guru/v2/specs/whapi.com/bets/2.0.0/openapi.json
# Auth: --token flag or $env.BETS_API_TOKEN

const BASE_URL = "https://sandbox.whapi.com/v2/bets"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BETS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox.whapi.com/v2/bets"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bet-complex placeComplexBet" } } | get name | first)
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
export def "bet-complex placeComplexBet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma Separated List)
  --include: list # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma Separated List)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
  --bets: list # A collection of bets — item shape: {delayedBetId?: string, freeBetId?: string, legs: list, number: int, stake: float, typeCode: string}
]: any -> table<id: string, numLines: int, number: float, placedDateTime: string, receipt: string, totalStake: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/bet/complex" $qp)
  let body = {"bets": $bets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Places a single bet
#
# POST /bet/single
# operationId: placeSingleBet
export def "bet-single placeSingleBet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma Separated List)
  --include: list # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma Separated List)
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
  let full_url = (build-url $base "/bet/single" $qp)
  let body = {"delayedBetId": $delayed_bet_id, "freeBetId": $free_bet_id, "priceDen": $price_den, "priceNum": $price_num, "priceType": $price_type, "selectionId": $selection_id, "stake": $stake, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base "/betslips" $qp)
  let body = {"legs": $legs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns available free bets
#
# GET /freebets
# operationId: getFreeBets
export def "freebets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list # Specify an absolute field list to return (Comma Separated List)
  --include: list # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma Separated List)
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
]: nothing -> table<awardDateTime: string, displayText: string, expiryDateTime: string, id: int, offerDesc: string, offerId: int, offerName: string, startDateTime: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv") (serialize-qp "include" $include "csv") (serialize-qp "exclude" $exclude "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/freebets" $qp)
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The UTC FROM datetime from bets to be returned. (yyyy-MM-ddTHH:mm:ss)
  --date-to: string # The UTC TO datetime for bets to be returned. (yyyy-MM-ddTHH:mm:ss)
  --fields: list # Specify an absolute field list to return (Comma Separated List)
  --include: list # Specify fields in addition to the default to return (Comma Separated List)
  --exclude: list # Specify fields from the default to exclude (Comma Separated List)
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
  let full_url = (build-url $base "/history" $qp)
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows a trusted application to cash in a bet (take a return on a bet) on behalf of the customer
#
# PUT /{betId}/cashin
# operationId: cashin
export def "cashin put" [
  bet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cash-in-value: float # The cash in value of the bet (format: double)
  --cashin-bet-delay-id: string # The ID of this bet delay
  --api-key: string # A unique identifier of your application that is generated by the API portal.
  --api-secret: string # Another unique identifier for your application.
  --api-ticket: string # The ticket obtained from the sessions API
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cashInValue" $cash_in_value "scalar") (serialize-qp "cashinBetDelayId" $cashin_bet_delay_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bet_id: $bet_id} | format pattern "/{bet_id}/cashin") $qp)
  let extra_headers = {"apiKey": $api_key, "apiSecret": $api_secret, "apiTicket": $api_ticket} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
