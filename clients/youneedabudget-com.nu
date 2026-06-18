# Auto-generated client for YNAB API Endpoints v1.0.0
# Source: https://api.apis.guru/v2/specs/youneedabudget.com/1.0.0/openapi.json
# Auth: --token flag or $env.YNAB_API_ENDPOINTS_TOKEN

const BASE_URL = "https://api.youneedabudget.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o YNAB_API_ENDPOINTS_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.youneedabudget.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["unapproved" "uncategorized"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "budgets list" } } | get name | first)
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

# List budgets
#
# GET /budgets
# operationId: getBudgets
export def "budgets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-accounts: oneof<nothing, bool> # Whether to include the list of budget accounts
]: nothing -> record<data: record<budgets: list<record>, default_budget: record<accounts: list, currency_format: record, date_format: record, first_month: string, id: string, last_modified_on: string, last_month: string, name: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_accounts" $include_accounts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/budgets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single budget
#
# GET /budgets/{budget_id}
# operationId: getBudgetById
export def "budgets get" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<budget: record<accounts: list, currency_format: record, date_format: record, first_month: string, id: string, last_modified_on: string, last_month: string, name: string, categories: list, category_groups: list, months: list, payee_locations: list, payees: list, scheduled_subtransactions: list, scheduled_transactions: list, subtransactions: list, transactions: list>, server_knowledge: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Account list
#
# GET /budgets/{budget_id}/accounts
# operationId: getAccounts
export def "budgets-accounts list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<accounts: list<record>, server_knowledge: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new account
#
# POST /budgets/{budget_id}/accounts
# operationId: createAccount
# --account shape: {balance: int, name: string, type: "checking"|"savings"|"cash"|"creditCard"|"lineOfCredit"|"otherAsset"|"otherLiability"|"mortgage"|"autoLoan"|"studentLoan"|"personalLoan"|"medicalDebt"|"otherDebt"}
export def "budgets-accounts create" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {balance: int, name: string, type: "checking"|"savings"|"cash"|"creditCard"|"lineOfCredit"|"otherAsset"|"otherLiability"|"mortgage"|"autoLoan"|"studentLoan"|"personalLoan"|"medicalDebt"|"otherDebt"}
]: any -> record<data: record<account: record<balance: int, cleared_balance: int, closed: bool, debt_escrow_amounts: record, debt_interest_rates: record, debt_minimum_payments: record, debt_original_balance: int, deleted: bool, direct_import_in_error: bool, direct_import_linked: bool, id: string, last_reconciled_at: string, name: string, note: string, on_budget: bool, transfer_payee_id: string, type: string, uncleared_balance: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/accounts"))
  let req_body = {"account": $account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Single account
#
# GET /budgets/{budget_id}/accounts/{account_id}
# operationId: getAccountById
export def "budgets-accounts get" [
  budget_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<account: record<balance: int, cleared_balance: int, closed: bool, debt_escrow_amounts: record, debt_interest_rates: record, debt_minimum_payments: record, debt_original_balance: int, deleted: bool, direct_import_in_error: bool, direct_import_linked: bool, id: string, last_reconciled_at: string, name: string, note: string, on_budget: bool, transfer_payee_id: string, type: string, uncleared_balance: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), account_id: (encode-path-segment $account_id)} | format pattern "/budgets/{budget_id}/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List account transactions
