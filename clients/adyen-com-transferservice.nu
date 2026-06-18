# Auto-generated client for Transfers API v3
# Source: https://api.apis.guru/v2/specs/adyen.com/TransferService/3/openapi.json
# Auth: --token flag or $env.TRANSFERS_API_TOKEN

const BASE_URL = "https://balanceplatform-api-test.adyen.com/btl/v3"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRANSFERS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://balanceplatform-api-test.adyen.com/btl/v3"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def category-completer [] { ["bank" "internal" "issuedCard" "platformPayment"] }
def priority-completer [] { ["crossBorder" "directDebit" "fast" "instant" "internal" "regular" "wire"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "transactions list" } } | get name | first)
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

# Get all transactions
#
# GET /transactions
# operationId: get-transactions
export def "transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-platform: string # Unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id).
  --payment-instrument-id: string # Unique identifier of the [payment instrument](https://docs.adyen.com/api-explorer/balanceplatform/latest/get/paymentInstruments/_id_).
  --account-holder-id: string # Unique identifier of the [account holder](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/accountHolders/{id}__queryParam_id).
  --balance-account-id: string # Unique identifier of the [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balanceAccounts/{id}__queryParam_id).
  --cursor: string # The `cursor` returned in the links of the previous response.
  --created-since: string # Only include transactions that have been created on or after this point in time. The value must be in ISO 8601 format. For example, **2021-05-30T15:07:40Z**. (format: date-time)
  --created-until: string # Only include transactions that have been created on or before this point in time. The value must be in ISO 8601 format. For example, **2021-05-30T15:07:40Z**. (format: date-time)
  --limit: int # The number of items returned per page, maximum of 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> record<_links: record<next: record<href: string>, prev: record<href: string>>, data: table<accountHolderId: string, amount: record, balanceAccountId: string, balancePlatform: string, bookingDate: string, category: string, counterparty: record, createdAt: string, description: string, id: string, instructedAmount: record, paymentInstrumentId: string, reference: string, referenceForBeneficiary: string, status: string, transferId: string, type: string, valueDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "balancePlatform" $balance_platform "scalar") (serialize-qp "paymentInstrumentId" $payment_instrument_id "scalar") (serialize-qp "accountHolderId" $account_holder_id "scalar") (serialize-qp "balanceAccountId" $balance_account_id "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "createdSince" $created_since "scalar") (serialize-qp "createdUntil" $created_until "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a transaction
#
# GET /transactions/{id}
# operationId: get-transactions-id
export def "transactions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountHolderId: string, amount: record<currency: string, value: int>, balanceAccountId: string, balancePlatform: string, bookingDate: string, category: string, counterparty: record<balanceAccountId: string, bankAccount: record<accountHolder: record, accountIdentification: any>, merchant: record<mcc: string, merchantId: string, nameLocation: record, postalCode: string>, transferInstrumentId: string>, createdAt: string, description: string, id: string, instructedAmount: record<currency: string, value: int>, paymentInstrumentId: string, reference: string, referenceForBeneficiary: string, status: string, transferId: string, type: string, valueDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Transfer funds
#
# POST /transfers
# operationId: post-transfers
# --amount shape: {currency: string, value: int}
# --counterparty shape: {balanceAccountId?: string, bankAccount?: record, transferInstrumentId?: string}
# --ultimateParty shape: {address?: record, dateOfBirth?: string, firstName?: string, fullName: string, lastName?: string, reference?: string, type?: "individual"|"organization"|"unknown"}
export def "transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # shape: {currency: string, value: int}
  --balance-account-id: string # The unique identifier of the source [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/balanceAccounts__resParam_id).
  category: string@category-completer # The type of transfer. Possible values: - **bank**: Transfer to a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id) or a bank account. - **internal**: Transfer to another [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/balanceAccounts__resParam_id) within your platform. - **issuedCard**: Transfer initiated by a Adyen-issued card. - **platformPayment**: Fund movements related to payments that are acquired for your users.
  counterparty: record # shape: {balanceAccountId?: string, bankAccount?: record, transferInstrumentId?: string}
  --description: string # Your description for the transfer. It is used by most banks as the transfer description. We recommend sending a maximum of 140 characters, otherwise the description may be truncated. Supported characters: **[a-z] [A-Z] [0-9] / - ?** **: ( ) . , ' + Space** Supported characters for **regular** and **fast** transfers to a US counterparty: **[a-z] [A-Z] [0-9] & $ % # @** **~ = + - _ ' " ! ?**
  --id: string # The ID of the resource.
  --payment-instrument-id: string # The unique identifier of the source [payment instrument](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/paymentInstruments__resParam_id).
  --priority: string@priority-completer # The priority for the bank transfer. This sets the speed at which the transfer is sent and the fees that you have to pay. Required for transfers with `category` **bank**. Possible values: * **regular**: For normal, low-value transactions. * **fast**: Faster way to transfer funds but has higher fees. Recommended for high-priority, low-value transactions. * **wire**: Fastest way to transfer funds but has the highest fees. Recommended for high-priority, high-value transactions. * **instant**: Instant way to transfer funds in [SEPA countries](https://www.ecb.europa.eu/paym/integration/retail/sepa/html/index.en.html). * **crossBorder**: High-value transfer to a recipient in a different country. * **internal**: Transfer to an Adyen-issued business bank account (by bank account number/IBAN).
  --reference: string # Your reference for the transfer, used internally within your platform. If you don't provide this in the request, Adyen generates a unique reference.
  --reference-for-beneficiary: string # A reference that is sent to the recipient. This reference is also sent in all notification webhooks related to the transfer, so you can use it to track statuses for both the source and recipient of funds. Supported characters: **a-z**, **A-Z**, **0-9**. The maximum length depends on the `category`. - **internal**: 80 characters - **bank**: 35 characters when transferring to an IBAN, 15 characters for others.
  --ultimate-party: record # shape: {address?: record, dateOfBirth?: string, firstName?: string, fullName: string, lastName?: string, reference?: string, type?: "individual"|"organization"|"unknown"}
]: any -> record<accountHolder: record<description: string, id: string, reference: string>, amount: record<currency: string, value: int>, balanceAccount: record<description: string, id: string, reference: string>, balanceAccountId: string, category: string, counterparty: record<balanceAccountId: string, bankAccount: record<accountHolder: record, accountIdentification: any>, merchant: record<mcc: string, merchantId: string, nameLocation: record, postalCode: string>, transferInstrumentId: string>, description: string, direction: string, id: string, paymentInstrument: record<description: string, id: string, reference: string, tokenType: string>, paymentInstrumentId: string, priority: string, reason: string, reference: string, referenceForBeneficiary: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfers")
  let req_body = {"amount": $amount, "balanceAccountId": $balance_account_id, "category": $category, "counterparty": $counterparty, "description": $description, "id": $id, "paymentInstrumentId": $payment_instrument_id, "priority": $priority, "reference": $reference, "referenceForBeneficiary": $reference_for_beneficiary, "ultimateParty": $ultimate_party} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
