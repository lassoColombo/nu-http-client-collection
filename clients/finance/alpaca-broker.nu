# Auto-generated client for Broker API v1.0.0
# Source: https://raw.githubusercontent.com/alpacahq/alpaca-docs/master/oas/broker/openapi.yaml
# Auth: --token flag or $env.BROKER_API_TOKEN

const BASE_URL = "https://broker-api.sandbox.alpaca.markets"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BROKER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://broker-api.sandbox.alpaca.markets" "https://broker-api.alpaca.markets"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def sort-completer [] { ["asc" "desc"] }
def type-completer [] { ["account_approval_letter" "address_verification" "cip_result" "date_of_birth_verification" "identity_verification" "tax_id_verification"] }
def document-type-completer [] { ["account_approval_letter" "address_verification" "cip_result" "date_of_birth_verification" "identity_verification" "tax_id_verification"] }
def status-completer [] { ["ACTIVE" "INACTIVE"] }
def bank-code-type-completer [] { ["ABA" "BIC"] }
def direction-completer [] { ["INCOMING" "OUTGOING"] }
def transfer-type-completer [] { ["ach" "instant_ach" "wire"] }
def timing-completer [] { ["immediate"] }
def direction-completer-1 [] { ["asc" "desc"] }
def bank-account-type-completer [] { ["CHECKING" "SAVINGS"] }
def time-in-force-completer [] { ["cls" "day" "fok" "gtc" "ioc" "opg"] }
def status-completer-1 [] { ["all" "closed" "open"] }
def side-completer [] { ["buy" "buy_minus" "cross" "cross_short" "sell" "sell_plus" "sell_short" "sell_short_exempt" "undisclosed"] }
def type-completer-1 [] { ["limit" "market" "stop" "stop_limit" "trailing_stop"] }
def order-class-completer [] { ["bracket" "oco" "oto" "simple"] }
def status-completer-2 [] { ["active" "all" "inactive"] }
def asset-class-completer [] { ["crypto" "us_equity"] }
def status-completer-3 [] { ["canceled" "deleted" "executed" "pending" "queued" "rejected"] }
def entry-type-completer [] { ["JNLC" "JNLS"] }
def entry-type-completer-1 [] { ["JNLC"] }
def response-type-completer [] { ["code" "token"] }
def date-type-completer [] { ["declaration_date" "ex_date" "payable_date" "record_date"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list" } } | get name | first)
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

# Get all accounts
#
# GET /v1/accounts
# operationId: getAllAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Pass space-delimited tokens. The response will contain accounts that match with each of the tokens (logical AND). A match means the token is present in either the account’s associated account number, phone number, name, or e-mail address (logical OR).
  --created-after: string # format: date-time
  --created-before: string # format: date-time
  --status: string # See the AccountStatus model for values
  --qp-sort: string@sort-completer # The chronological order of response based on the submission time. asc or desc. Defaults to desc. (e.g. desc)
  --entities: string # Comma-delimited entity names to include in the response
]: nothing -> table<id: string, account_number: string, status: string, crypto_status: string, currency: string, created_at: string, last_equity: string, kyc_results: record<reject: record, accept: record, indeterminate: record, addidional_information: string>, account_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "created_after" $created_after "scalar") (serialize-qp "created_before" $created_before "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "entities" $entities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an account
#
# POST /v1/accounts
# operationId: createAccount
# --contact shape: {email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string}
# --identity shape: {given_name: string, family_name: string, date_of_birth: string, tax_id?: string, tax_id_type?: "NOT_SPECIFIED"|"USA_SSN"|"ARG_AG_CUIT"|"AUS_TFN"|"AUS_ABN"|"BOL_NIT"|"BRA_CPF"|"CHL_RUT"|"COL_NIT"|"CRI_NITE"|"DEU_TAX_ID"|"DOM_RNC"|"ECU_RUC"|"FRA_SPI"|"GBR_UTR"|"GBR_NINO"|"GTM_NIT"|"HND_RTN"|"HUN_TIN"|"IDN_KTP"|"IND_PAN"|"ISR_TAX_ID"|"ITA_TAX_ID"|"JPN_TAX_ID"|"MEX_RFC"|"NIC_RUC"|"NLD_TIN"|"PAN_RUC"|"PER_RUC"|"PRY_RUC"|"SGP_NRIC"|"SGP_FIN"|"SGP_ASGD"|"SGP_ITR"|"SLV_NIT"|"SWE_TAX_ID"|"URY_RUT"|"VEN_RIF", country_of_citizenship?: string, country_of_birth?: string, country_of_tax_residence: string, funding_source: list, annual_income_min?: float, annual_income_max?: float, liquid_net_worth_min?: float, liquid_net_worth_max?: float, total_net_worth_min?: float, total_net_worth_max?: float, extra?: record}
# --disclosures shape: {employment_status?: "unemployed"|"employed"|"student"|"retired", employer_name?: string, employer_address?: string, employment_position?: string, is_control_person: bool, is_affiliated_exchange_or_finra: bool, is_politically_exposed: bool, immediate_family_exposed: bool, context?: list}
# --agreements item shape: {agreement: "margin_agreement"|"account_agreement"|"customer_agreement"|"crypto_agreement", signed_at: string, ip_address: string, revision?: string}
# --documents item shape: {document_type: "identity_verification"|"address_verification"|"date_of_birth_verification"|"tax_id_verification"|"account_approval_letter"|"cip_result", document_sub_type?: string, content: string, mime_type: string}
# --trusted_contact shape: {given_name: string, family_name: string, email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string, country?: string}
export def "accounts createAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  contact: record # Contact is the model for the account owner contact information. — shape: {email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string}
  identity: record # Identity is the model to provide account owner’s identity information.  (e.g. {given_name: John, family_name: Doe, date_of_birth: 1990-01-01, tax_id: 666-55-4321, tax_id_type: USA_SSN, country_of_citizenship: AUS, country_of_birth: AUS, country_of_tax_residence: USA, funding_source: [employment_income]}) — shape: {given_name: string, family_name: string, date_of_birth: string, tax_id?: string, tax_id_type?: "NOT_SPECIFIED"|"USA_SSN"|"ARG_AG_CUIT"|"AUS_TFN"|"AUS_ABN"|"BOL_NIT"|"BRA_CPF"|"CHL_RUT"|"COL_NIT"|"CRI_NITE"|"DEU_TAX_ID"|"DOM_RNC"|"ECU_RUC"|"FRA_SPI"|"GBR_UTR"|"GBR_NINO"|"GTM_NIT"|"HND_RTN"|"HUN_TIN"|"IDN_KTP"|"IND_PAN"|"ISR_TAX_ID"|"ITA_TAX_ID"|"JPN_TAX_ID"|"MEX_RFC"|"NIC_RUC"|"NLD_TIN"|"PAN_RUC"|"PER_RUC"|"PRY_RUC"|"SGP_NRIC"|"SGP_FIN"|"SGP_ASGD"|"SGP_ITR"|"SLV_NIT"|"SWE_TAX_ID"|"URY_RUT"|"VEN_RIF", country_of_citizenship?: string, country_of_birth?: string, country_of_tax_residence: string, funding_source: list, annual_income_min?: float, annual_income_max?: float, liquid_net_worth_min?: float, liquid_net_worth_max?: float, total_net_worth_min?: float, total_net_worth_max?: float, extra?: record}
  disclosures: record # Disclosures fields denote if the account owner falls under each category defined by FINRA rule. The client has to ask questions for the end user and the values should reflect their answers. If one of the answers is true (yes), the account goes into ACTION_REQUIRED status.  (e.g. {is_control_person: false, is_affiliated_exchange_or_finra: false, is_politically_exposed: false, immediate_family_exposed: false}) — shape: {employment_status?: "unemployed"|"employed"|"student"|"retired", employer_name?: string, employer_address?: string, employment_position?: string, is_control_person: bool, is_affiliated_exchange_or_finra: bool, is_politically_exposed: bool, immediate_family_exposed: bool, context?: list}
  agreements: list # The client has to present the Alpaca Account and Margin Agreements to the end user, and have them read full sentences. — item shape: {agreement: "margin_agreement"|"account_agreement"|"customer_agreement"|"crypto_agreement", signed_at: string, ip_address: string, revision?: string}
  --documents: list # item shape: {document_type: "identity_verification"|"address_verification"|"date_of_birth_verification"|"tax_id_verification"|"account_approval_letter"|"cip_result", document_sub_type?: string, content: string, mime_type: string}
  --trusted-contact: record # This model input is optional. However, the client should make reasonable effort to obtain the trusted contact information. See more details in [FINRA Notice 17-11](https://www.finra.org/sites/default/files/Regulatory-Notice-17-11.pdf)  (e.g. {given_name: Jane, family_name: Doe, email_address: jane.doe@example.com}) — shape: {given_name: string, family_name: string, email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string, country?: string}
]: any -> record<id: string, account_number: string, status: string, crypto_status: string, currency: string, created_at: string, last_equity: string, kyc_results: record<reject: record, accept: record, indeterminate: record, addidional_information: string>, account_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let body = {contact: $contact, identity: $identity, disclosures: $disclosures, agreements: $agreements, documents: $documents, trusted_contact: $trusted_contact} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an account by Id.
#
# GET /v1/accounts/{account_id}
# operationId: getAccount
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, account_number: string, status: string, crypto_status: string, kyc_result: record<reject: record, accept: record, indeterminate: record, addidional_information: string>, currency: string, last_equity: string, created_at: string, contact: record<email_address: string, phone_number: string, street_address: list<string>, city: string, state: string, postal_code: string>, identity: record<given_name: string, family_name: string, date_of_birth: string, tax_id: string, tax_id_type: string, country_of_citizenship: string, country_of_birth: string, country_of_tax_residence: string, funding_source: list<string>, annual_income_min: float, annual_income_max: float, liquid_net_worth_min: float, liquid_net_worth_max: float, total_net_worth_min: float, total_net_worth_max: float, extra: record>, disclosures: record<employment_status: string, employer_name: string, employer_address: string, employment_position: string, is_control_person: bool, is_affiliated_exchange_or_finra: bool, is_politically_exposed: bool, immediate_family_exposed: bool, context: list<record>>, agreements: table<agreement: string, signed_at: string, ip_address: string, revision: string>, documents: table<id: string, document_type: string, document_sub_type: string, mime_type: string, created_at: string>, trusted_contact: record<given_name: string, family_name: string, email_address: string, phone_number: string, street_address: list<string>, city: string, state: string, postal_code: string, country: string>, account_name: string, account_type: string, custodial_account_type: string, minor_identity: record<given_name: string, family_name: string, date_of_birth: string, tax_id: string, tax_id_type: string, country_of_citizenship: string, country_of_birth: string, country_of_tax_residence: string, state: string, email: string>, trading_configurations: record<dtbp_check: string, trade_confirm_email: string, suspend_trade: bool, no_shorting: bool, fractional_trading: bool, max_margin_multiplier: string, pdt_check: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an account
#
# PATCH /v1/accounts/{account_id}
# operationId: patchAccount
# --contact shape: {email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string}
# --identity shape: {given_name: string, family_name: string, date_of_birth: string, tax_id?: string, tax_id_type?: "NOT_SPECIFIED"|"USA_SSN"|"ARG_AG_CUIT"|"AUS_TFN"|"AUS_ABN"|"BOL_NIT"|"BRA_CPF"|"CHL_RUT"|"COL_NIT"|"CRI_NITE"|"DEU_TAX_ID"|"DOM_RNC"|"ECU_RUC"|"FRA_SPI"|"GBR_UTR"|"GBR_NINO"|"GTM_NIT"|"HND_RTN"|"HUN_TIN"|"IDN_KTP"|"IND_PAN"|"ISR_TAX_ID"|"ITA_TAX_ID"|"JPN_TAX_ID"|"MEX_RFC"|"NIC_RUC"|"NLD_TIN"|"PAN_RUC"|"PER_RUC"|"PRY_RUC"|"SGP_NRIC"|"SGP_FIN"|"SGP_ASGD"|"SGP_ITR"|"SLV_NIT"|"SWE_TAX_ID"|"URY_RUT"|"VEN_RIF", country_of_citizenship?: string, country_of_birth?: string, country_of_tax_residence: string, funding_source: list, annual_income_min?: float, annual_income_max?: float, liquid_net_worth_min?: float, liquid_net_worth_max?: float, total_net_worth_min?: float, total_net_worth_max?: float, extra?: record}
# --disclosures shape: {employment_status?: "unemployed"|"employed"|"student"|"retired", employer_name?: string, employer_address?: string, employment_position?: string, is_control_person: bool, is_affiliated_exchange_or_finra: bool, is_politically_exposed: bool, immediate_family_exposed: bool, context?: list}
# --trustedContact shape: {given_name: string, family_name: string, email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string, country?: string}
export def "accounts patch" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact: record # Contact is the model for the account owner contact information. — shape: {email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string}
  --identity: record # Identity is the model to provide account owner’s identity information.  (e.g. {given_name: John, family_name: Doe, date_of_birth: 1990-01-01, tax_id: 666-55-4321, tax_id_type: USA_SSN, country_of_citizenship: AUS, country_of_birth: AUS, country_of_tax_residence: USA, funding_source: [employment_income]}) — shape: {given_name: string, family_name: string, date_of_birth: string, tax_id?: string, tax_id_type?: "NOT_SPECIFIED"|"USA_SSN"|"ARG_AG_CUIT"|"AUS_TFN"|"AUS_ABN"|"BOL_NIT"|"BRA_CPF"|"CHL_RUT"|"COL_NIT"|"CRI_NITE"|"DEU_TAX_ID"|"DOM_RNC"|"ECU_RUC"|"FRA_SPI"|"GBR_UTR"|"GBR_NINO"|"GTM_NIT"|"HND_RTN"|"HUN_TIN"|"IDN_KTP"|"IND_PAN"|"ISR_TAX_ID"|"ITA_TAX_ID"|"JPN_TAX_ID"|"MEX_RFC"|"NIC_RUC"|"NLD_TIN"|"PAN_RUC"|"PER_RUC"|"PRY_RUC"|"SGP_NRIC"|"SGP_FIN"|"SGP_ASGD"|"SGP_ITR"|"SLV_NIT"|"SWE_TAX_ID"|"URY_RUT"|"VEN_RIF", country_of_citizenship?: string, country_of_birth?: string, country_of_tax_residence: string, funding_source: list, annual_income_min?: float, annual_income_max?: float, liquid_net_worth_min?: float, liquid_net_worth_max?: float, total_net_worth_min?: float, total_net_worth_max?: float, extra?: record}
  --disclosures: record # Disclosures fields denote if the account owner falls under each category defined by FINRA rule. The client has to ask questions for the end user and the values should reflect their answers. If one of the answers is true (yes), the account goes into ACTION_REQUIRED status.  (e.g. {is_control_person: false, is_affiliated_exchange_or_finra: false, is_politically_exposed: false, immediate_family_exposed: false}) — shape: {employment_status?: "unemployed"|"employed"|"student"|"retired", employer_name?: string, employer_address?: string, employment_position?: string, is_control_person: bool, is_affiliated_exchange_or_finra: bool, is_politically_exposed: bool, immediate_family_exposed: bool, context?: list}
  --trustedContact: record # This model input is optional. However, the client should make reasonable effort to obtain the trusted contact information. See more details in [FINRA Notice 17-11](https://www.finra.org/sites/default/files/Regulatory-Notice-17-11.pdf)  (e.g. {given_name: Jane, family_name: Doe, email_address: jane.doe@example.com}) — shape: {given_name: string, family_name: string, email_address?: string, phone_number?: string, street_address?: list, city?: string, state?: string, postal_code?: string, country?: string}
]: any -> record<id: string, account_number: string, status: string, crypto_status: string, kyc_result: record<reject: record, accept: record, indeterminate: record, addidional_information: string>, currency: string, last_equity: string, created_at: string, contact: record<email_address: string, phone_number: string, street_address: list<string>, city: string, state: string, postal_code: string>, identity: record<given_name: string, family_name: string, date_of_birth: string, tax_id: string, tax_id_type: string, country_of_citizenship: string, country_of_birth: string, country_of_tax_residence: string, funding_source: list<string>, annual_income_min: float, annual_income_max: float, liquid_net_worth_min: float, liquid_net_worth_max: float, total_net_worth_min: float, total_net_worth_max: float, extra: record>, disclosures: record<employment_status: string, employer_name: string, employer_address: string, employment_position: string, is_control_person: bool, is_affiliated_exchange_or_finra: bool, is_politically_exposed: bool, immediate_family_exposed: bool, context: list<record>>, agreements: table<agreement: string, signed_at: string, ip_address: string, revision: string>, documents: table<id: string, document_type: string, document_sub_type: string, mime_type: string, created_at: string>, trusted_contact: record<given_name: string, family_name: string, email_address: string, phone_number: string, street_address: list<string>, city: string, state: string, postal_code: string, country: string>, account_name: string, account_type: string, custodial_account_type: string, minor_identity: record<given_name: string, family_name: string, date_of_birth: string, tax_id: string, tax_id_type: string, country_of_citizenship: string, country_of_birth: string, country_of_tax_residence: string, state: string, email: string>, trading_configurations: record<dtbp_check: string, trade_confirm_email: string, suspend_trade: bool, no_shorting: bool, fractional_trading: bool, max_margin_multiplier: string, pdt_check: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)")
  let body = {contact: $contact, identity: $identity, disclosures: $disclosures, trustedContact: $trustedContact} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request to close an account