#
# GET /budgets/{budget_id}/accounts/{account_id}/transactions
# operationId: getTransactionsByAccount
export def "budgets-accounts-transactions get" [
  budget_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since-date: string # If specified, only transactions on or after this date will be included. The date should be ISO formatted (e.g. 2016-12-30). (format: date)
  --type: string@type-completer # If specified, only transactions of the specified type will be included. "uncategorized" and "unapproved" are currently supported.
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<server_knowledge: int, transactions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_date" $since_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), account_id: (encode-path-segment $account_id)} | format pattern "/budgets/{budget_id}/accounts/{account_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List categories
#
# GET /budgets/{budget_id}/categories
# operationId: getCategories
export def "budgets-categories list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<category_groups: list<record>, server_knowledge: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/categories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single category
#
# GET /budgets/{budget_id}/categories/{category_id}
# operationId: getCategoryById
export def "budgets-categories get" [
  budget_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<category: record<activity: int, balance: int, budgeted: int, category_group_id: string, deleted: bool, goal_cadence: int, goal_cadence_frequency: int, goal_creation_month: string, goal_day: int, goal_months_to_budget: int, goal_overall_funded: int, goal_overall_left: int, goal_percentage_complete: int, goal_target: int, goal_target_month: string, goal_type: string, goal_under_funded: int, hidden: bool, id: string, name: string, note: string, original_category_group_id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), category_id: (encode-path-segment $category_id)} | format pattern "/budgets/{budget_id}/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List category transactions
#
# GET /budgets/{budget_id}/categories/{category_id}/transactions
# operationId: getTransactionsByCategory
export def "budgets-categories-transactions get" [
  budget_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since-date: string # If specified, only transactions on or after this date will be included. The date should be ISO formatted (e.g. 2016-12-30). (format: date)
  --type: string@type-completer # If specified, only transactions of the specified type will be included. "uncategorized" and "unapproved" are currently supported.
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<server_knowledge: int, transactions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_date" $since_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), category_id: (encode-path-segment $category_id)} | format pattern "/budgets/{budget_id}/categories/{category_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List budget months
#
# GET /budgets/{budget_id}/months
# operationId: getBudgetMonths
export def "budgets-months list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<months: list<record>, server_knowledge: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/months") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single budget month
#
# GET /budgets/{budget_id}/months/{month}
# operationId: getBudgetMonth
export def "budgets-months get" [
  budget_id: string
  month: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<month: record<activity: int, age_of_money: int, budgeted: int, deleted: bool, income: int, month: string, note: string, to_be_budgeted: int, categories: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), month: (encode-path-segment $month)} | format pattern "/budgets/{budget_id}/months/{month}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single category for a specific budget month
#
# GET /budgets/{budget_id}/months/{month}/categories/{category_id}
# operationId: getMonthCategoryById
export def "budgets-months-categories get" [
  budget_id: string
  month: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<category: record<activity: int, balance: int, budgeted: int, category_group_id: string, deleted: bool, goal_cadence: int, goal_cadence_frequency: int, goal_creation_month: string, goal_day: int, goal_months_to_budget: int, goal_overall_funded: int, goal_overall_left: int, goal_percentage_complete: int, goal_target: int, goal_target_month: string, goal_type: string, goal_under_funded: int, hidden: bool, id: string, name: string, note: string, original_category_group_id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), month: (encode-path-segment $month), category_id: (encode-path-segment $category_id)} | format pattern "/budgets/{budget_id}/months/{month}/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a category for a specific month
#
# PATCH /budgets/{budget_id}/months/{month}/categories/{category_id}
# operationId: updateMonthCategory
# --category shape: {budgeted: int}
export def "budgets-months-categories update" [
  budget_id: string
  month: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: record # shape: {budgeted: int}
]: any -> record<data: record<category: record<activity: int, balance: int, budgeted: int, category_group_id: string, deleted: bool, goal_cadence: int, goal_cadence_frequency: int, goal_creation_month: string, goal_day: int, goal_months_to_budget: int, goal_overall_funded: int, goal_overall_left: int, goal_percentage_complete: int, goal_target: int, goal_target_month: string, goal_type: string, goal_under_funded: int, hidden: bool, id: string, name: string, note: string, original_category_group_id: string>, server_knowledge: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), month: (encode-path-segment $month), category_id: (encode-path-segment $category_id)} | format pattern "/budgets/{budget_id}/months/{month}/categories/{category_id}"))
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List payee locations
#
# GET /budgets/{budget_id}/payee_locations
# operationId: getPayeeLocations
export def "budgets-payee-locations list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<payee_locations: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/payee_locations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single payee location
#
# GET /budgets/{budget_id}/payee_locations/{payee_location_id}
# operationId: getPayeeLocationById
export def "budgets-payee-locations get" [
  budget_id: string
  payee_location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<payee_location: record<deleted: bool, id: string, latitude: string, longitude: string, payee_id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), payee_location_id: (encode-path-segment $payee_location_id)} | format pattern "/budgets/{budget_id}/payee_locations/{payee_location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payees
