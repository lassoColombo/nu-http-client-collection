# Auto-generated client for PocketSmith v2.0
# Source: https://api.apis.guru/v2/specs/pocketsmith.com/2.0/openapi.json
# Auth: --token flag or $env.POCKETSMITH_TOKEN

const BASE_URL = "https://api.pocketsmith.com/v2"
const DEFAULT_AUTH = "x-developer-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POCKETSMITH_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-developer-key" => { {headers: {X-Developer-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.pocketsmith.com/v2"] }
def auth-scheme-completer [] { ["x-developer-key" "bearer"] }

# Completers for enum parameters
def type-completer [] { ["bank" "cash" "credits" "insurance" "loans" "mortgage" "other_asset" "other_liability" "property" "stocks" "vehicle"] }
def type-completer-1 [] { ["credit" "debit"] }
def refund-behaviour-completer [] { ["" "credits_are_refunds" "debits_are_deductions"] }
def behaviour-completer [] { ["all" "forward" "one"] }
def repeat-type-completer [] { ["daily" "each weekday" "fortnightly" "monthly" "once" "weekly" "yearly"] }
def period-completer [] { ["event" "months" "weeks" "years"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts delete" } } | get name | first)
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

# Delete account
#
# DELETE /accounts/{id}
export def "accounts delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account
#
# GET /accounts/{id}
export def "accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update account
#
# PUT /accounts/{id}
export def "accounts update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: string # A new currency code for the account. (e.g. NZD)
  --is-net-worth: oneof<nothing, bool> # Whether the account is a net worth account. (e.g. false)
  --title: string # A new title for the account. (e.g. Savings)
  --type: string@type-completer # The type of the account. (e.g. bank)
]: any -> record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let req_body = {"currency_code": $currency_code, "is_net_worth": $is_net_worth, "title": $title, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List transactions in account
#
# GET /accounts/{id}/transactions
export def "accounts-transactions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "uncategorised" $uncategorised "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "needs_review" $needs_review "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete attachment
#
# DELETE /attachments/{id}
export def "attachments delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachment
#
# GET /attachments/{id}
export def "attachments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update attachment
#
# PUT /attachments/{id}
export def "attachments update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The new title of the attachment. If the title is blank or not provided, the server will derive a title from the file name. (e.g. Invoice for taxi)
]: any -> record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/attachments/{id}"))
  let req_body = {"title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete category
#
# DELETE /categories/{id}
export def "categories delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get category
#
# GET /categories/{id}
export def "categories get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update category
#
# PUT /categories/{id}
export def "categories update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --colour: string # A new CSS-style hex colour for the category. (e.g. #e0e7ff)
  --is-bill: oneof<nothing, bool> # Set the category as a bill category. (e.g. true)
  --is-transfer: oneof<nothing, bool> # Set the category as a transfer category. (e.g. false)
  --parent-id: int # The unique identifier of a parent category for the category, making this category a child of that category. (e.g. 42)
  --refund-behaviour: string@refund-behaviour-completer # Set the refund behaviour of the category. (nullable, e.g. credits_are_refunds)
  --roll-up: oneof<nothing, bool> # Set the category to be rolled up into its parent category. (e.g. false)
  --title: string # A new title for the category. (e.g. Food)
]: any -> record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}"))
  let req_body = {"colour": $colour, "is_bill": $is_bill, "is_transfer": $is_transfer, "parent_id": $parent_id, "refund_behaviour": $refund_behaviour, "roll_up": $roll_up, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create category rule in category
#
# POST /categories/{id}/category_rules
export def "categories-category-rules create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-to-all: oneof<nothing, bool> # Apply the created category rule to all transactions. (e.g. false)
  --apply-to-uncategorised: oneof<nothing, bool> # Apply the created category rule to all uncategorised transactions. (e.g. true)
  payee_matches: string # The keyword/s to match the transaction payees. (e.g. Countdown)
]: any -> record<category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, created_at: string, id: int, payee_matches: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}/category_rules"))
  let req_body = {"apply_to_all": $apply_to_all, "apply_to_uncategorised": $apply_to_uncategorised, "payee_matches": $payee_matches} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List transactions in categories
#
# GET /categories/{id}/transactions
export def "categories-transactions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "uncategorised" $uncategorised "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "needs_review" $needs_review "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List currencies
#
# GET /currencies
export def "currencies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, minor_unit: int, name: string, separators: record<major: string, minor: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get currency
#
# GET /currencies/{id}
export def "currencies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, minor_unit: int, name: string, separators: record<major: string, minor: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/currencies/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete event
#
# DELETE /events/{id}
export def "events delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --behaviour: string@behaviour-completer # Whether the delete applies only to this event, to all events within the series from this event or to all events within the series.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "behaviour" $behaviour "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get event
#
# GET /events/{id}
export def "events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update event
#
# PUT /events/{id}
export def "events update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # The amount of the event. A positive amount is a credit, and a negative amount is a debit. (e.g. 11.5)
  behaviour: string@behaviour-completer # Whether the update applies only to this event, to all events within the series from this event or to all events within the series. (e.g. all)
  --note: string # A note for the event. (e.g. Need more beer.)
  --repeat-interval: int # The repeat interval of the event. (e.g. 1)
  --repeat-type: string@repeat-type-completer # The repeat type of the event. (e.g. weekly)
]: any -> record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}"))
  let req_body = {"amount": $amount, "behaviour": $behaviour, "note": $note, "repeat_interval": $repeat_interval, "repeat_type": $repeat_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete institution
#
# DELETE /institutions/{id}
export def "institutions delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-into-institution-id: int # The unique identifier of the institution to merge into. (e.g. 44)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge_into_institution_id" $merge_into_institution_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/institutions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get institution
#
# GET /institutions/{id}
export def "institutions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, currency_code: string, id: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/institutions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update institution
#
# PUT /institutions/{id}
export def "institutions update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: string # A new currency code for the institution. (e.g. NZD)
  --title: string # A new title for the institution. (e.g. Bank of Foo)
]: any -> record<created_at: string, currency_code: string, id: int, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/institutions/{id}"))
  let req_body = {"currency_code": $currency_code, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List accounts in institution
#
# GET /institutions/{id}/accounts
export def "institutions-accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/institutions/{id}/accounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the authorised user
#
# GET /me
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List events in scenario.
#
# GET /scenarios/{id}/events
export def "scenarios-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Return the events from and including this date. (e.g. 2020-10-01)
  --end-date: string # Return the events until and including this date. (e.g. 2020-10-30)
]: nothing -> table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/scenarios/{id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create event in scenario
#
# POST /scenarios/{id}/events
export def "scenarios-events create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The amount of the event. A positive amount is a credit, and a negative amount is a debit. (e.g. 11.5)
  category_id: int # The unique identifier of the category for the event. (e.g. 42)
  date: string # The starting date of the event. (e.g. 2020-10-27)
  --note: string # A note for the event. (e.g. New beers for sampling over the weekends.)
  --repeat-interval: int # The repeat interval of the event. (default: 1, e.g. 1)
  repeat_type: string@repeat-type-completer # The repeat type of the event. (e.g. weekly)
]: any -> record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/scenarios/{id}/events"))
  let req_body = {"amount": $amount, "category_id": $category_id, "date": $date, "note": $note, "repeat_interval": $repeat_interval, "repeat_type": $repeat_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List time zones
#
# GET /time_zones
export def "time-zones get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, formatted_name: string, formatted_offset: string, identifier: string, name: string, utc_offset: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_zones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get transaction account
#
# GET /transaction_accounts/{id}
export def "transaction-accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transaction_accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update transaction account
#
# PUT /transaction_accounts/{id}
export def "transaction-accounts update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --institution-id: int # The unique identifier of a new institution for the transaction account. (e.g. 42)
  --starting-balance: float # The starting balance amount of the transaction account. (e.g. 3547.45)
  --starting-balance-date: string # The starting balance date of the transaction account. (e.g. 2015-03-15)
]: any -> record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transaction_accounts/{id}"))
  let req_body = {"institution_id": $institution_id, "starting_balance": $starting_balance, "starting_balance_date": $starting_balance_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List transactions in transaction account
#
# GET /transaction_accounts/{id}/transactions
export def "transaction-accounts-transactions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "uncategorised" $uncategorised "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "needs_review" $needs_review "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transaction_accounts/{id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a transaction in transaction account
#
# POST /transaction_accounts/{id}/transactions
export def "transaction-accounts-transactions create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The amount of the transaction. A positive amount is a credit, and a negative amount is a debit. (e.g. 11.5)
  --category-id: int # The unique identifier of a category for the transaction. (e.g. 42)
  --cheque-number: string # A cheque number for the transaction.
  date: string # The date when the transaction occurred. (e.g. 2018-02-27)
  --is-transfer: oneof<nothing, bool> # Whether the transaction should be indicated as a transfer. (e.g. false)
  --labels: string # A set of comma-separated labels for the transaction. (e.g. lunch,mexican)
  --memo: string # A memo for the transaction.
  --needs-review: oneof<nothing, bool> # Whether the transaction needs to be reviewed or not. (e.g. false)
  --note: string # A note for the transaction. (e.g. I really enjoyed the loaded corn chips)
  payee: string # The payee/merchant of the transaction. (e.g. Tex Otago)
]: any -> record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transaction_accounts/{id}/transactions"))
  let req_body = {"amount": $amount, "category_id": $category_id, "cheque_number": $cheque_number, "date": $date, "is_transfer": $is_transfer, "labels": $labels, "memo": $memo, "needs_review": $needs_review, "note": $note, "payee": $payee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete transaction
#
# DELETE /transactions/{id}
export def "transactions delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a transaction
#
# GET /transactions/{id}
export def "transactions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a transaction
#
# PUT /transactions/{id}
export def "transactions update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # A new amount for the transaction. (e.g. 225)
  --category-id: int # The unique identifier of a new category for the transaction. (e.g. 42)
  --cheque-number: string # A new cheque number for the transaction. (e.g. 503113643691)
  --date: string # A new date for the transaction. (e.g. 2018-02-27)
  --is-transfer: oneof<nothing, bool> # Whether the transaction is a transfer or not. (e.g. false)
  --labels: string # A new comma-separated set of labels for the transaction. (e.g. foo,bar,baz)
  --memo: string # A new memo for the transaction. (e.g. Rent)
  --needs-review: oneof<nothing, bool> # Whether the transaction needs to be reviewed or not. (e.g. false)
  --note: string # A new note for the transaction.
  --payee: string # A new payee for the transaction. (e.g. Bill)
]: any -> record<amount: float, amount_in_base_currency: float, category: record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}"))
  let req_body = {"amount": $amount, "category_id": $category_id, "cheque_number": $cheque_number, "date": $date, "is_transfer": $is_transfer, "labels": $labels, "memo": $memo, "needs_review": $needs_review, "note": $note, "payee": $payee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List attachments in transaction
#
# GET /transactions/{id}/attachments
export def "transactions-attachments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns attachment to transaction
#
# POST /transactions/{id}/attachments
export def "transactions-attachments create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment-id: int # The unique identifier of the attachment. (e.g. 1438154)
]: any -> record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}/attachments"))
  let req_body = {"attachment_id": $attachment_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Unassigns attachment in transaction
#
# DELETE /transactions/{transaction_id}/attachments/{attachment_id}
export def "transactions-attachments delete" [
  transaction_id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/transactions/{transaction_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user
#
# GET /users/{id}
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /users/{id}
export def "users update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --always-show-base-currency: oneof<nothing, bool> # Whether the user wishes to have all monetary values converted to their base currency. (e.g. true)
  --base-currency-code: string # A new base currency code for the user. (e.g. nzd)
  --beta-user: oneof<nothing, bool> # Whether the user is a beta user, and wishes to try out new features. (e.g. true)
  --email: string # A new email address for the user. (e.g. foo@bar.com)
  --name: string # A new name for the user. (e.g. John Appleseed)
  --time-zone: string # A new time zone for the user. (e.g. Auckland)
  --week-start-day: int # The day of the week the user wishes their calendars to start on. A number between 0 and 6, where 0 is Sunday and 6 is Saturday. (e.g. 1)
]: any -> record<always_show_base_currency: bool, available_accounts: int, available_budgets: int, avatar_url: string, base_currency_code: string, beta_user: bool, created_at: string, email: string, forecast_defer_recalculate: bool, forecast_end_date: string, forecast_last_accessed_at: string, forecast_last_updated_at: string, forecast_needs_recalculate: bool, forecast_start_date: string, id: int, is_reviewing_transactions: bool, last_activity_at: string, last_logged_in_at: string, login: string, name: string, time_zone: string, updated_at: string, using_multiple_currencies: bool, week_start_day: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let req_body = {"always_show_base_currency": $always_show_base_currency, "base_currency_code": $base_currency_code, "beta_user": $beta_user, "email": $email, "name": $name, "time_zone": $time_zone, "week_start_day": $week_start_day} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List accounts in user
#
# GET /users/{id}/accounts
export def "users-accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/accounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an account in user
#
# POST /users/{id}/accounts
export def "users-accounts create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  currency_code: string # A currency code for the account. (e.g. NZD)
  institution_id: int # The ID of the institution to create this account in. (e.g. 42)
  title: string # A title for the account. (e.g. Foo)
  type: string@type-completer # The type of the account. (e.g. bank)
]: any -> record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: table<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, title: string, transaction_accounts: table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/accounts"))
  let req_body = {"currency_code": $currency_code, "institution_id": $institution_id, "title": $title, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the display order of accounts in user
#
# PUT /users/{id}/accounts
# --accounts item shape: {created_at?: string, currency_code?: string, current_balance?: float, current_balance_date?: string, current_balance_exchange_rate?: float, current_balance_in_base_currency?: float, id?: int, is_net_worth?: bool, primary_scenario?: record, primary_transaction_account?: record, safe_balance?: float, safe_balance_in_base_currency?: float, scenarios?: list, title?: string, transaction_accounts?: list, ... (2 more fields)}
export def "users-accounts update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accounts: list # List the account objects in their new display order. — item shape: {created_at?: string, currency_code?: string, current_balance?: float, current_balance_date?: string, current_balance_exchange_rate?: float, current_balance_in_base_currency?: float, id?: int, is_net_worth?: bool, primary_scenario?: record, primary_transaction_account?: record, safe_balance?: float, safe_balance_in_base_currency?: float, scenarios?: list, title?: string, transaction_accounts?: list, ... (2 more fields)}
]: any -> table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, is_net_worth: bool, primary_scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, primary_transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, safe_balance: float, safe_balance_in_base_currency: float, scenarios: list<record>, title: string, transaction_accounts: list<record>, type: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/accounts"))
  let req_body = {"accounts": $accounts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists attachments in user
#
# GET /users/{id}/attachments
export def "users-attachments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unassigned: int # If set, returns unassigned attachments, that are available for assigning to a transaction. (e.g. 1)
]: nothing -> table<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unassigned" $unassigned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/attachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create attachment in user
#
# POST /users/{id}/attachments
export def "users-attachments create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-data: string # The base64-encoded contents of the source file. The supported file types are png, jpg, pdf, xls, xlsx, doc, docx. (format: base64)
  --file-name: string # The file name of the attachment. (e.g. taxi.png)
  --title: string # The title of the attachment. If the title is blank or not provided, the title will derived from the file name. (e.g. Invoice for taxi)
]: any -> record<content_type: string, content_type_meta: record<description: string, extension: string, title: string>, created_at: string, file_name: string, id: int, original_url: string, title: string, type: string, updated_at: string, variants: record<large_url: string, thumb_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/attachments"))
  let req_body = {"file_data": $file_data, "file_name": $file_name, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List budget for user
#
# GET /users/{id}/budget
export def "users-budget get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --roll-up: oneof<nothing, bool> # Whether parent categories should have their children rolled up into them. When used, the children will still appear in the collection on their own, but their actual and forecast figures will be rolled up to the root parent. (e.g. true)
]: nothing -> table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "roll_up" $roll_up "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/budget") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get budget summary for user
#
# GET /users/{id}/budget_summary
export def "users-budget-summary get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # The period to analyse in, one of `weeks`, `months` or `years`. Also supported is `event`, although event period analysis is only possible when the budget events gathered align, so in this case where all categories are analysed together, it's highly unlikely that event period analysis will be possible. (e.g. weeks)
  --interval: int # The period interval, e.g. if the interval is 2 and the period is weeks, the budget will be analysed fortnightly. (e.g. 2)
  --start-date: string # The date to start analysing the budget from. This will be bumped out to make full periods as necessary. (e.g. 2016-11-01)
  --end-date: string # The date to stop analysing the budget from. This will be bumped out to make full periods as necessary. (e.g. 2016-11-30)
]: nothing -> table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/budget_summary") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List categories in user
#
# GET /users/{id}/categories
export def "users-categories get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create category in user
#
# POST /users/{id}/categories
export def "users-categories create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --colour: string # A CSS-style hex colour for the category. (e.g. #e0e7ff)
  --is-bill: oneof<nothing, bool> # Set the category as a bill category. (e.g. true)
  --is-transfer: oneof<nothing, bool> # Set the category as a transfer category. (e.g. false)
  --parent-id: int # The unique identifier of a category to be the parent of this category. (e.g. 42)
  --refund-behaviour: string@refund-behaviour-completer # Set the refund behaviour of the category. (nullable, e.g. credits_are_refunds)
  --roll-up: oneof<nothing, bool> # Set the category to be rolled up into its parent category. (e.g. false)
  title: string # A title for the category. (e.g. Food)
]: any -> record<children: list<any>, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/categories"))
  let req_body = {"colour": $colour, "is_bill": $is_bill, "is_transfer": $is_transfer, "parent_id": $parent_id, "refund_behaviour": $refund_behaviour, "roll_up": $roll_up, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List category rules in user
#
# GET /users/{id}/category_rules
export def "users-category-rules get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, created_at: string, id: int, payee_matches: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/category_rules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List events in user.
#
# GET /users/{id}/events
export def "users-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Return the events from and including this date. (e.g. 2020-10-01)
  --end-date: string # Return the events until and including this date. (e.g. 2020-10-30)
]: nothing -> table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, colour: string, currency_code: string, date: string, id: string, infinite_series: bool, note: string, repeat_interval: int, repeat_type: string, scenario: record<achieve_date: string, closing_balance: float, closing_balance_date: string, created_at: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, description: string, id: int, interest_rate: float, interest_rate_repeat_id: int, maximum_value: float, minimum_value: float, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, title: string, type: string, updated_at: string>, series_id: int, series_start_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete forecast cache for user
#
# DELETE /users/{id}/forecast_cache
export def "users-forecast-cache delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/forecast_cache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List institutions in user
#
# GET /users/{id}/institutions
export def "users-institutions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, currency_code: string, id: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/institutions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create institution in user
#
# POST /users/{id}/institutions
export def "users-institutions create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  currency_code: string # A currency code for the institution. (e.g. NZD)
  title: string # A title for the institution. (e.g. Bank of Foo)
]: any -> record<created_at: string, currency_code: string, id: int, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/institutions"))
  let req_body = {"currency_code": $currency_code, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List labels in user
#
# GET /users/{id}/labels
export def "users-labels get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/labels"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List saved searches in user
#
# GET /users/{id}/saved_searches
export def "users-saved-searches get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, id: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/saved_searches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transaction accounts in user
#
# GET /users/{id}/transaction_accounts
export def "users-transaction-accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record<created_at: string, currency_code: string, id: int, title: string, updated_at: string>, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/transaction_accounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transactions in user
#
# GET /users/{id}/transactions
export def "users-transactions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Limit to transactions on or after this date. Required if end_date is provided. If not provided, defaults to the furtherest date allowed by the user's subscription. (e.g. 2016-11-01)
  --end-date: string # Limit to transactions on or before this date. Required if start_date is provided. If not provided, defaults to today's date. (e.g. 2016-11-30)
  --updated-since: string # Limit to transactions updated since an ISO 8601 timestamp. (e.g. 2020-10-14T09:20:33+13:00)
  --uncategorised: int # Limit to uncategorised transactions. (e.g. 1)
  --type: string@type-completer-1 # Limit to transactions of this type. (e.g. debit)
  --needs-review: int # Limit to transactions that need to be reviewed. (e.g. 1)
  --search: string # Limit to transactions matching a keyword search string. The provided string is matched against the transaction amount, account name, payee, category title, note, labels, and the date in ISO 8601 format. (e.g. Paypal)
  --page: int # Choose a particular page of the results. (e.g. 3)
]: nothing -> table<amount: float, amount_in_base_currency: float, category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, cheque_number: string, closing_balance: float, created_at: string, date: string, id: int, is_transfer: bool, labels: list<string>, memo: string, needs_review: bool, note: string, original_payee: string, payee: string, status: string, transaction_account: record<created_at: string, currency_code: string, current_balance: float, current_balance_date: string, current_balance_exchange_rate: float, current_balance_in_base_currency: float, id: int, institution: record, name: string, number: string, safe_balance: float, safe_balance_in_base_currency: float, starting_balance: float, starting_balance_date: string, type: string, updated_at: string>, type: string, updated_at: string, upload_source: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "updated_since" $updated_since "scalar") (serialize-qp "uncategorised" $uncategorised "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "needs_review" $needs_review "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trend analysis for user
#
# GET /users/{id}/trend_analysis
export def "users-trend-analysis get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # The period to analyse in, one of `weeks`, `months` or `years`. Also supported is `event`, although event period analysis is only possible when the budget events gathered align, so in this case where all categories are analysed together, it's highly unlikely that event period analysis will be possible. (e.g. weeks)
  --interval: int # The period interval, e.g. if the interval is 2 and the period is weeks, the budget will be analysed fortnightly. (e.g. true)
  --start-date: string # The date to start analysing the budget from. This will be bumped out to make full periods as necessary. (e.g. 2016-11-01)
  --end-date: string # The date to stop analysing the budget from. This will be bumped out to make full periods as necessary. (e.g. 2016-11-30)
  --categories: string # A comma-separated list of category IDs to analyse. (e.g. 42,49)
  --scenarios: string # A comma-separated list of scenario IDs to analyse. You're likely going to want to include all a user's scenarios here, unless you have reason to only analyse for a subset of scenarios. Regardless of what scenarios are analysed, all actuals (transactions) across all accounts will be included. (e.g. 11,29)
]: nothing -> table<category: record<children: list, colour: string, created_at: string, id: int, is_bill: bool, is_transfer: bool, parent_id: int, refund_behaviour: string, roll_up: bool, title: string, updated_at: string>, expense: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, income: record<average_actual_amount: float, average_forecast_amount: float, currency_code: string, end_date: string, periods: list, start_date: string, total_actual_amount: float, total_forecast_amount: float, total_over_by: float, total_under_by: float>, is_transfer: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-developer-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "scenarios" $scenarios "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/trend_analysis") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