#
# DELETE /v1/accounts/{account_id}
# operationId: deleteAccount
export def "accounts delete" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of account documents.
#
# GET /v1/accounts/{account_id}/documents
# operationId: getDocsForAccount
export def "accounts-documents get" [
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # optional date value to filter the list (inclusive). (format: date)
  --end-date: string # optional date value to filter the list (inclusive). (format: date)
  --type: string@type-completer # See DocumentType model for reference and explanation of values (e.g. identity_verification)
]: nothing -> list<table<document_id: string, document_type: string, document_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a document to an already existing account
#
# POST /v1/accounts/{account_id}/documents/upload
# operationId: uploadDocToAccount
export def "accounts-documents-upload uploadDocToAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  document_type: string@document-type-completer # - identity_verification:   identity verification document  - address_verification:   address verification document  - date_of_birth_verification:   date of birth verification document  - tax_id_verification:   tax ID verification document  - account_approval_letter:   407 approval letter  - cip_result:   initial CIP result  (e.g. identity_verification)
  --document-sub-type: string # e.g. passport
  content: string # format: base64, e.g. /9j/Cg==
  mime_type: string # e.g. image/jpeg
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/documents/upload")
  let body = {document_type: $document_type, document_sub_type: $document_sub_type, content: $content, mime_type: $mime_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a document file that belongs to an account.
#
# GET /v1/accounts/{account_id}/documents/{document_id}/download
# operationId: downloadDocFromAccount
export def "accounts-documents-download downloadDocFromAccount" [
  account_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/documents/($document_id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a document file directly
#
# GET /v1/documents/{document_id}
# operationId: downloadDocumentById
export def "documents downloadDocumentById" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/documents/($document_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve bank relationships for an account
#
# GET /v1/accounts/{account_id}/recipient_banks
# operationId: getRecipientBanks
export def "accounts-recipient-banks get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # e.g. ACTIVE
  --bank-name: string
]: nothing -> table<id: string, created_at: string, updated_at: string, account_id: string, status: string, name: string, bank_code: string, bank_code_type: string, country: string, state_province: string, postal_code: string, city: string, street_address: string, account_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "bank_name" $bank_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/recipient_banks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Bank Relationship for an account
#
# POST /v1/accounts/{account_id}/recipient_banks
# operationId: createRecipientBank
export def "accounts-recipient-banks createRecipientBank" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of recipient bank
  bank_code: string # 9-Digit ABA RTN (Routing Number) or BIC
  bank_code_type: string@bank-code-type-completer # ABA (Domestic) or BIC (International)
  --country: string # Only for international banks
  --state-province: string # Only for international banks
  --postal-code: string # Only for international banks
  --city: string # Only for international banks
  --street-address: string # Only for international banks
  account_number: string
]: any -> record<id: string, created_at: string, updated_at: string, account_id: string, status: string, name: string, bank_code: string, bank_code_type: string, country: string, state_province: string, postal_code: string, city: string, street_address: string, account_number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/recipient_banks")
  let body = {name: $name, bank_code: $bank_code, bank_code_type: $bank_code_type, country: $country, state_province: $state_province, postal_code: $postal_code, city: $city, street_address: $street_address, account_number: $account_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Bank Relationship for an account
#
# DELETE /v1/accounts/{account_id}/recipient_banks/{bank_id}
# operationId: deleteRecipientBank
export def "accounts-recipient-banks delete" [
  account_id: string
  bank_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/recipient_banks/($bank_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of transfers for an account.
#
# GET /v1/accounts/{account_id}/transfers
# operationId: getTransfersForAccount
export def "accounts-transfers get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # INCOMING or OUTGOING
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> table<id: string, relationship_id: string, bank_id: string, account_id: string, type: string, status: string, reason: string, amount: string, direction: string, created_at: string, updated_at: string, expires_at: string, additional_information: string, hold_until: string, instant_amount: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a new transfer
#
# POST /v1/accounts/{account_id}/transfers
# operationId: createTransferForAccount
export def "accounts-transfers createTransferForAccount" [
  account_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transfer_type: string@transfer-type-completer # **NOTE:** The Sandbox environment currently only supports `ach`  - **ach** Transfer via ACH (US Only). - **wire** Transfer via wire (international).  (e.g. ach)
  --relationship-id: string # Required if type = `ach`  The ach_relationship created for the account_id [here](https://alpaca.markets/docs/api-references/broker-api/funding/ach/#creating-an-ach-relationship) (format: uuid)
  --bank-id: string # Required if type = `wire`  The bank_relationship created for the account_id [here](https://alpaca.markets/docs/api-references/broker-api/funding/bank/#creating-a-new-bank-relationship) (format: uuid)
  amount: string # Must be > 0.00 (format: decimal)
  direction: string@direction-completer # - **INCOMING** Funds incoming to user’s account (deposit). - **OUTGOING** Funds outgoing from user’s account (withdrawal).  (e.g. INCOMING)
  timing: string@timing-completer # Only `immediate` is currently supported.  values:  - **immediate**  - **next_day** (e.g. immediate)
  --additional-information: string # Additional details for when type = `wire` (nullable)
]: any -> record<id: string, relationship_id: string, bank_id: string, account_id: string, type: string, status: string, reason: string, amount: string, direction: string, created_at: string, updated_at: string, expires_at: string, additional_information: string, hold_until: string, instant_amount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/transfers")
  let body = {transfer_type: $transfer_type, relationship_id: $relationship_id, bank_id: $bank_id, amount: $amount, direction: $direction, timing: $timing, additional_information: $additional_information} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request to close a transfer
#
# DELETE /v1/accounts/{account_id}/transfers/{transfer_id}
# operationId: deleteTransfer
export def "accounts-transfers delete" [
  account_id: string
  transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/transfers/($transfer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve account activities
#
# GET /v1/accounts/activities
# operationId: getAccountActivities
export def "accounts-activities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # id of a single account to filter by (format: uuid)
  --date: string # Both formats YYYY-MM-DD and YYYY-MM-DDTHH:MM:SSZ supported.
  --until: string # Both formats YYYY-MM-DD and YYYY-MM-DDTHH:MM:SSZ supported.
  --after: string # Both formats YYYY-MM-DD and YYYY-MM-DDTHH:MM:SSZ supported. Cannot be used with date.
  --direction: string@direction-completer-1 # The chronological order of response based on the submission time. asc or desc. Defaults to desc. (e.g. desc)
  --page-size: int # The maximum number of entries to return in the response (default: 100)
  --page-token: string # The Activity ID of the end of your current page of results. 
]: nothing -> table<id: string, account_id: string, activity_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/accounts/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve specific account activities
#
# GET /v1/accounts/activities/{activity_type}
# operationId: getAccountActivitiesByType
export def "accounts-activities get" [
  activity_type: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # id of a single account to filter by (format: uuid)
  --date: string # Both formats YYYY-MM-DD and YYYY-MM-DDTHH:MM:SSZ supported. (format: date-time)
  --until: string # Both formats YYYY-MM-DD and YYYY-MM-DDTHH:MM:SSZ supported. (format: date-time)
  --after: string # Both formats YYYY-MM-DD and YYYY-MM-DDTHH:MM:SSZ supported. (format: date-time)
  --direction: string@direction-completer-1 # The chronological order of response based on the submission time. asc or desc. Defaults to desc. (e.g. desc)
  --page-size: int # The maximum number of entries to return in the response (default: 100)
  --page-token: string # The ID of the end of your current page of results
]: nothing -> table<id: string, account_id: string, activity_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/activities/($activity_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve ACH Relationships for an account
#
# GET /v1/accounts/{account_id}/ach_relationships
# operationId: getAccountACHRelationships
export def "accounts-ach-relationships get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statuses: string # Comma-separated status values
]: nothing -> table<id: string, created_at: string, updated_at: string, account_id: string, status: string, account_owner_name: string, bank_account_type: string, bank_account_number: string, bank_routing_number: string, nickname: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statuses" $statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($account_id)/ach_relationships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an ACH Relationship
#
# POST /v1/accounts/{account_id}/ach_relationships
# operationId: createACHRelationshipForAccount
export def "accounts-ach-relationships createACHRelationshipForAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_owner_name: string
  bank_account_type: string@bank-account-type-completer # Must be CHECKING or SAVINGS
  bank_account_number: string # In sandbox, this still must be a valid format
  bank_routing_number: string # In sandbox, this still must be a valid format
  --nickname: string
  --processor-token: string # If using Plaid, you can specify a Plaid processor token here 
]: any -> record<id: string, created_at: string, updated_at: string, account_id: string, status: string, account_owner_name: string, bank_account_type: string, bank_account_number: string, bank_routing_number: string, nickname: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/ach_relationships")
  let body = {account_owner_name: $account_owner_name, bank_account_type: $bank_account_type, bank_account_number: $bank_account_number, bank_routing_number: $bank_routing_number, nickname: $nickname, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an existing ACH relationship
#
# DELETE /v1/accounts/{account_id}/ach_relationships/{ach_relationship_id}
# operationId: deleteACHRelationshipFromAccount
export def "accounts-ach-relationships delete" [
  account_id: string
  ach_relationship_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/ach_relationships/($ach_relationship_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve trading details for an account.
#
# GET /v1/trading/accounts/{account_id}/account
# operationId: getTradingAccount
export def "trading-accounts-account get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, account_number: string, status: string, currency: string, buying_power: string, regt_buying_power: string, daytrading_buying_power: string, cash: string, cash_withdrawable: string, cash_transferable: string, pending_transfer_out: string, portfolio_value: string, pattern_day_trader: bool, trading_blocked: bool, transfers_blocked: bool, account_blocked: bool, created_at: string, trade_suspended_by_user: bool, multiplier: string, shorting_enabled: bool, equity: string, last_equity: string, long_market_value: string, short_market_value: string, initial_margin: string, maintenance_margin: string, last_maintenance_margin: string, sma: string, daytrade_count: int, previous_close: string, last_long_market_value: string, last_short_market_value: string, last_cash: string, last_initial_margin: string, last_regt_buying_power: string, last_daytrading_buying_power: string, last_buying_power: string, last_daytrade_count: int, clearing_broker: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List open positions for an account
#
# GET /v1/trading/accounts/{account_id}/positions
# operationId: getPositionsForAccount
export def "trading-accounts-positions list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<asset_id: string, symbol: string, exchange: string, asset_class: string, asset_marginable: bool, avg_entry_price: string, qty: string, side: string, market_value: string, cost_basis: string, unrealized_pl: string, unrealized_plpc: string, unrealized_intraday_pl: string, unrealized_intraday_plpc: string, current_price: string, lastday_price: string, change_today: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/positions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Close All Positions for an Account
#
# DELETE /v1/trading/accounts/{account_id}/positions
# operationId: closeAllPositionsForAccount
export def "trading-accounts-positions closeAllPositionsForAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancel-orders: oneof<nothing, bool> # If true is specified, cancel all open orders before liquidating all positions.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cancel_orders" $cancel_orders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Open Position for account by Symbol or AssetId
#
# GET /v1/trading/accounts/{account_id}/positions/{symbol_or_asset_id}
# operationId: getPositionsForAccountBySymbol
export def "trading-accounts-positions get" [
  account_id: string
  symbol_or_asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<asset_id: string, symbol: string, exchange: string, asset_class: string, asset_marginable: bool, avg_entry_price: string, qty: string, side: string, market_value: string, cost_basis: string, unrealized_pl: string, unrealized_plpc: string, unrealized_intraday_pl: string, unrealized_intraday_plpc: string, current_price: string, lastday_price: string, change_today: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/positions/($symbol_or_asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Close a Position for an Account
#
# DELETE /v1/trading/accounts/{account_id}/positions/{symbol_or_asset_id}
# operationId: closePositionForAccountBySymbol
export def "trading-accounts-positions closePositionForAccountBySymbol" [
  account_id: string
  symbol_or_asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qty: string # Optional the number of shares to liquidate. Can accept up to 9 decimal points. Cannot work with percentage
  --percentage: string # percentage of position to liquidate. Must be between 0 and 100. Would only sell fractional if position is originally fractional. Can accept up to 9 decimal points. Cannot work with qty
]: nothing -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_price: string, trail_percent: string, hwm: string, commission: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "qty" $qty "scalar") (serialize-qp "percentage" $percentage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/positions/($symbol_or_asset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a single order for the given order_id.
#
# GET /v1/trading/accounts/{account_id}/orders/{order_id}
# operationId: getOrderForAccount
export def "trading-accounts-orders get" [
  account_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_price: string, trail_percent: string, hwm: string, commission: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/orders/($order_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces a single order with updated parameters
#
# PATCH /v1/trading/accounts/{account_id}/orders/{order_id}
# operationId: replaceOrderForAccount
export def "trading-accounts-orders replaceOrderForAccount" [
  account_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qty: string # You can only patch full shares for now (format: decimal, e.g. 4.2)
  --time-in-force: string@time-in-force-completer # e.g. gtc
  --limit-price: string # Required if original order's `type` field was limit or stop_limit (format: decimal, e.g. 3.14)
  --stop-price: string # Required if original order's `type` field was stop or stop_limit (format: decimal, e.g. 3.14)
  --trail: string # The new value of the trail_price or trail_percent (format: decimal, e.g. 3.14)
  --client-order-id: string # e.g. 61e69015-8549-4bfd-b9c3-01e75843f47d
]: any -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_price: string, trail_percent: string, hwm: string, commission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/orders/($order_id)")
  let body = {qty: $qty, time_in_force: $time_in_force, limit_price: $limit_price, stop_price: $stop_price, trail: $trail, client_order_id: $client_order_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attempts to cancel an open order.
#
# DELETE /v1/trading/accounts/{account_id}/orders/{order_id}
# operationId: deleteOrderForAccount
export def "trading-accounts-orders delete-by-account_id-order_id" [
  account_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/orders/($order_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of orders for the account, filtered by the supplied query parameters.
#
# GET /v1/trading/accounts/{account_id}/orders
# operationId: getAllOrdersForAccount
export def "trading-accounts-orders list" [
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Order status to be queried. open, closed or all. Defaults to open.
  --limit: int # The maximum number of orders in response. Defaults to 50 and max is 500. (e.g. 500)
  --after: string # The response will include only ones submitted after this timestamp (exclusive.) (format: date-time, e.g. 2021-03-16T18:38:01.942282Z)
  --until: string # The response will include only ones submitted until this timestamp (exclusive.) (format: date-time, e.g. 2021-03-16T18:38:01.942282Z)
  --direction: string@direction-completer-1 # The chronological order of response based on the submission time. asc or desc. Defaults to desc. (e.g. desc)
  --nested: oneof<nothing, bool> # If true, the result will roll up multi-leg orders under the legs field of primary order.
  --symbols: string # A comma-separated list of symbols to filter by. (e.g. AAPL,TSLA,MSFT)
]: nothing -> table<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_price: string, trail_percent: string, hwm: string, commission: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "nested" $nested "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an order for an account.
#
# POST /v1/trading/accounts/{account_id}/orders
# operationId: createOrderForAccount
# --take_profit shape: {limit_price?: string}
# --stop_loss shape: {stop_price?: string, limit_price?: string}
export def "trading-accounts-orders createOrderForAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  symbol: string # Symbol or asset ID to identify the asset to trade (e.g. AAPL)
  --qty: string # Number of shares to trade. Can be fractionable for only market and day order types. (format: decimal, e.g. 4.124)
  --notional: string # Dollar amount to trade. Cannot work with qty. Can only work for market order types and time_in_force = day. (format: decimal, e.g. 3)
  side: string@side-completer # Represents what side of the transaction an order was on. (e.g. buy)
  type: string@type-completer-1 # e.g. stop
  time_in_force: string@time-in-force-completer # e.g. gtc
  --limit-price: string # Required if type is limit or stop_limit (format: decimal, e.g. 3.14)
  --stop-price: string # Required if type is stop or stop_limit (format: decimal, e.g. 3.14)
  --trail-price: string # If type is trailing_stop, then one of trail_price or trail_percent is required (format: decimal, e.g. 3.14)
  --trail-percent: string # If type is trailing_stop, then one of trail_price or trail_percent is required (format: decimal, e.g. 5.0)
  --extended-hours: oneof<nothing, bool> # Defaults to false. If true, order will be eligible to execute in premarket/afterhours. Only works with type limit and time_in_force = day. (e.g. false)
  --client-order-id: string # A unique identifier for the order. Automatically generated if not sent. (<= 48 characters) (e.g. eb9e2aaa-f71a-4f51-b5b4-52a6c565dad4)
  --order-class: string@order-class-completer # e.g. bracket
  --take-profit: record # Takes in a string/number value for limit_price — shape: {limit_price?: string}
  --stop-loss: record # Takes in a string/number values for stop_price and limit_price — shape: {stop_price?: string, limit_price?: string}
  --commission: string # The commission you want to collect from the user. (format: decimal, e.g. 1.0)
]: any -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_price: string, trail_percent: string, hwm: string, commission: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/orders")
  let body = {symbol: $symbol, qty: $qty, notional: $notional, side: $side, type: $type, time_in_force: $time_in_force, limit_price: $limit_price, stop_price: $stop_price, trail_price: $trail_price, trail_percent: $trail_percent, extended_hours: $extended_hours, client_order_id: $client_order_id, order_class: $order_class, take_profit: $take_profit, stop_loss: $stop_loss, commission: $commission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attempts to cancel all open orders. A response will be provided for each order that is attempted to be cancelled.
#
# DELETE /v1/trading/accounts/{account_id}/orders
# operationId: deleteAllOrdersForAccount
export def "trading-accounts-orders delete-by-account_id" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/orders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all assets
#
# GET /v1/assets
# operationId: getAssets
export def "assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # Asset status to filter by, will default to `all` (default: all, e.g. all)
  --asset-class: string@asset-class-completer # Asset class to filter by, `us_equity` or `crypto`. Defaults to `us_equity` (default: us_equity, e.g. us_equity)
]: nothing -> table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool, last_close_pct_change: string, last_price: string, last_close: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "asset_class" $asset_class "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an asset by UUID
#
# GET /v1/assets/{symbol_or_asset_id}
# operationId: getAssetBySymbolOrId
export def "assets get" [
  symbol_or_asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool, last_close_pct_change: string, last_price: string, last_close: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/assets/($symbol_or_asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query market calendar
#
# GET /v1/calendar
# operationId: queryMarketCalendar
export def "calendar queryMarketCalendar" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The first date to retrieve data for. (Inclusive) in YYYY-MM-DD format (format: date, e.g. 2022-01-01)
  --end: string # The last date to retrieve data for. (Inclusive) in YYYY-MM-DD format (format: date, e.g. 2022-01-01)
]: nothing -> table<date: string, open: string, close: string, session_open: string, session_close: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query market clock
#
# GET /v1/clock
# operationId: queryMarketClock
export def "clock queryMarketClock" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<timestamp: string, is_open: bool, next_open: string, next_close: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/clock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to account status events (SSE).
#
# GET /v1/events/accounts/status
# operationId: suscribeToAccountStatusSSE
export def "events-accounts-status suscribeToAccountStatusSSE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Format: YYYY-MM-DD (format: date)
  --until: string # Format: YYYY-MM-DD (format: date)
  --since-id: int
  --until-id: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/events/accounts/status" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to journal events (SSE).
#
# GET /v1/events/journals/status
# operationId: subscribeToJournalStatusSSE
export def "events-journals-status subscribeToJournalStatusSSE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Format: YYYY-MM-DD (format: date-time)
  --until: string # Format: YYYY-MM-DD (format: date-time)
  --since-id: int
  --until-id: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/events/journals/status" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to Transfer Events (SSE)
#
# GET /v1/events/transfers/status
# operationId: subscribeToTransferStatusSSE
export def "events-transfers-status subscribeToTransferStatusSSE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Format: YYYY-MM-DD (format: date-time)
  --until: string # Format: YYYY-MM-DD (format: date-time)
  --since-id: int
  --until-id: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/events/transfers/status" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to Trade Events (SSE)
#
# GET /v1/events/trades
# operationId: subscribeToTradeSSE
export def "events-trades subscribeToTradeSSE" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Format: YYYY-MM-DD (format: date-time)
  --until: string # Format: YYYY-MM-DD (format: date-time)
  --since-id: int
  --until-id: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "since_id" $since_id "scalar") (serialize-qp "until_id" $until_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/events/trades" $qp)
  let accept_val = "text/event-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of requested journals.
#
# GET /v1/journals
# Discriminator (response): entry_type = JNLC, JNLS
# operationId: getAllJournals
export def "journals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # By journal creation date. Format: 2020-01-01 (format: date)
  --before: string # By journal creation date. Format: 2020-01-01 (format: date)
  --status: string@status-completer-3 # See the JournalStatus model for more info
  --entry-type: string@entry-type-completer # JNLC or JNLS
  --to-account: string # The account id that received the journal (format: uuid)
  --from-account: string # The account id that initiated the journal (format: uuid)
]: nothing -> table<id: string, entry_type: string, from_account: string, to_account: string, settle_date: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "entry_type" $entry_type "scalar") (serialize-qp "to_account" $to_account "scalar") (serialize-qp "from_account" $from_account "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/journals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Journal.
#
# POST /v1/journals
# operationId: createJournal
export def "journals createJournal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  to_account: string # The account_id you wish to journal to (format: uuid)
  from_account: string # The account_id you wish to journal from (format: uuid)
  entry_type: string@entry-type-completer # This enum represents the various kinds of Journal alpaca supports.  Current values are:  - **JNLC**    Journal Cash between accounts  - **JNLS**    Journal Securities between accounts
  --amount: string # Required if `entry_type` = `JNLC`
  --symbol: string # Required if `entry_type` = `JNLS`
  --qty: string # Required if `entry_type` = `JNLS`
  --description: string # Max 1024 characters. Can include fixtures for amounts that are above the transaction limit
  --transmitter-name: string # Max 255 characters. See more details about [Travel Rule](https://alpaca.markets/docs/broker/integration/funding/#travel-rule) in our main documentation.
  --transmitter-account-number: string # Max 255 characters. See more details about [Travel Rule](https://alpaca.markets/docs/broker/integration/funding/#travel-rule) in our main documentation.
  --transmitter-address: string # Max 255 characters. See more details about [Travel Rule](https://alpaca.markets/docs/broker/integration/funding/#travel-rule) in our main documentation.
  --transmitter-financial-institution: string # Max 255 characters. See more details about [Travel Rule](https://alpaca.markets/docs/broker/integration/funding/#travel-rule) in our main documentation.
  --transmitter-timestamp: string # RFC 3339 format. See more details about [Travel Rule](https://alpaca.markets/docs/broker/integration/funding/#travel-rule) in our main documentation. (format: date-time)
]: any -> record<id: string, entry_type: string, from_account: string, to_account: string, settle_date: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/journals")
  let body = {to_account: $to_account, from_account: $from_account, entry_type: $entry_type, amount: $amount, symbol: $symbol, qty: $qty, description: $description, transmitter_name: $transmitter_name, transmitter_account_number: $transmitter_account_number, transmitter_address: $transmitter_address, transmitter_financial_institution: $transmitter_financial_institution, transmitter_timestamp: $transmitter_timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a pending journal.
#
# DELETE /v1/journals/{journal_id}
# operationId: deleteJournalById
export def "journals delete" [
  journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/journals/($journal_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Batch Journal Transaction (One-to-Many)
#
# POST /v1/journals/batch
# operationId: createBatchJournal
# --entries item shape: {to_account: string, amount: string}
export def "journals-batch createBatchJournal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entry_type: string@entry-type-completer-1 # Only supports `JNLC` for now
  from_account: string # The account id that is the originator of the funds being moved. Most likely is your Sweep Firm Account (format: uuid)
  --description: string # Journal description, gets returned in the response
  entries: list # An array of objects describing to what accounts you want to move funds into and how much to move into for each account — item shape: {to_account: string, amount: string}
]: any -> table<error_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/journals/batch")
  let body = {entry_type: $entry_type, from_account: $from_account, description: $description, entries: $entries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an OAuth client
#
# GET /v1/oauth/clients/{client_id}
# operationId: getOAuthClient
export def "oauth-clients get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string@response-type-completer # code or token (e.g. token)
  --redirect-uri: string # Redirect URI of the OAuth flow (e.g. https://example.com/authorize)
  --scope: string # Requested scopes by the OAuth flow (e.g. general)
]: nothing -> record<client_id: string, name: string, description: string, url: string, terms_of_use: string, privacy_policy: string, status: string, redirect_uri: list<string>, live_trading_approved: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/oauth/clients/($client_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Issue an OAuth token.
#
# POST /v1/oauth/token
# operationId: issueOAuthToken
export def "oauth-token issueOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # OAuth client ID
  client_secret: string # OAuth client secret
  redirect_uri: string # redirect URI for the OAuth flow
  scope: string # scopes requested by the OAuth flow
  account_id: string # end-user account ID (format: uuid)
]: any -> record<access_token: string, token_type: string, scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/token")
  let body = {client_id: $client_id, client_secret: $client_secret, redirect_uri: $redirect_uri, scope: $scope, account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize an OAuth Token
#
# POST /v1/oauth/authorize
# operationId: authorizeOAuthToken
export def "oauth-authorize authorizeOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # OAuth client ID
  client_secret: string # OAuth client secret
  redirect_uri: string # redirect URI for the OAuth flow
  scope: string # scopes requested by the OAuth flow
  account_id: string # end-user account ID (format: uuid)
]: any -> record<code: string, client_id: string, redirect_uri: string, scope: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/authorize")
  let body = {client_id: $client_id, client_secret: $client_secret, redirect_uri: $redirect_uri, scope: $scope, account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all watchlists
#
# GET /v1/trading/accounts/{account_id}/watchlists
# operationId: getAllWatchlistsForAccount
export def "trading-accounts-watchlists get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/watchlists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new watchlist
#
# POST /v1/trading/accounts/{account_id}/watchlists
# operationId: createWatchlistForAccount
export def "trading-accounts-watchlists createWatchlistForAccount" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The watchlist name
  symbols: list # The new list of symbol names to watch
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool, last_close_pct_change: string, last_price: string, last_close: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/trading/accounts/($account_id)/watchlists")
  let body = {name: $name, symbols: $symbols} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manage watchlists
#
# GET /v1/accounts/{account_id}/watchlists/{watchlist_id}
# operationId: getWatchlistForAccountById
export def "accounts-watchlists get" [
  account_id: string
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool, last_close_pct_change: string, last_price: string, last_close: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/watchlists/($watchlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing watchlist
#
# PUT /v1/accounts/{account_id}/watchlists/{watchlist_id}
# operationId: replaceWatchlistForAccountById
export def "accounts-watchlists replaceWatchlistForAccountById" [
  account_id: string
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The watchlist name
  symbols: list # The new list of symbol names to watch
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool, last_close_pct_change: string, last_price: string, last_close: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/watchlists/($watchlist_id)")
  let body = {name: $name, symbols: $symbols} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a watchlist
#
# DELETE /v1/accounts/{account_id}/watchlists/{watchlist_id}
# operationId: deleteWatchlistFromAccountById
export def "accounts-watchlists delete" [
  account_id: string
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($account_id)/watchlists/($watchlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieving Announcements
#
# GET /v1/corporate_actions/announcements
# operationId: getCorporateAnnouncements
export def "corporate-actions-announcements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ca-types: string # A comma-delimited list of CorporateActionType values
  --since: string # The start (inclusive) of the date range when searching corporate action announcements. This should follow the YYYY-MM-DD format. The date range is limited to 90 days. (format: date)
  --until: string # The end (inclusive) of the date range when searching corporate action announcements. This should follow the YYYY-MM-DD format. The date range is limited to 90 days. (format: date)
  --symbol: string # The symbol of the company initiating the announcement.
  --cusip: string # The CUSIP of the company initiating the announcement.
  --date-type: string@date-type-completer # An emum of possible ways to use the `since` and `until` parameters to search by.  the types are:  - **declaration_date**: The date of the preliminary announcement details or the date that any subsequent term updates took place. - **ex_date**: The date on which any security purchasing activity will not result in a corporate action entitlement. Any selling activity that takes place on or after this date will result in a corporate action entitlement. - **record_date**: The date the company checks its records to determine who is shareholder in order to allocate entitlements. - **payable_date**: The date that the stock and cash positions will update according to the account positions as of the record date.
]: nothing -> table<id: string, corporate_action_id: string, ca_type: string, ca_sub_type: string, initiating_symbol: string, initiating_original_cusip: string, target_symbol: string, target_original_cusip: string, declaration_date: string, ex_date: string, record_date: string, payable_date: string, cash: string, old_rate: string, new_rate: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ca_types" $ca_types "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "cusip" $cusip "scalar") (serialize-qp "date_type" $date_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/corporate_actions/announcements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