#
# GET /budgets/{budget_id}/payees
# operationId: getPayees
export def "budgets-payees list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<payees: list<record>, server_knowledge: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/payees") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single payee
#
# GET /budgets/{budget_id}/payees/{payee_id}
# operationId: getPayeeById
export def "budgets-payees get" [
  budget_id: string
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<payee: record<deleted: bool, id: string, name: string, transfer_account_id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), payee_id: (encode-path-segment $payee_id)} | format pattern "/budgets/{budget_id}/payees/{payee_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List locations for a payee
#
# GET /budgets/{budget_id}/payees/{payee_id}/payee_locations
# operationId: getPayeeLocationsByPayee
export def "budgets-payees-payee-locations get" [
  budget_id: string
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<payee_locations: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), payee_id: (encode-path-segment $payee_id)} | format pattern "/budgets/{budget_id}/payees/{payee_id}/payee_locations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payee transactions
#
# GET /budgets/{budget_id}/payees/{payee_id}/transactions
# operationId: getTransactionsByPayee
export def "budgets-payees-transactions get" [
  budget_id: string
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since-date: string # If specified, only transactions on or after this date will be included. The date should be ISO formatted (e.g. 2016-12-30). (format: date)
  --type: string@type-completer # If specified, only transactions of the specified type will be included. "uncategorized" and "unapproved" are currently supported.
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<server_knowledge: int, transactions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_date" $since_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), payee_id: (encode-path-segment $payee_id)} | format pattern "/budgets/{budget_id}/payees/{payee_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List scheduled transactions
#
# GET /budgets/{budget_id}/scheduled_transactions
# operationId: getScheduledTransactions
export def "budgets-scheduled-transactions list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<scheduled_transactions: list<record>, server_knowledge: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/scheduled_transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single scheduled transaction
#
# GET /budgets/{budget_id}/scheduled_transactions/{scheduled_transaction_id}
# operationId: getScheduledTransactionById
export def "budgets-scheduled-transactions get" [
  budget_id: string
  scheduled_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<scheduled_transaction: record<account_id: string, amount: int, category_id: string, date_first: string, date_next: string, deleted: bool, flag_color: string, frequency: string, id: string, memo: string, payee_id: string, transfer_account_id: string, account_name: string, category_name: string, payee_name: string, subtransactions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), scheduled_transaction_id: (encode-path-segment $scheduled_transaction_id)} | format pattern "/budgets/{budget_id}/scheduled_transactions/{scheduled_transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Budget Settings
#
# GET /budgets/{budget_id}/settings
# operationId: getBudgetSettingsById
export def "budgets-settings get" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<settings: record<currency_format: record, date_format: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transactions
#
# GET /budgets/{budget_id}/transactions
# operationId: getTransactions
export def "budgets-transactions list" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since-date: string # If specified, only transactions on or after this date will be included. The date should be ISO formatted (e.g. 2016-12-30). (format: date)
  --type: string@type-completer # If specified, only transactions of the specified type will be included. "uncategorized" and "unapproved" are currently supported.
  --last-knowledge-of-server: int # The starting server knowledge. If provided, only entities that have changed since `last_knowledge_of_server` will be included. (format: int64)
]: nothing -> record<data: record<server_knowledge: int, transactions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since_date" $since_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "last_knowledge_of_server" $last_knowledge_of_server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update multiple transactions
#
# PATCH /budgets/{budget_id}/transactions
# operationId: updateTransactions
# --transactions item shape: {id?: string, account_id?: string, amount?: int, approved?: bool, category_id?: string, cleared?: "cleared"|"uncleared"|"reconciled", date?: string, flag_color?: "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"", import_id?: string, memo?: string, payee_id?: string, payee_name?: string, subtransactions?: list}
export def "budgets-transactions update-by-budget_id" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transactions: list # item shape: {id?: string, account_id?: string, amount?: int, approved?: bool, category_id?: string, cleared?: "cleared"|"uncleared"|"reconciled", date?: string, flag_color?: "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"", import_id?: string, memo?: string, payee_id?: string, payee_name?: string, subtransactions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/transactions"))
  let req_body = {"transactions": $transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a single transaction or multiple transactions
#
# POST /budgets/{budget_id}/transactions
# operationId: createTransaction
# --transactions item shape: {account_id: string, amount: int, approved?: bool, category_id?: string, cleared?: "cleared"|"uncleared"|"reconciled", date: string, flag_color?: "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"", import_id?: string, memo?: string, payee_id?: string, payee_name?: string, subtransactions?: list}
export def "budgets-transactions create" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: any
  --transactions: list # item shape: {account_id: string, amount: int, approved?: bool, category_id?: string, cleared?: "cleared"|"uncleared"|"reconciled", date: string, flag_color?: "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"", import_id?: string, memo?: string, payee_id?: string, payee_name?: string, subtransactions?: list}
]: any -> record<data: record<duplicate_import_ids: list<string>, server_knowledge: int, transaction: record<account_id: string, amount: int, approved: bool, category_id: string, cleared: string, date: string, debt_transaction_type: string, deleted: bool, flag_color: string, id: string, import_id: string, import_payee_name: string, import_payee_name_original: string, matched_transaction_id: string, memo: string, payee_id: string, transfer_account_id: string, transfer_transaction_id: string, account_name: string, category_name: string, payee_name: string, subtransactions: list>, transaction_ids: list<string>, transactions: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/transactions"))
  let req_body = {"transaction": $transaction, "transactions": $transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk create transactions
#
# POST /budgets/{budget_id}/transactions/bulk
# operationId: bulkCreateTransactions
# --transactions item shape: {account_id: string, amount: int, approved?: bool, category_id?: string, cleared?: "cleared"|"uncleared"|"reconciled", date: string, flag_color?: "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"", import_id?: string, memo?: string, payee_id?: string, payee_name?: string, subtransactions?: list}
export def "budgets-transactions-bulk create" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transactions: list # item shape: {account_id: string, amount: int, approved?: bool, category_id?: string, cleared?: "cleared"|"uncleared"|"reconciled", date: string, flag_color?: "red"|"orange"|"yellow"|"green"|"blue"|"purple"|"", import_id?: string, memo?: string, payee_id?: string, payee_name?: string, subtransactions?: list}
]: any -> record<data: record<bulk: record<duplicate_import_ids: list, transaction_ids: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/transactions/bulk"))
  let req_body = {"transactions": $transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Import transactions
#
# POST /budgets/{budget_id}/transactions/import
# operationId: importTransactions
export def "budgets-transactions-import import" [
  budget_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<transaction_ids: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id)} | format pattern "/budgets/{budget_id}/transactions/import"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an existing transaction
