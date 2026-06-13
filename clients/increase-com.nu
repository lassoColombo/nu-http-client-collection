# Auto-generated client for Increase API v0.0.1
# Source: https://api.apis.guru/v2/specs/increase.com/0.0.1/openapi.json
# Auth: --token flag or $env.INCREASE_API_TOKEN

const BASE_URL = "https://api.increase.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INCREASE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.increase.com" "https://sandbox.increase.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["active" "canceled" "disabled"] }
def status-completer-1 [] { ["closed" "open"] }
def credit-debit-indicator-completer [] { ["credit" "debit"] }
def standard-entry-class-code-completer [] { ["corporate_credit_or_debit" "internet_initiated" "prearranged_payments_and_deposit"] }
def funding-completer [] { ["checking" "savings"] }
def relationship-completer [] { ["affiliated" "informational" "unaffiliated"] }
def structure-completer [] { ["corporation" "joint" "natural_person" "trust"] }
def selected-event-category-completer [] { ["account.created" "account.updated" "account_number.created" "account_number.updated" "account_statement.created" "account_transfer.created" "account_transfer.updated" "ach_prenotification.created" "ach_prenotification.updated" "ach_transfer.created" "ach_transfer.updated" "card.created" "card.updated" "card_dispute.created" "card_dispute.updated" "check_deposit.created" "check_deposit.updated" "check_transfer.created" "check_transfer.updated" "declined_transaction.created" "digital_wallet_token.created" "digital_wallet_token.updated" "document.created" "entity.created" "entity.updated" "external_account.created" "file.created" "group.heartbeat" "group.updated" "inbound_ach_transfer_return.created" "inbound_ach_transfer_return.updated" "inbound_wire_drawdown_request.created" "oauth_connection.created" "oauth_connection.deactivated" "pending_transaction.created" "pending_transaction.updated" "real_time_decision.card_authorization_requested" "real_time_decision.digital_wallet_authentication_requested" "real_time_decision.digital_wallet_token_requested" "real_time_payments_request_for_payment.created" "real_time_payments_request_for_payment.updated" "real_time_payments_transfer.created" "real_time_payments_transfer.updated" "transaction.created" "wire_drawdown_request.created" "wire_drawdown_request.updated" "wire_transfer.created" "wire_transfer.updated"] }
def status-completer-2 [] { ["active" "deleted" "disabled"] }
def funding-completer-1 [] { ["checking" "other" "savings"] }
def status-completer-3 [] { ["active" "archived"] }
def purpose-completer [] { ["check_image_back" "check_image_front" "digital_wallet_app_icon" "digital_wallet_artwork" "entity_supplemental_document" "form_ss_4" "identity_document" "other" "trust_formation_document"] }
def reason-completer [] { ["authorization_revoked_by_customer" "beneficiary_or_account_holder_deceased" "corporate_customer_advised_not_authorized" "credit_entry_refused_by_receiver" "customer_advised_unauthorized_improper_ineligible_or_incomplete" "duplicate_entry" "payment_stopped" "representative_payee_deceased_or_unable_to_continue_in_that_capacity"] }
def interval-completer [] { ["all_time" "day" "month" "transaction" "week" "year"] }
def metric-completer [] { ["count" "volume"] }
def status-completer-4 [] { ["active" "inactive"] }
def reason-completer-1 [] { ["account_closed" "account_frozen_entry_returned_per_ofac_instruction" "addenda_error" "amount_field_error" "authorization_revoked_by_customer" "corporate_customer_advised_not_authorized" "credit_entry_refused_by_receiver" "customer_advised_unauthorized_improper_ineligible_or_incomplete" "enr_invalid_individual_name" "file_record_edit_criteria" "incorrectly_coded_outbound_international_payment" "insufficient_fund" "invalid_account_number_structure" "invalid_ach_routing_number" "limited_participation_dfi" "no_account" "non_transaction_account" "other" "payment_stopped" "returned_per_odfi_request" "routing_number_check_digit_error" "unauthorized_debit_to_consumer_account_using_corporate_sec_code" "uncollected_funds"] }
def status-completer-5 [] { ["accepted" "rejected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-numbers numbers" } } | get name | first)
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