#
# DELETE /budgets/{budget_id}/transactions/{transaction_id}
# operationId: deleteTransaction
export def "budgets-transactions delete" [
  budget_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<transaction: record<account_id: string, amount: int, approved: bool, category_id: string, cleared: string, date: string, debt_transaction_type: string, deleted: bool, flag_color: string, id: string, import_id: string, import_payee_name: string, import_payee_name_original: string, matched_transaction_id: string, memo: string, payee_id: string, transfer_account_id: string, transfer_transaction_id: string, account_name: string, category_name: string, payee_name: string, subtransactions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/budgets/{budget_id}/transactions/{transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Single transaction
#
# GET /budgets/{budget_id}/transactions/{transaction_id}
# operationId: getTransactionById
export def "budgets-transactions get" [
  budget_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<transaction: record<account_id: string, amount: int, approved: bool, category_id: string, cleared: string, date: string, debt_transaction_type: string, deleted: bool, flag_color: string, id: string, import_id: string, import_payee_name: string, import_payee_name_original: string, matched_transaction_id: string, memo: string, payee_id: string, transfer_account_id: string, transfer_transaction_id: string, account_name: string, category_name: string, payee_name: string, subtransactions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/budgets/{budget_id}/transactions/{transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing transaction
#
# PUT /budgets/{budget_id}/transactions/{transaction_id}
# operationId: updateTransaction
export def "budgets-transactions update-by-budget_id-transaction_id" [
  budget_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: any
]: any -> record<data: record<transaction: record<account_id: string, amount: int, approved: bool, category_id: string, cleared: string, date: string, debt_transaction_type: string, deleted: bool, flag_color: string, id: string, import_id: string, import_payee_name: string, import_payee_name_original: string, matched_transaction_id: string, memo: string, payee_id: string, transfer_account_id: string, transfer_transaction_id: string, account_name: string, category_name: string, payee_name: string, subtransactions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({budget_id: (encode-path-segment $budget_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/budgets/{budget_id}/transactions/{transaction_id}"))
  let req_body = {"transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# User info
#
# GET /user
# operationId: getUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<user: record<id: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