# List Account Numbers
#
# GET /account_numbers
# operationId: list_account_numbers
export def "account-numbers numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --status: string@status-completer
  --account-id: string
]: nothing -> record<data: table<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "account_id" $account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Account Number
#
# POST /account_numbers
# operationId: create_an_account_number
export def "account-numbers number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The Account the Account Number should belong to.
  name: string # The name you choose for the Account Number.
]: any -> record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account_numbers")
  let body = {account_id: $account_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Account Number
#
# GET /account_numbers/{account_number_id}
# operationId: retrieve_an_account_number
export def "account-numbers number-by-account_number_id" [
  account_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account_numbers/($account_number_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Account Number
#
# PATCH /account_numbers/{account_number_id}
# operationId: update_an_account_number
export def "account-numbers number-by-account_number_id-1" [
  account_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name you choose for the Account Number.
  --status: string@status-completer # This indicates if transfers can be made to the Account Number.
]: any -> record<account_id: string, account_number: string, created_at: string, id: string, name: string, routing_number: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account_numbers/($account_number_id)")
  let body = {name: $name, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Account Statements
#
# GET /account_statements
# operationId: list_account_statements
export def "account-statements statements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --statement-period-startafter: string # format: date-time
  --statement-period-startbefore: string # format: date-time
  --statement-period-starton-or-after: string # format: date-time
  --statement-period-starton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "statement_period_start.after" $statement_period_startafter "scalar") (serialize-qp "statement_period_start.before" $statement_period_startbefore "scalar") (serialize-qp "statement_period_start.on_or_after" $statement_period_starton_or_after "scalar") (serialize-qp "statement_period_start.on_or_before" $statement_period_starton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account_statements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Account Statement
#
# GET /account_statements/{account_statement_id}
# operationId: retrieve_an_account_statement
export def "account-statements statement" [
  account_statement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account_statements/($account_statement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Account Transfers
#
# GET /account_transfers
# operationId: list_account_transfers
export def "account-transfers transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, amount: int, approval: record, cancellation: record, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account_transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Account Transfer
#
# POST /account_transfers
# operationId: create_an_account_transfer
export def "account-transfers transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the account that will send the transfer.
  amount: int # The transfer amount in the minor unit of the account currency. For dollars, for example, this is cents.
  description: string # The description you choose to give the transfer.
  destination_account_id: string # The identifier for the account that will receive the transfer.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
]: any -> record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account_transfers")
  let body = {account_id: $account_id, amount: $amount, description: $description, destination_account_id: $destination_account_id, require_approval: $require_approval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Account Transfer
#
# GET /account_transfers/{account_transfer_id}
# operationId: retrieve_an_account_transfer
export def "account-transfers transfer-by-account_transfer_id" [
  account_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account_transfers/($account_transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve an Account Transfer
#
# POST /account_transfers/{account_transfer_id}/approve
# operationId: approve_an_account_transfer
export def "account-transfers-approve transfer" [
  account_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account_transfers/($account_transfer_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel an Account Transfer
#
# POST /account_transfers/{account_transfer_id}/cancel
# operationId: cancel_an_account_transfer
export def "account-transfers-cancel transfer" [
  account_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account_transfers/($account_transfer_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Accounts
#
# GET /accounts
# operationId: list_accounts
export def "accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --entity-id: string # e.g. entity_n8y8tnk2p9339ti393yi
  --status: string@status-completer-1
]: nothing -> record<data: table<balances: record, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Account
#
# POST /accounts
# operationId: create_an_account
export def "accounts account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-id: string # The identifier for the Entity that will own the Account.
  --informational-entity-id: string # The identifier of an Entity that, while not owning the Account, is associated with its activity. Its relationship to your group must be `informational`.
  name: string # The name you choose for the Account.
]: any -> record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {entity_id: $entity_id, informational_entity_id: $informational_entity_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Account
#
# GET /accounts/{account_id}
# operationId: retrieve_an_account
export def "accounts account-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Account
#
# PATCH /accounts/{account_id}
# operationId: update_an_account
export def "accounts account-by-account_id-1" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the Account.
]: any -> record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close an Account
#
# POST /accounts/{account_id}/close
# operationId: close_an_account
export def "accounts-close account" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balances: record<available_balance: int, current_balance: int>, created_at: string, currency: string, entity_id: string, id: string, informational_entity_id: string, interest_accrued: string, interest_accrued_at: string, name: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/close")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ACH Prenotifications
#
# GET /ach_prenotifications
# operationId: list_ach_prenotifications
export def "ach-prenotifications prenotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record, routing_number: string, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ach_prenotifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an ACH Prenotification
#
# POST /ach_prenotifications
# operationId: create_an_ach_prenotification
export def "ach-prenotifications prenotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string # The account number for the destination account.
  --addendum: string # Additional information that will be sent to the recipient.
  --company-descriptive-date: string # The description of the date of the transfer.
  --company-discretionary-data: string # The data you choose to associate with the transfer.
  --company-entry-description: string # The description of the transfer you wish to be shown to the recipient.
  --company-name: string # The name by which the recipient knows you.
  --credit-debit-indicator: string@credit-debit-indicator-completer # Whether the Prenotification is for a future debit or credit.
  --effective-date: string # The transfer effective date in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date)
  --individual-id: string # Your identifer for the transfer recipient.
  --individual-name: string # The name of the transfer recipient. This value is information and not verified by the recipient's bank.
  routing_number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
  --standard-entry-class-code: string@standard-entry-class-code-completer # The Standard Entry Class (SEC) code to use for the ACH Prenotification.
]: any -> record<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record<created_at: string, return_reason_code: string>, routing_number: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ach_prenotifications")
  let body = {account_number: $account_number, addendum: $addendum, company_descriptive_date: $company_descriptive_date, company_discretionary_data: $company_discretionary_data, company_entry_description: $company_entry_description, company_name: $company_name, credit_debit_indicator: $credit_debit_indicator, effective_date: $effective_date, individual_id: $individual_id, individual_name: $individual_name, routing_number: $routing_number, standard_entry_class_code: $standard_entry_class_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an ACH Prenotification
#
# GET /ach_prenotifications/{ach_prenotification_id}
# operationId: retrieve_an_ach_prenotification
export def "ach-prenotifications prenotification-by-ach_prenotification_id" [
  ach_prenotification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number: string, addendum: string, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, credit_debit_indicator: string, effective_date: string, id: string, prenotification_return: record<created_at: string, return_reason_code: string>, routing_number: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ach_prenotifications/($ach_prenotification_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ACH Transfers
#
# GET /ach_transfers
# operationId: list_ach_transfers
export def "ach-transfers transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --external-account-id: string
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, account_number: string, addendum: string, amount: int, approval: record, cancellation: record, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record, return: record, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record, template_id: string, transaction_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "external_account_id" $external_account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ach_transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an ACH Transfer
#
# POST /ach_transfers
# operationId: create_an_ach_transfer
export def "ach-transfers transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The Increase identifier for the account that will send the transfer.
  --account-number: string # The account number for the destination account.
  --addendum: string # Additional information that will be sent to the recipient. This is included in the transfer data sent to the receiving bank.
  amount: int # The transfer amount in cents. A positive amount originates a credit transfer pushing funds to the receiving account. A negative amount originates a debit transfer pulling funds from the receiving account.
  --company-descriptive-date: string # The description of the date of the transfer, usually in the format `YYYYMMDD`. This is included in the transfer data sent to the receiving bank.
  --company-discretionary-data: string # The data you choose to associate with the transfer. This is included in the transfer data sent to the receiving bank.
  --company-entry-description: string # A description of the transfer. This is included in the transfer data sent to the receiving bank.
  --company-name: string # The name by which the recipient knows you. This is included in the transfer data sent to the receiving bank.
  --effective-date: string # The transfer effective date in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. (format: date)
  --external-account-id: string # The ID of an External Account to initiate a transfer to. If this parameter is provided, `account_number`, `routing_number`, and `funding` must be absent.
  --funding: string@funding-completer # The type of the account to which the transfer will be sent.
  --individual-id: string # Your identifer for the transfer recipient.
  --individual-name: string # The name of the transfer recipient. This value is informational and not verified by the recipient's bank.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
  --routing-number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
  --standard-entry-class-code: string@standard-entry-class-code-completer # The Standard Entry Class (SEC) code to use for the transfer.
  statement_descriptor: string # A description you choose to give the transfer. This will be saved with the transfer details, displayed in the dashboard, and returned by the API. If `individual_name` and `company_name` are not explicitly set by this API, the `statement_descriptor` will be sent in those fields to the receiving bank to help the customer recognize the transfer. You are highly encouraged to pass `individual_name` and `company_name` instead of relying on this fallback.
]: any -> record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ach_transfers")
  let body = {account_id: $account_id, account_number: $account_number, addendum: $addendum, amount: $amount, company_descriptive_date: $company_descriptive_date, company_discretionary_data: $company_discretionary_data, company_entry_description: $company_entry_description, company_name: $company_name, effective_date: $effective_date, external_account_id: $external_account_id, funding: $funding, individual_id: $individual_id, individual_name: $individual_name, require_approval: $require_approval, routing_number: $routing_number, standard_entry_class_code: $standard_entry_class_code, statement_descriptor: $statement_descriptor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an ACH Transfer
#
# GET /ach_transfers/{ach_transfer_id}
# operationId: retrieve_an_ach_transfer
export def "ach-transfers transfer-by-ach_transfer_id" [
  ach_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ach_transfers/($ach_transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve an ACH Transfer
#
# POST /ach_transfers/{ach_transfer_id}/approve
# operationId: approve_an_ach_transfer
export def "ach-transfers-approve transfer" [
  ach_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ach_transfers/($ach_transfer_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a pending ACH Transfer
#
# POST /ach_transfers/{ach_transfer_id}/cancel
# operationId: cancel_a_pending_ach_transfer
export def "ach-transfers-cancel transfer" [
  ach_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ach_transfers/($ach_transfer_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Card Disputes
#
# GET /card_disputes
# operationId: list_card_disputes
export def "card-disputes disputes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
  --statusin: list
]: nothing -> record<data: table<acceptance: record, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar") (serialize-qp "status.in" $statusin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/card_disputes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Card Dispute
#
# POST /card_disputes
# operationId: create_a_card_dispute
export def "card-disputes dispute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  disputed_transaction_id: string # The Transaction you wish to dispute. This Transaction must have a `source_type` of `card_settlement`.
  explanation: string # Why you are disputing this Transaction.
]: any -> record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/card_disputes")
  let body = {disputed_transaction_id: $disputed_transaction_id, explanation: $explanation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Card Dispute
#
# GET /card_disputes/{card_dispute_id}
# operationId: retrieve_a_card_dispute
export def "card-disputes dispute-by-card_dispute_id" [
  card_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/card_disputes/($card_dispute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Card Profiles
#
# GET /card_profiles
# operationId: list_card_profiles
export def "card-profiles profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --statusin: list
]: nothing -> record<data: table<created_at: string, description: string, digital_wallets: record, id: string, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status.in" $statusin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/card_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Card Profile
#
# POST /card_profiles
# operationId: create_a_card_profile
# --digital_wallets shape: {app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email?: string, contact_phone?: string, contact_website?: string, issuer_name: string, text_color?: record}
export def "card-profiles profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # A description you can use to identify the Card Profile.
  digital_wallets: record # How Cards should appear in digital wallets such as Apple Pay. Different wallets will use these values to render card artwork appropriately for their app. — shape: {app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email?: string, contact_phone?: string, contact_website?: string, issuer_name: string, text_color?: record}
]: any -> record<created_at: string, description: string, digital_wallets: record<app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email: string, contact_phone: string, contact_website: string, issuer_name: string, text_color: record<blue: int, green: int, red: int>>, id: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/card_profiles")
  let body = {description: $description, digital_wallets: $digital_wallets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Card Profile
#
# GET /card_profiles/{card_profile_id}
# operationId: retrieve_a_card_profile
export def "card-profiles profile-by-card_profile_id" [
  card_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, description: string, digital_wallets: record<app_icon_file_id: string, background_image_file_id: string, card_description: string, contact_email: string, contact_phone: string, contact_website: string, issuer_name: string, text_color: record<blue: int, green: int, red: int>>, id: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/card_profiles/($card_profile_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Cards
#
# GET /cards
# operationId: list_cards
export def "cards cards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, billing_address: record, created_at: string, description: string, digital_wallet: record, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Card
#
# POST /cards
# operationId: create_a_card
# --billing_address shape: {city: string, line1: string, line2?: string, postal_code: string, state: string}
# --digital_wallet shape: {card_profile_id?: string, email?: string, phone?: string}
export def "cards card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The Account the card should belong to.
  --billing-address: record # The card's billing address. — shape: {city: string, line1: string, line2?: string, postal_code: string, state: string}
  --description: string # The description you choose to give the card.
  --digital-wallet: record # The contact information used in the two-factor steps for digital wallet card creation. At least one field must be present to complete the digital wallet steps. — shape: {card_profile_id?: string, email?: string, phone?: string}
]: any -> record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards")
  let body = {account_id: $account_id, billing_address: $billing_address, description: $description, digital_wallet: $digital_wallet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Card
#
# GET /cards/{card_id}
# operationId: retrieve_a_card
export def "cards card-by-card_id" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($card_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Card
#
# PATCH /cards/{card_id}
# operationId: update_a_card
# --billing_address shape: {city: string, line1: string, line2?: string, postal_code: string, state: string}
# --digital_wallet shape: {card_profile_id?: string, email?: string, phone?: string}
export def "cards card-by-card_id-1" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-address: record # The card's updated billing address. — shape: {city: string, line1: string, line2?: string, postal_code: string, state: string}
  --description: string # The description you choose to give the card.
  --digital-wallet: record # The contact information used in the two-factor steps for digital wallet card creation. At least one field must be present to complete the digital wallet steps. — shape: {card_profile_id?: string, email?: string, phone?: string}
  --status: string@status-completer # The status to update the Card with.
]: any -> record<account_id: string, billing_address: record<city: string, line1: string, line2: string, postal_code: string, state: string>, created_at: string, description: string, digital_wallet: record<card_profile_id: string, email: string, phone: string>, expiration_month: int, expiration_year: int, id: string, last4: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($card_id)")
  let body = {billing_address: $billing_address, description: $description, digital_wallet: $digital_wallet, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve sensitive details for a Card
#
# GET /cards/{card_id}/details
# operationId: retrieve_sensitive_details_for_a_card
export def "cards-details card" [
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card_id: string, expiration_month: int, expiration_year: int, primary_account_number: string, type: string, verification_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($card_id)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Check Deposits
#
# GET /check_deposits
# operationId: list_check_deposits
export def "check-deposits deposits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record, deposit_rejection: record, deposit_return: record, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/check_deposits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Check Deposit
#
# POST /check_deposits
# operationId: create_a_check_deposit
export def "check-deposits deposit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the Account to deposit the check in.
  amount: int # The deposit amount in the minor unit of the account currency. For dollars, for example, this is cents.
  back_image_file_id: string # The File containing the check's back image.
  currency: string # The currency to use for the deposit.
  front_image_file_id: string # The File containing the check's front image.
]: any -> record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/check_deposits")
  let body = {account_id: $account_id, amount: $amount, back_image_file_id: $back_image_file_id, currency: $currency, front_image_file_id: $front_image_file_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Check Deposit
#
# GET /check_deposits/{check_deposit_id}
# operationId: retrieve_a_check_deposit
export def "check-deposits deposit-by-check_deposit_id" [
  check_deposit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/check_deposits/($check_deposit_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Check Transfers
#
# GET /check_transfers
# operationId: list_check_transfers
export def "check-transfers transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record, status: string, stop_payment_request: record, submission: record, submitted_at: string, template_id: string, transaction_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/check_transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Check Transfer
#
# POST /check_transfers
# operationId: create_a_check_transfer
# --return_address shape: {city: string, line1: string, line2?: string, name: string, state: string, zip: string}
export def "check-transfers transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the account that will send the transfer.
  address_city: string # The city of the check's destination.
  address_line1: string # The street address of the check's destination.
  --address-line2: string # The second line of the address of the check's destination.
  address_state: string # The state of the check's destination.
  address_zip: string # The postal code of the check's destination.
  amount: int # The transfer amount in cents.
  message: string # The descriptor that will be printed on the memo field on the check.
  --note: string # The descriptor that will be printed on the letter included with the check.
  recipient_name: string # The name that will be printed on the check.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
  --return-address: record # The return address to be printed on the check. If omitted this will default to the address of the Entity of the Account used to make the Check Transfer. — shape: {city: string, line1: string, line2?: string, name: string, state: string, zip: string}
]: any -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/check_transfers")
  let body = {account_id: $account_id, address_city: $address_city, address_line1: $address_line1, address_line2: $address_line2, address_state: $address_state, address_zip: $address_zip, amount: $amount, message: $message, note: $note, recipient_name: $recipient_name, require_approval: $require_approval, return_address: $return_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Check Transfer
#
# GET /check_transfers/{check_transfer_id}
# operationId: retrieve_a_check_transfer
export def "check-transfers transfer-by-check_transfer_id" [
  check_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/check_transfers/($check_transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve a Check Transfer
#
# POST /check_transfers/{check_transfer_id}/approve
# operationId: approve_a_check_transfer
export def "check-transfers-approve transfer" [
  check_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/check_transfers/($check_transfer_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a pending Check Transfer
#
# POST /check_transfers/{check_transfer_id}/cancel
# operationId: cancel_a_pending_check_transfer
export def "check-transfers-cancel transfer" [
  check_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/check_transfers/($check_transfer_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a stop payment on a Check Transfer
#
# POST /check_transfers/{check_transfer_id}/stop_payment
# operationId: request_a_stop_payment_on_a_check_transfer
export def "check-transfers-stop-payment transfer" [
  check_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/check_transfers/($check_transfer_id)/stop_payment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Declined Transactions
#
# GET /declined_transactions
# operationId: list_declined_transactions
export def "declined-transactions transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
  --route-id: string
]: nothing -> record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar") (serialize-qp "route_id" $route_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/declined_transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Declined Transaction
#
# GET /declined_transactions/{declined_transaction_id}
# operationId: retrieve_a_declined_transaction
export def "declined-transactions transaction" [
  declined_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_id: string, originator_company_name: string, reason: string, receiver_id_number: string, receiver_name: string, trace_number: string>, card_decline: record<amount: int, currency: string, digital_wallet_token_id: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string, network: string, network_details: record, real_time_decision_id: string, reason: string>, card_route_decline: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, category: string, check_decline: record<amount: int, auxiliary_on_us: string, reason: string>, inbound_real_time_payments_transfer_decline: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, reason: string, remittance_information: string, transaction_identification: string>, international_ach_decline: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/declined_transactions/($declined_transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Digital Wallet Tokens
#
# GET /digital_wallet_tokens
# operationId: list_digital_wallet_tokens
export def "digital-wallet-tokens tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --card-id: string # e.g. card_oubs0hwk5rn6knuecxg2
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<card_id: string, created_at: string, id: string, status: string, token_requestor: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "card_id" $card_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/digital_wallet_tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Digital Wallet Token
#
# GET /digital_wallet_tokens/{digital_wallet_token_id}
# operationId: retrieve_a_digital_wallet_token
export def "digital-wallet-tokens token" [
  digital_wallet_token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card_id: string, created_at: string, id: string, status: string, token_requestor: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/digital_wallet_tokens/($digital_wallet_token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Documents
#
# GET /documents
# operationId: list_documents
export def "documents documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --entity-id: string
  --categoryin: list
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "category.in" $categoryin "multi") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Document
#
# GET /documents/{document_id}
# operationId: retrieve_a_document
export def "documents document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($document_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Entities
#
# GET /entities
# operationId: list_entities
export def "entities entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> record<data: table<corporation: record, description: string, id: string, joint: record, natural_person: record, relationship: string, structure: string, supplemental_documents: list, trust: record, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Entity
#
# POST /entities
# operationId: create_an_entity
# --corporation shape: {address: record, beneficial_owners: list, incorporation_state?: string, name: string, tax_identifier: string, website?: string}
# --joint shape: {individuals: list, name?: string}
# --natural_person shape: {address: record, confirmed_no_us_tax_id?: bool, date_of_birth: string, identification: record, name: string}
# --supplemental_documents item shape: {file_id: string}
# --trust shape: {address: record, category: "revocable"|"irrevocable", formation_document_file_id?: string, formation_state?: string, grantor?: record, name: string, tax_identifier?: string, trustees: list}
export def "entities entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --corporation: record # Details of the corporation entity to create. Required if `structure` is equal to `corporation`. — shape: {address: record, beneficial_owners: list, incorporation_state?: string, name: string, tax_identifier: string, website?: string}
  --description: string # The description you choose to give the entity.
  --joint: record # Details of the joint entity to create. Required if `structure` is equal to `joint`. — shape: {individuals: list, name?: string}
  --natural-person: record # Details of the natural person entity to create. Required if `structure` is equal to `natural_person`. Natural people entities should be submitted with `social_security_number` or `individual_taxpayer_identification_number` identification methods. — shape: {address: record, confirmed_no_us_tax_id?: bool, date_of_birth: string, identification: record, name: string}
  relationship: string@relationship-completer # The relationship between your group and the entity.
  structure: string@structure-completer # The type of Entity to create.
  --supplemental-documents: list # Additional documentation associated with the entity. — item shape: {file_id: string}
  --trust: record # Details of the trust entity to create. Required if `structure` is equal to `trust`. — shape: {address: record, category: "revocable"|"irrevocable", formation_document_file_id?: string, formation_state?: string, grantor?: record, name: string, tax_identifier?: string, trustees: list}
]: any -> record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entities")
  let body = {corporation: $corporation, description: $description, joint: $joint, natural_person: $natural_person, relationship: $relationship, structure: $structure, supplemental_documents: $supplemental_documents, trust: $trust} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Entity
#
# GET /entities/{entity_id}
# operationId: retrieve_an_entity
export def "entities entity-by-entity_id" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entities/($entity_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a supplemental document for an Entity
#
# POST /entities/{entity_id}/supplemental_documents
# operationId: create_a_supplemental_document_for_an_entity
export def "entities-supplemental-documents entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string # The identifier of the File containing the document.
]: any -> record<corporation: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, beneficial_owners: list<record>, incorporation_state: string, name: string, tax_identifier: string, website: string>, description: string, id: string, joint: record<individuals: list<record>, name: string>, natural_person: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, date_of_birth: string, identification: record<method: string, number_last4: string>, name: string>, relationship: string, structure: string, supplemental_documents: table<file_id: string>, trust: record<address: record<city: string, line1: string, line2: string, state: string, zip: string>, category: string, formation_document_file_id: string, formation_state: string, grantor: record<address: record, date_of_birth: string, identification: record, name: string>, name: string, tax_identifier: string, trustees: list<record>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entities/($entity_id)/supplemental_documents")
  let body = {file_id: $file_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Event Subscriptions
#
# GET /event_subscriptions
# operationId: list_event_subscriptions
export def "event-subscriptions subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> record<data: table<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/event_subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Event Subscription
#
# POST /event_subscriptions
# operationId: create_an_event_subscription
export def "event-subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --selected-event-category: string@selected-event-category-completer # If specified, this subscription will only receive webhooks for Events with the specified `category`.
  --shared-secret: string # The key that will be used to sign webhooks. If no value is passed, a random string will be used as default.
  --body-url: string # The URL you'd like us to send webhooks to.
]: any -> record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event_subscriptions")
  let body = {selected_event_category: $selected_event_category, shared_secret: $shared_secret, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Event Subscription
#
# GET /event_subscriptions/{event_subscription_id}
# operationId: retrieve_an_event_subscription
export def "event-subscriptions subscription-by-event_subscription_id" [
  event_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_subscriptions/($event_subscription_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Event Subscription
#
# PATCH /event_subscriptions/{event_subscription_id}
# operationId: update_an_event_subscription
export def "event-subscriptions subscription-by-event_subscription_id-1" [
  event_subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # The status to update the Event Subscription with.
]: any -> record<created_at: string, id: string, selected_event_category: string, shared_secret: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/event_subscriptions/($event_subscription_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Events
#
# GET /events
# operationId: list_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
  --categoryin: list
  --associated-object-id: string
]: nothing -> record<data: table<associated_object_id: string, associated_object_type: string, category: string, created_at: string, id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar") (serialize-qp "category.in" $categoryin "multi") (serialize-qp "associated_object_id" $associated_object_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Event
#
# GET /events/{event_id}
# operationId: retrieve_an_event
export def "events event" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<associated_object_id: string, associated_object_type: string, category: string, created_at: string, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/events/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List External Accounts
#
# GET /external_accounts
# operationId: list_external_accounts
export def "external-accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --statusin: list
]: nothing -> record<data: table<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status.in" $statusin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/external_accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an External Account
#
# POST /external_accounts
# operationId: create_an_external_account
export def "external-accounts account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string # The account number for the destination account.
  description: string # The name you choose for the Account.
  --funding: string@funding-completer-1 # The type of the destination account. Defaults to `checking`.
  routing_number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
]: any -> record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/external_accounts")
  let body = {account_number: $account_number, description: $description, funding: $funding, routing_number: $routing_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an External Account
#
# GET /external_accounts/{external_account_id}
# operationId: retrieve_an_external_account
export def "external-accounts account-by-external_account_id" [
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_accounts/($external_account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an External Account
#
# PATCH /external_accounts/{external_account_id}
# operationId: update_an_external_account
export def "external-accounts account-by-external_account_id-1" [
  external_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description you choose to give the external account.
  --status: string@status-completer-3 # The status of the External Account.
]: any -> record<account_number: string, created_at: string, description: string, funding: string, id: string, routing_number: string, status: string, type: string, verification_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/external_accounts/($external_account_id)")
  let body = {description: $description, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Files
#
# GET /files
# operationId: list_files
export def "files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
  --purposein: list
]: nothing -> record<data: table<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar") (serialize-qp "purpose.in" $purposein "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a File
#
# POST /files
# operationId: create_a_file
export def "files file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description you choose to give the File.
  file: string # The file contents. This should follow the specifications of [RFC 7578](https://datatracker.ietf.org/doc/html/rfc7578) which defines file transfers for the multipart/form-data protocol. (format: binary)
  purpose: string@purpose-completer # What the File will be used for in Increase's systems.
]: any -> record<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let body = {description: $description, file: $file, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve a File
#
# GET /files/{file_id}
# operationId: retrieve_a_file
export def "files file-by-file_id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, description: string, direction: string, download_url: string, filename: string, id: string, purpose: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Group details
#
# GET /groups/current
# operationId: retrieve_group_details
export def "groups-current details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ach_debit_status: string, activation_status: string, created_at: string, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Inbound ACH Transfer Returns
#
# GET /inbound_ach_transfer_returns
# operationId: list_inbound_ach_transfer_returns
export def "inbound-ach-transfer-returns returns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> record<data: table<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record, transaction_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inbound_ach_transfer_returns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an ACH Return
#
# POST /inbound_ach_transfer_returns
# operationId: create_an_ach_return
export def "inbound-ach-transfer-returns return" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string@reason-completer # The reason why this transfer will be returned. The most usual return codes are `payment_stopped` for debits and `credit_entry_refused_by_receiver` for credits.
  transaction_id: string # The transaction identifier of the Inbound ACH Transfer to return to the originating financial institution.
]: any -> record<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record<submitted_at: string, trace_number: string>, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/inbound_ach_transfer_returns")
  let body = {reason: $reason, transaction_id: $transaction_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Inbound ACH Transfer Return
#
# GET /inbound_ach_transfer_returns/{inbound_ach_transfer_return_id}
# operationId: retrieve_an_inbound_ach_transfer_return
export def "inbound-ach-transfer-returns return-by-inbound_ach_transfer_return_id" [
  inbound_ach_transfer_return_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, inbound_ach_transfer_transaction_id: string, reason: string, status: string, submission: record<submitted_at: string, trace_number: string>, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inbound_ach_transfer_returns/($inbound_ach_transfer_return_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Inbound Wire Drawdown Requests
#
# GET /inbound_wire_drawdown_requests
# operationId: list_inbound_wire_drawdown_requests
export def "inbound-wire-drawdown-requests requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> record<data: table<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inbound_wire_drawdown_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an Inbound Wire Drawdown Request
#
# GET /inbound_wire_drawdown_requests/{inbound_wire_drawdown_request_id}
# operationId: retrieve_an_inbound_wire_drawdown_request
export def "inbound-wire-drawdown-requests request" [
  inbound_wire_drawdown_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inbound_wire_drawdown_requests/($inbound_wire_drawdown_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Limits
#
# GET /limits
# operationId: list_limits
export def "limits limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --model-id: string # e.g. account_number_v18nkfqm6afpsrvy82b2
  --status: string # e.g. active
]: nothing -> record<data: table<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "model_id" $model_id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/limits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Limit
#
# POST /limits
# operationId: create_a_limit
export def "limits limit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string@interval-completer # The interval for the metric. Required if `metric` is `count` or `volume`.
  metric: string@metric-completer # The metric for the limit.
  model_id: string # The identifier of the Account or Account Number you wish to associate the limit with.
  value: int # The value to test the limit against.
]: any -> record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/limits")
  let body = {interval: $interval, metric: $metric, model_id: $model_id, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Limit
#
# GET /limits/{limit_id}
# operationId: retrieve_a_limit
export def "limits limit-by-limit_id" [
  limit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/limits/($limit_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Limit
#
# PATCH /limits/{limit_id}
# operationId: update_a_limit
export def "limits limit-by-limit_id-1" [
  limit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-4 # The status to update the limit with.
]: any -> record<id: string, interval: string, metric: string, model_id: string, model_type: string, status: string, type: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/limits/($limit_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List OAuth Connections
#
# GET /oauth_connections
# operationId: list_oauth_connections
export def "oauth-connections connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> record<data: table<created_at: string, group_id: string, id: string, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an OAuth Connection
#
# GET /oauth_connections/{oauth_connection_id}
# operationId: retrieve_an_oauth_connection
export def "oauth-connections connection" [
  oauth_connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, group_id: string, id: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/oauth_connections/($oauth_connection_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Pending Transactions
#
# GET /pending_transactions
# operationId: list_pending_transactions
export def "pending-transactions transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string
  --route-id: string
  --source-id: string
  --statusin: list
]: nothing -> record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, status: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "route_id" $route_id "scalar") (serialize-qp "source_id" $source_id "scalar") (serialize-qp "status.in" $statusin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/pending_transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Pending Transaction
#
# GET /pending_transactions/{pending_transaction_id}
# operationId: retrieve_a_pending_transaction
export def "pending-transactions transaction" [
  pending_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_instruction: record<amount: int, currency: string, transfer_id: string>, ach_transfer_instruction: record<amount: int, transfer_id: string>, card_authorization: record<amount: int, currency: string, digital_wallet_token_id: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record, real_time_decision_id: string>, card_route_authorization: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, category: string, check_deposit_instruction: record<amount: int, back_image_file_id: string, check_deposit_id: string, currency: string, front_image_file_id: string>, check_transfer_instruction: record<amount: int, currency: string, transfer_id: string>, inbound_funds_hold: record<amount: int, automatically_releases_at: string, currency: string, held_transaction_id: string, released_at: string, status: string>, wire_drawdown_payment_instruction: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string>, wire_transfer_instruction: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>>, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pending_transactions/($pending_transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Real-Time Decision
#
# GET /real_time_decisions/{real_time_decision_id}
# operationId: retrieve_a_real_time_decision
export def "real-time-decisions decision" [
  real_time_decision_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card_authorization: record<account_id: string, card_id: string, decision: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record<visa: record>, presentment_amount: int, presentment_currency: string, settlement_amount: int, settlement_currency: string>, category: string, created_at: string, digital_wallet_authentication: record<card_id: string, channel: string, digital_wallet: string, email: string, one_time_passcode: string, phone: string, result: string>, digital_wallet_token: record<card_id: string, card_profile_id: string, decision: string, digital_wallet: string>, id: string, status: string, timeout_at: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/real_time_decisions/($real_time_decision_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Action a Real-Time Decision
#
# POST /real_time_decisions/{real_time_decision_id}/action
# operationId: action_a_real_time_decision
# --card_authorization shape: {decision: "approve"|"decline"}
# --digital_wallet_authentication shape: {result: "success"|"failure"}
# --digital_wallet_token shape: {approval?: record, decline?: record}
export def "real-time-decisions-action decision" [
  real_time_decision_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --card-authorization: record # If the Real-Time Decision relates to a card authorization attempt, this object contains your response to the authorization. — shape: {decision: "approve"|"decline"}
  --digital-wallet-authentication: record # If the Real-Time Decision relates to a digital wallet authentication attempt, this object contains your response to the authentication. — shape: {result: "success"|"failure"}
  --digital-wallet-token: record # If the Real-Time Decision relates to a digital wallet token provisioning attempt, this object contains your response to the attempt. — shape: {approval?: record, decline?: record}
]: any -> record<card_authorization: record<account_id: string, card_id: string, decision: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, network: string, network_details: record<visa: record>, presentment_amount: int, presentment_currency: string, settlement_amount: int, settlement_currency: string>, category: string, created_at: string, digital_wallet_authentication: record<card_id: string, channel: string, digital_wallet: string, email: string, one_time_passcode: string, phone: string, result: string>, digital_wallet_token: record<card_id: string, card_profile_id: string, decision: string, digital_wallet: string>, id: string, status: string, timeout_at: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/real_time_decisions/($real_time_decision_id)/action")
  let body = {card_authorization: $card_authorization, digital_wallet_authentication: $digital_wallet_authentication, digital_wallet_token: $digital_wallet_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Routing Numbers
#
# GET /routing_numbers
# operationId: list_routing_numbers
export def "routing-numbers numbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --routing-number: string # e.g. 021000021
]: nothing -> record<data: table<ach_transfers: string, name: string, real_time_payments_transfers: string, routing_number: string, type: string, wire_transfers: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "routing_number" $routing_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/routing_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Simulate an Account Statement being created
#
# POST /simulations/account_statements
# operationId: simulate_an_account_statement_being_created
export def "simulations-account-statements created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier of the Account the statement is for.
]: any -> record<account_id: string, created_at: string, ending_balance: int, file_id: string, id: string, starting_balance: int, statement_period_end: string, statement_period_start: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/account_statements")
  let body = {account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete a Sandbox Account Transfer
#
# POST /simulations/account_transfers/{account_transfer_id}/complete
# operationId: complete_a_sandbox_account_transfer
export def "simulations-account-transfers-complete transfer" [
  account_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, created_at: string, currency: string, description: string, destination_account_id: string, destination_transaction_id: string, id: string, network: string, status: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/account_transfers/($account_transfer_id)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a Sandbox ACH Transfer
#
# POST /simulations/ach_transfers/{ach_transfer_id}/return
# operationId: return_a_sandbox_ach_transfer
export def "simulations-ach-transfers-return transfer" [
  ach_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string@reason-completer-1 # The reason why the Federal Reserve or destination bank returned this transfer. Defaults to `no_account`.
]: any -> record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/ach_transfers/($ach_transfer_id)/return")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Submit a Sandbox ACH Transfer
#
# POST /simulations/ach_transfers/{ach_transfer_id}/submit
# operationId: submit_a_sandbox_ach_transfer
export def "simulations-ach-transfers-submit transfer" [
  ach_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, addendum: string, amount: int, approval: record<approved_at: string>, cancellation: record<canceled_at: string>, company_descriptive_date: string, company_discretionary_data: string, company_entry_description: string, company_name: string, created_at: string, currency: string, external_account_id: string, funding: string, id: string, individual_id: string, individual_name: string, network: string, notification_of_change: record<change_code: string, corrected_data: string, created_at: string>, return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, routing_number: string, standard_entry_class_code: string, statement_descriptor: string, status: string, submission: record<submitted_at: string, trace_number: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/ach_transfers/($ach_transfer_id)/submit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Simulate an authorization on a Card
#
# POST /simulations/card_authorizations
# operationId: simulate_an_authorization_on_a_card
export def "simulations-card-authorizations card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # The authorization amount in cents.
  --card-id: string # The identifier of the Card to be authorized.
  --digital-wallet-token-id: string # The identifier of the Digital Wallet Token to be authorized.
]: any -> record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, pending_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_instruction: record, ach_transfer_instruction: record, card_authorization: record, card_route_authorization: record, category: string, check_deposit_instruction: record, check_transfer_instruction: record, inbound_funds_hold: record, wire_drawdown_payment_instruction: record, wire_transfer_instruction: record>, status: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/card_authorizations")
  let body = {amount: $amount, card_id: $card_id, digital_wallet_token_id: $digital_wallet_token_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulates advancing the state of a card dispute
#
# POST /simulations/card_disputes/{card_dispute_id}/action
# operationId: simulates_advancing_the_state_of_a_card_dispute
export def "simulations-card-disputes-action dispute" [
  card_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explanation: string # Why the dispute was rejected. Not required for accepting disputes.
  status: string@status-completer-5 # The status to move the dispute to.
]: any -> record<acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, created_at: string, disputed_transaction_id: string, explanation: string, id: string, rejection: record<card_dispute_id: string, explanation: string, rejected_at: string>, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/card_disputes/($card_dispute_id)/action")
  let body = {explanation: $explanation, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate a refund on a card
#
# POST /simulations/card_refunds
# operationId: simulate_a_refund_on_a_card
export def "simulations-card-refunds card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction_id: string # The identifier for the Transaction to refund. The Transaction's source must have a category of card_settlement.
]: any -> record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/card_refunds")
  let body = {transaction_id: $transaction_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate settling a card authorization
#
# POST /simulations/card_settlements
# operationId: simulate_settling_a_card_authorization
export def "simulations-card-settlements authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The amount to be settled. This defaults to the amount of the Pending Transaction being settled.
  card_id: string # The identifier of the Card to create a settlement on.
  pending_transaction_id: string # The identifier of the Pending Transaction for the Card Authorization you wish to settle.
]: any -> record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/card_settlements")
  let body = {amount: $amount, card_id: $card_id, pending_transaction_id: $pending_transaction_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reject a Sandbox Check Deposit
#
# POST /simulations/check_deposits/{check_deposit_id}/reject
# operationId: reject_a_sandbox_check_deposit
export def "simulations-check-deposits-reject deposit" [
  check_deposit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/check_deposits/($check_deposit_id)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a Sandbox Check Deposit
#
# POST /simulations/check_deposits/{check_deposit_id}/return
# operationId: return_a_sandbox_check_deposit
export def "simulations-check-deposits-return deposit" [
  check_deposit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/check_deposits/($check_deposit_id)/return")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a Sandbox Check Deposit
#
# POST /simulations/check_deposits/{check_deposit_id}/submit
# operationId: submit_a_sandbox_check_deposit
export def "simulations-check-deposits-submit deposit" [
  check_deposit_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, back_image_file_id: string, created_at: string, currency: string, deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, deposit_rejection: record<amount: int, currency: string, reason: string, rejected_at: string>, deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, front_image_file_id: string, id: string, status: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/check_deposits/($check_deposit_id)/submit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deposit a Sandbox Check Transfer
#
# POST /simulations/check_transfers/{check_transfer_id}/deposit
# operationId: deposit_a_sandbox_check_transfer
export def "simulations-check-transfers-deposit transfer" [
  check_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/check_transfers/($check_transfer_id)/deposit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mail a Sandbox Check Transfer
#
# POST /simulations/check_transfers/{check_transfer_id}/mail
# operationId: mail_a_sandbox_check_transfer
export def "simulations-check-transfers-mail transfer" [
  check_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, created_at: string, currency: string, deposit: record<back_image_file_id: string, front_image_file_id: string, type: string>, id: string, mailed_at: string, message: string, note: string, recipient_name: string, return_address: record<city: string, line1: string, line2: string, name: string, state: string, zip: string>, status: string, stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, submission: record<check_number: string>, submitted_at: string, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/check_transfers/($check_transfer_id)/mail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Simulate digital wallet provisioning for a card
#
# POST /simulations/digital_wallet_token_requests
# operationId: simulate_digital_wallet_provisioning_for_a_card
export def "simulations-digital-wallet-token-requests card" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  card_id: string # The identifier of the Card to be authorized.
]: any -> record<decline_reason: string, digital_wallet_token_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/digital_wallet_token_requests")
  let body = {card_id: $card_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate a tax document being created
#
# POST /simulations/documents
# operationId: simulate_a_tax_document_being_created
export def "simulations-documents created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier of the Account the tax document is for.
]: any -> record<category: string, created_at: string, entity_id: string, file_id: string, id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/documents")
  let body = {account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate an ACH Transfer to your account
#
# POST /simulations/inbound_ach_transfers
# operationId: simulate_an_ach_transfer_to_your_account
export def "simulations-inbound-ach-transfers account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The identifier of the Account Number the inbound ACH Transfer is for.
  amount: int # The transfer amount in cents. A positive amount originates a credit transfer pushing funds to the receiving account. A negative amount originates a debit transfer pulling funds from the receiving account.
  --company-descriptive-date: string # The description of the date of the transfer.
  --company-discretionary-data: string # Data associated with the transfer set by the sender.
  --company-entry-description: string # The description of the transfer set by the sender.
  --company-id: string # The sender's company id.
  --company-name: string # The name of the sender.
]: any -> record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/inbound_ach_transfers")
  let body = {account_number_id: $account_number_id, amount: $amount, company_descriptive_date: $company_descriptive_date, company_discretionary_data: $company_discretionary_data, company_entry_description: $company_entry_description, company_id: $company_id, company_name: $company_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate a Real Time Payments Transfer to your account
#
# POST /simulations/inbound_real_time_payments_transfers
# operationId: simulate_a_real_time_payments_transfer_to_your_account
export def "simulations-inbound-real-time-payments-transfers account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The identifier of the Account Number the inbound Real Time Payments Transfer is for.
  amount: int # The transfer amount in USD cents. Must be positive.
  --debtor-account-number: string # The account number of the account that sent the transfer.
  --debtor-name: string # The name provided by the sender of the transfer.
  --debtor-routing-number: string # The routing number of the account that sent the transfer.
  --remittance-information: string # Additional information included with the transfer.
  --request-for-payment-id: string # The identifier of a pending Request for Payment that this transfer will fulfill.
]: any -> record<declined_transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<ach_decline: record, card_decline: record, card_route_decline: record, category: string, check_decline: record, inbound_real_time_payments_transfer_decline: record, international_ach_decline: record>, type: string>, transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/inbound_real_time_payments_transfers")
  let body = {account_number_id: $account_number_id, amount: $amount, debtor_account_number: $debtor_account_number, debtor_name: $debtor_name, debtor_routing_number: $debtor_routing_number, remittance_information: $remittance_information, request_for_payment_id: $request_for_payment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate an Inbound Wire Drawdown request being created
#
# POST /simulations/inbound_wire_drawdown_requests
# operationId: simulate_an_inbound_wire_drawdown_request_being_created
export def "simulations-inbound-wire-drawdown-requests created" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # The amount being requested in cents.
  beneficiary_account_number: string # The drawdown request's beneficiary's account number.
  --beneficiary-address-line1: string # Line 1 of the drawdown request's beneficiary's address.
  --beneficiary-address-line2: string # Line 2 of the drawdown request's beneficiary's address.
  --beneficiary-address-line3: string # Line 3 of the drawdown request's beneficiary's address.
  --beneficiary-name: string # The drawdown request's beneficiary's name.
  beneficiary_routing_number: string # The drawdown request's beneficiary's routing number.
  currency: string # The [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) code for the amount being requested. Will always be "USD".
  message_to_recipient: string # A message from the drawdown request's originator.
  originator_account_number: string # The drawdown request's originator's account number.
  --originator-address-line1: string # Line 1 of the drawdown request's originator's address.
  --originator-address-line2: string # Line 2 of the drawdown request's originator's address.
  --originator-address-line3: string # Line 3 of the drawdown request's originator's address.
  --originator-name: string # The drawdown request's originator's name.
  originator_routing_number: string # The drawdown request's originator's routing number.
  --originator-to-beneficiary-information-line1: string # Line 1 of the information conveyed from the originator of the message to the beneficiary.
  --originator-to-beneficiary-information-line2: string # Line 2 of the information conveyed from the originator of the message to the beneficiary.
  --originator-to-beneficiary-information-line3: string # Line 3 of the information conveyed from the originator of the message to the beneficiary.
  --originator-to-beneficiary-information-line4: string # Line 4 of the information conveyed from the originator of the message to the beneficiary.
  recipient_account_number_id: string # The Account Number to which the recipient of this request is being requested to send funds from.
]: any -> record<amount: int, beneficiary_account_number: string, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_routing_number: string, currency: string, id: string, message_to_recipient: string, originator_account_number: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_routing_number: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string, recipient_account_number_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/inbound_wire_drawdown_requests")
  let body = {amount: $amount, beneficiary_account_number: $beneficiary_account_number, beneficiary_address_line1: $beneficiary_address_line1, beneficiary_address_line2: $beneficiary_address_line2, beneficiary_address_line3: $beneficiary_address_line3, beneficiary_name: $beneficiary_name, beneficiary_routing_number: $beneficiary_routing_number, currency: $currency, message_to_recipient: $message_to_recipient, originator_account_number: $originator_account_number, originator_address_line1: $originator_address_line1, originator_address_line2: $originator_address_line2, originator_address_line3: $originator_address_line3, originator_name: $originator_name, originator_routing_number: $originator_routing_number, originator_to_beneficiary_information_line1: $originator_to_beneficiary_information_line1, originator_to_beneficiary_information_line2: $originator_to_beneficiary_information_line2, originator_to_beneficiary_information_line3: $originator_to_beneficiary_information_line3, originator_to_beneficiary_information_line4: $originator_to_beneficiary_information_line4, recipient_account_number_id: $recipient_account_number_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate a Wire Transfer to your account
#
# POST /simulations/inbound_wire_transfers
# operationId: simulate_a_wire_transfer_to_your_account
export def "simulations-inbound-wire-transfers account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The identifier of the Account Number the inbound Wire Transfer is for.
  amount: int # The transfer amount in cents. Must be positive.
  --beneficiary-address-line1: string # The sending bank will set beneficiary_address_line1 in production. You can simulate any value here.
  --beneficiary-address-line2: string # The sending bank will set beneficiary_address_line2 in production. You can simulate any value here.
  --beneficiary-address-line3: string # The sending bank will set beneficiary_address_line3 in production. You can simulate any value here.
  --beneficiary-name: string # The sending bank will set beneficiary_name in production. You can simulate any value here.
  --beneficiary-reference: string # The sending bank will set beneficiary_reference in production. You can simulate any value here.
  --originator-address-line1: string # The sending bank will set originator_address_line1 in production. You can simulate any value here.
  --originator-address-line2: string # The sending bank will set originator_address_line2 in production. You can simulate any value here.
  --originator-address-line3: string # The sending bank will set originator_address_line3 in production. You can simulate any value here.
  --originator-name: string # The sending bank will set originator_name in production. You can simulate any value here.
  --originator-to-beneficiary-information-line1: string # The sending bank will set originator_to_beneficiary_information_line1 in production. You can simulate any value here.
  --originator-to-beneficiary-information-line2: string # The sending bank will set originator_to_beneficiary_information_line2 in production. You can simulate any value here.
  --originator-to-beneficiary-information-line3: string # The sending bank will set originator_to_beneficiary_information_line3 in production. You can simulate any value here.
  --originator-to-beneficiary-information-line4: string # The sending bank will set originator_to_beneficiary_information_line4 in production. You can simulate any value here.
]: any -> record<transaction: record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record, ach_check_conversion: record, ach_check_conversion_return: record, ach_transfer_intention: record, ach_transfer_rejection: record, ach_transfer_return: record, card_dispute_acceptance: record, card_refund: record, card_route_refund: record, card_route_settlement: record, card_settlement: record, category: string, check_deposit_acceptance: record, check_deposit_return: record, check_transfer_intention: record, check_transfer_rejection: record, check_transfer_return: record, check_transfer_stop_payment_request: record, dispute_resolution: record, empyreal_cash_deposit: record, inbound_ach_transfer: record, inbound_check: record, inbound_international_ach_transfer: record, inbound_real_time_payments_transfer_confirmation: record, inbound_wire_drawdown_payment: record, inbound_wire_drawdown_payment_reversal: record, inbound_wire_reversal: record, inbound_wire_transfer: record, interest_payment: record, internal_source: record, sample_funds: record, wire_drawdown_payment_intention: record, wire_drawdown_payment_rejection: record, wire_transfer_intention: record, wire_transfer_rejection: record>, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations/inbound_wire_transfers")
  let body = {account_number_id: $account_number_id, amount: $amount, beneficiary_address_line1: $beneficiary_address_line1, beneficiary_address_line2: $beneficiary_address_line2, beneficiary_address_line3: $beneficiary_address_line3, beneficiary_name: $beneficiary_name, beneficiary_reference: $beneficiary_reference, originator_address_line1: $originator_address_line1, originator_address_line2: $originator_address_line2, originator_address_line3: $originator_address_line3, originator_name: $originator_name, originator_to_beneficiary_information_line1: $originator_to_beneficiary_information_line1, originator_to_beneficiary_information_line2: $originator_to_beneficiary_information_line2, originator_to_beneficiary_information_line3: $originator_to_beneficiary_information_line3, originator_to_beneficiary_information_line4: $originator_to_beneficiary_information_line4} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reverse a Sandbox Wire Transfer
#
# POST /simulations/wire_transfers/{wire_transfer_id}/reverse
# operationId: reverse_a_sandbox_wire_transfer
export def "simulations-wire-transfers-reverse transfer" [
  wire_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/wire_transfers/($wire_transfer_id)/reverse")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a Sandbox Wire Transfer
#
# POST /simulations/wire_transfers/{wire_transfer_id}/submit
# operationId: submit_a_sandbox_wire_transfer
export def "simulations-wire-transfers-submit transfer" [
  wire_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/wire_transfers/($wire_transfer_id)/submit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Transactions
#
# GET /transactions
# operationId: list_transactions
export def "transactions transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
  --categoryin: list
  --route-id: string
]: nothing -> record<data: table<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar") (serialize-qp "category.in" $categoryin "multi") (serialize-qp "route_id" $route_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Transaction
#
# GET /transactions/{transaction_id}
# operationId: retrieve_a_transaction
export def "transactions transaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, amount: int, created_at: string, currency: string, description: string, id: string, route_id: string, route_type: string, source: record<account_transfer_intention: record<amount: int, currency: string, description: string, destination_account_id: string, source_account_id: string, transfer_id: string>, ach_check_conversion: record<amount: int, file_id: string>, ach_check_conversion_return: record<amount: int, return_reason_code: string>, ach_transfer_intention: record<account_number: string, amount: int, routing_number: string, statement_descriptor: string, transfer_id: string>, ach_transfer_rejection: record<transfer_id: string>, ach_transfer_return: record<created_at: string, return_reason_code: string, transaction_id: string, transfer_id: string>, card_dispute_acceptance: record<accepted_at: string, card_dispute_id: string, transaction_id: string>, card_refund: record<amount: int, card_settlement_transaction_id: string, currency: string, type: string>, card_route_refund: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_route_settlement: record<amount: int, currency: string, merchant_acceptor_id: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_descriptor: string, merchant_state: string>, card_settlement: record<amount: int, currency: string, merchant_category_code: string, merchant_city: string, merchant_country: string, merchant_name: string, merchant_state: string, pending_transaction_id: string, presentment_amount: int, presentment_currency: string, type: string>, category: string, check_deposit_acceptance: record<account_number: string, amount: int, auxiliary_on_us: string, check_deposit_id: string, currency: string, routing_number: string, serial_number: string>, check_deposit_return: record<amount: int, check_deposit_id: string, currency: string, return_reason: string, returned_at: string, transaction_id: string>, check_transfer_intention: record<address_city: string, address_line1: string, address_line2: string, address_state: string, address_zip: string, amount: int, currency: string, recipient_name: string, transfer_id: string>, check_transfer_rejection: record<transfer_id: string>, check_transfer_return: record<file_id: string, transfer_id: string>, check_transfer_stop_payment_request: record<requested_at: string, transaction_id: string, transfer_id: string, type: string>, dispute_resolution: record<amount: int, currency: string, disputed_transaction_id: string>, empyreal_cash_deposit: record<amount: int, bag_id: string, deposit_date: string>, inbound_ach_transfer: record<amount: int, originator_company_descriptive_date: string, originator_company_discretionary_data: string, originator_company_entry_description: string, originator_company_id: string, originator_company_name: string, receiver_id_number: string, receiver_name: string, trace_number: string>, inbound_check: record<amount: int, check_front_image_file_id: string, check_number: string, check_rear_image_file_id: string, currency: string>, inbound_international_ach_transfer: record<amount: int, destination_country_code: string, destination_currency_code: string, foreign_exchange_indicator: string, foreign_exchange_reference: string, foreign_exchange_reference_indicator: string, foreign_payment_amount: int, foreign_trace_number: string, international_transaction_type_code: string, originating_currency_code: string, originating_depository_financial_institution_branch_country: string, originating_depository_financial_institution_id: string, originating_depository_financial_institution_id_qualifier: string, originating_depository_financial_institution_name: string, originator_city: string, originator_company_entry_description: string, originator_country: string, originator_identification: string, originator_name: string, originator_postal_code: string, originator_state_or_province: string, originator_street_address: string, payment_related_information: string, payment_related_information2: string, receiver_city: string, receiver_country: string, receiver_identification_number: string, receiver_postal_code: string, receiver_state_or_province: string, receiver_street_address: string, receiving_company_or_individual_name: string, receiving_depository_financial_institution_country: string, receiving_depository_financial_institution_id: string, receiving_depository_financial_institution_id_qualifier: string, receiving_depository_financial_institution_name: string, trace_number: string>, inbound_real_time_payments_transfer_confirmation: record<amount: int, creditor_name: string, currency: string, debtor_account_number: string, debtor_name: string, debtor_routing_number: string, remittance_information: string, transaction_identification: string>, inbound_wire_drawdown_payment: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string>, inbound_wire_drawdown_payment_reversal: record<amount: int, description: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string>, inbound_wire_reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, inbound_wire_transfer: record<amount: int, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, beneficiary_reference: string, description: string, input_message_accountability_data: string, originator_address_line1: string, originator_address_line2: string, originator_address_line3: string, originator_name: string, originator_to_beneficiary_information: string, originator_to_beneficiary_information_line1: string, originator_to_beneficiary_information_line2: string, originator_to_beneficiary_information_line3: string, originator_to_beneficiary_information_line4: string>, interest_payment: record<accrued_on_account_id: string, amount: int, currency: string, period_end: string, period_start: string>, internal_source: record<amount: int, currency: string, reason: string>, sample_funds: record<originator: string>, wire_drawdown_payment_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_drawdown_payment_rejection: record<transfer_id: string>, wire_transfer_intention: record<account_number: string, amount: int, message_to_recipient: string, routing_number: string, transfer_id: string>, wire_transfer_rejection: record<transfer_id: string>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Wire Drawdown Requests
#
# GET /wire_drawdown_requests
# operationId: list_wire_drawdown_requests
export def "wire-drawdown-requests requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
]: nothing -> record<data: table<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wire_drawdown_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Wire Drawdown Request
#
# POST /wire_drawdown_requests
# operationId: create_a_wire_drawdown_request
export def "wire-drawdown-requests request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number_id: string # The Account Number to which the recipient should send funds.
  amount: int # The amount requested from the recipient, in cents.
  message_to_recipient: string # A message the recipient will see as part of the request.
  recipient_account_number: string # The drawdown request's recipient's account number.
  --recipient-address-line1: string # Line 1 of the drawdown request's recipient's address.
  --recipient-address-line2: string # Line 2 of the drawdown request's recipient's address.
  --recipient-address-line3: string # Line 3 of the drawdown request's recipient's address.
  recipient_name: string # The drawdown request's recipient's name.
  recipient_routing_number: string # The drawdown request's recipient's routing number.
]: any -> record<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record<input_message_accountability_data: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wire_drawdown_requests")
  let body = {account_number_id: $account_number_id, amount: $amount, message_to_recipient: $message_to_recipient, recipient_account_number: $recipient_account_number, recipient_address_line1: $recipient_address_line1, recipient_address_line2: $recipient_address_line2, recipient_address_line3: $recipient_address_line3, recipient_name: $recipient_name, recipient_routing_number: $recipient_routing_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Wire Drawdown Request
#
# GET /wire_drawdown_requests/{wire_drawdown_request_id}
# operationId: retrieve_a_wire_drawdown_request
export def "wire-drawdown-requests request-by-wire_drawdown_request_id" [
  wire_drawdown_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number_id: string, amount: int, currency: string, fulfillment_transaction_id: string, id: string, message_to_recipient: string, recipient_account_number: string, recipient_address_line1: string, recipient_address_line2: string, recipient_address_line3: string, recipient_name: string, recipient_routing_number: string, status: string, submission: record<input_message_accountability_data: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wire_drawdown_requests/($wire_drawdown_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Wire Transfers
#
# GET /wire_transfers
# operationId: list_wire_transfers
export def "wire-transfers transfers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string
  --limit: int
  --account-id: string # e.g. account_in71c4amph0vgo2qllky
  --external-account-id: string
  --created-atafter: string # format: date-time
  --created-atbefore: string # format: date-time
  --created-aton-or-after: string # format: date-time
  --created-aton-or-before: string # format: date-time
]: nothing -> record<data: table<account_id: string, account_number: string, amount: int, approval: record, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record, routing_number: string, status: string, submission: record, template_id: string, transaction_id: string, type: string>, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "external_account_id" $external_account_id "scalar") (serialize-qp "created_at.after" $created_atafter "scalar") (serialize-qp "created_at.before" $created_atbefore "scalar") (serialize-qp "created_at.on_or_after" $created_aton_or_after "scalar") (serialize-qp "created_at.on_or_before" $created_aton_or_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wire_transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Wire Transfer
#
# POST /wire_transfers
# operationId: create_a_wire_transfer
export def "wire-transfers transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # The identifier for the account that will send the transfer.
  --account-number: string # The account number for the destination account.
  amount: int # The transfer amount in cents.
  --beneficiary-address-line1: string # The beneficiary's address line 1.
  --beneficiary-address-line2: string # The beneficiary's address line 2.
  --beneficiary-address-line3: string # The beneficiary's address line 3.
  beneficiary_name: string # The beneficiary's name.
  --external-account-id: string # The ID of an External Account to initiate a transfer to. If this parameter is provided, `account_number` and `routing_number` must be absent.
  message_to_recipient: string # The message that will show on the recipient's bank statement.
  --require-approval: oneof<nothing, bool> # Whether the transfer requires explicit approval via the dashboard or API.
  --routing-number: string # The American Bankers' Association (ABA) Routing Transit Number (RTN) for the destination account.
]: any -> record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wire_transfers")
  let body = {account_id: $account_id, account_number: $account_number, amount: $amount, beneficiary_address_line1: $beneficiary_address_line1, beneficiary_address_line2: $beneficiary_address_line2, beneficiary_address_line3: $beneficiary_address_line3, beneficiary_name: $beneficiary_name, external_account_id: $external_account_id, message_to_recipient: $message_to_recipient, require_approval: $require_approval, routing_number: $routing_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a Wire Transfer
#
# GET /wire_transfers/{wire_transfer_id}
# operationId: retrieve_a_wire_transfer
export def "wire-transfers transfer-by-wire_transfer_id" [
  wire_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wire_transfers/($wire_transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve a Wire Transfer
#
# POST /wire_transfers/{wire_transfer_id}/approve
# operationId: approve_a_wire_transfer
export def "wire-transfers-approve transfer" [
  wire_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wire_transfers/($wire_transfer_id)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a pending Wire Transfer
#
# POST /wire_transfers/{wire_transfer_id}/cancel
# operationId: cancel_a_pending_wire_transfer
export def "wire-transfers-cancel transfer" [
  wire_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_id: string, account_number: string, amount: int, approval: record<approved_at: string>, beneficiary_address_line1: string, beneficiary_address_line2: string, beneficiary_address_line3: string, beneficiary_name: string, cancellation: record<canceled_at: string>, created_at: string, currency: string, external_account_id: string, id: string, message_to_recipient: string, network: string, reversal: record<amount: int, description: string, financial_institution_to_financial_institution_information: string, input_cycle_date: string, input_message_accountability_data: string, input_sequence_number: string, input_source: string, previous_message_input_cycle_date: string, previous_message_input_message_accountability_data: string, previous_message_input_sequence_number: string, previous_message_input_source: string, receiver_financial_institution_information: string>, routing_number: string, status: string, submission: record<input_message_accountability_data: string, submitted_at: string>, template_id: string, transaction_id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/wire_transfers/($wire_transfer_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
