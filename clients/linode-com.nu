# Auto-generated client for Linode API v4.145.0
# Source: https://api.apis.guru/v2/specs/linode.com/4.145.0/openapi.json
# Auth: --token flag or $env.LINODE_API_TOKEN

const BASE_URL = "https://api.linode.com/v4"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LINODE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.linode.com/v4" "https://api.linode.com/v4beta"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["credit_card"] }
def target-completer [] { ["primary" "secondary"] }
def status-completer [] { ["active" "disabled"] }
def type-completer-1 [] { ["master" "slave"] }
def tag-completer [] { ["iodef" "issue" "issuewild"] }
def type-completer-2 [] { ["A" "AAAA" "CAA" "CNAME" "MX" "NS" "PTR" "SRV" "TXT"] }
def run-level-completer [] { ["binbash" "default" "single"] }
def virt-mode-completer [] { ["fullvirt" "paravirt"] }
def filesystem-completer [] { ["ext3" "ext4" "initrd" "raw" "swap"] }
def type-completer-3 [] { ["ipv4"] }
def longview-subscription-completer [] { ["longview-10" "longview-100" "longview-3" "longview-40"] }
def service-type-completer [] { ["tcp" "url"] }
def status-completer-1 [] { ["disabled" "enabled"] }
def prefix-length-completer [] { ["56" "64"] }
def algorithm-completer [] { ["leastconn" "roundrobin" "source"] }
def check-completer [] { ["connection" "http" "http_body" "none"] }
def cipher-suite-completer [] { ["legacy" "recommended"] }
def protocol-completer [] { ["http" "https" "tcp"] }
def proxy-protocol-completer [] { ["none" "v1" "v2"] }
def stickiness-completer [] { ["http_cookie" "none" "table"] }
def mode-completer [] { ["accept" "backup" "drain" "reject"] }
def acl-completer [] { ["authenticated-read" "private" "public-read" "public-read-write"] }
def acl-completer-1 [] { ["authenticated-read" "custom" "private" "public-read" "public-read-write"] }
def lish-auth-method-completer [] { ["disabled" "keys_only" "password_keys"] }

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

# Account View
#
# GET /account
# operationId: getAccount
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active_promotions: table<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>, active_since: string, address_1: string, address_2: string, balance: float, balance_uninvoiced: float, billing_source: string, capabilities: list<string>, city: string, company: string, country: string, credit_card: record<expiry: string, last_four: string>, email: string, euuid: string, first_name: string, last_name: string, phone: string, state: string, tax_id: string, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Account Update
#
# PUT /account
# operationId: updateAccount
# --active_promotions item shape: {credit_monthly_cap?: string, credit_remaining?: string, description?: string, expire_dt?: string, image_url?: string, service_type?: "all"|"backup"|"blockstorage"|"db_mysql"|"ip_v4"|"linode"|"linode_disk"|"linode_memory"|"longview"|"managed"|"nodebalancer"|"objectstorage"|"transfer_tx", summary?: string, this_month_credit_remaining?: string}
# --credit_card shape: {expiry?: string, last_four?: string}
export def "account update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-1: string # First line of this Account's billing address. (e.g. 123 Main Street)
  --address-2: string # Second line of this Account's billing address. (e.g. Suite A)
  --city: string # The city for this Account's billing address. (e.g. Philadelphia)
  --company: string # The company name associated with this Account. (e.g. Linode LLC)
  --country: string # The two-letter ISO 3166 country code of this Account's billing address.  (e.g. US)
  --email: string # The email address of the person associated with this Account. (e.g. john.smith@linode.com)
  --first-name: string # The first name of the person associated with this Account. (e.g. John)
  --last-name: string # The last name of the person associated with this Account. (e.g. Smith)
  --phone: string # The phone number associated with this Account. (e.g. 215-555-1212)
  --state: string # If billing address is in the United States (US) or Canada (CA), only the two-letter ISO 3166 State or Province code are accepted. If entering a US military address, state abbreviations (AA, AE, AP) should be entered. If the address is outside the US or CA, this is the Province associated with the Account's billing address.  (e.g. PA)
  --tax-id: string # The tax identification number associated with this Account, for tax calculations in some countries. If you do not live in a country that collects tax, this should be an empty string (`""`).  (e.g. ATU99999999)
  --zip: string # The zip code of this Account's billing address. The following restrictions apply:  - May only consist of letters, numbers, spaces, and hyphens. - Must not contain more than 9 letter or number characters.  (e.g. 19102-1234)
]: any -> record<active_promotions: table<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string>, active_since: string, address_1: string, address_2: string, balance: float, balance_uninvoiced: float, billing_source: string, capabilities: list<string>, city: string, company: string, country: string, credit_card: record<expiry: string, last_four: string>, email: string, euuid: string, first_name: string, last_name: string, phone: string, state: string, tax_id: string, zip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let body = {"address_1": $address_1, "address_2": $address_2, "city": $city, "company": $company, "country": $country, "email": $email, "first_name": $first_name, "last_name": $last_name, "phone": $phone, "state": $state, "tax_id": $tax_id, "zip": $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Account Cancel
#
# POST /account/cancel
# operationId: cancelAccount
export def "account-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string # Any reason for cancelling the account, and any other comments you might have about your Linode service.  (e.g. I'm consolidating multiple accounts into one.)
]: any -> record<survey_link: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/cancel")
  let body = {"comments": $comments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Credit Card Add/Edit
#
# POST /account/credit-card
# DEPRECATED
# operationId: createCreditCard
@deprecated
export def "account-credit-card create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # Your credit card number. No spaces or dashes allowed. (format: digits, e.g. 4111111111111111)
  cvv: string # CVV (Card Verification Value) of the credit card, typically found on the back of the card.  (format: digits, e.g. 123)
  expiry_month: int # A value from 1-12 representing the expiration month of your credit card.    * 1 = January   * 2 = February   * 3 = March   * Etc.  (e.g. 12)
  expiry_year: int # A four-digit integer representing the expiration year of your credit card.  The combination of `expiry_month` and `expiry_year` must result in a month/year combination of the current month or in the future. An expiration date set in the past is invalid.  (e.g. 2020)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/credit-card")
  let body = {"card_number": $card_number, "cvv": $cvv, "expiry_month": $expiry_month, "expiry_year": $expiry_year} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Entity Transfers List
#
# GET /account/entity-transfers
# DEPRECATED
# operationId: getEntityTransfers
@deprecated
export def "account-entity-transfers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<created: string, entities: record, expiry: string, is_sender: bool, status: string, token: string, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/entity-transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Entity Transfer Create
#
# POST /account/entity-transfers
# DEPRECATED
# operationId: createEntityTransfer
@deprecated
export def "account-entity-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entities: any
]: any -> record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/entity-transfers")
  let body = {"entities": $entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Entity Transfer Cancel
#
# DELETE /account/entity-transfers/{token}
# DEPRECATED
# operationId: deleteEntityTransfer
@deprecated
export def "account-entity-transfers delete" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/account/entity-transfers/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Entity Transfer View
#
# GET /account/entity-transfers/{token}
# DEPRECATED
# operationId: getEntityTransfer
@deprecated
export def "account-entity-transfers get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/account/entity-transfers/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Entity Transfer Accept
#
# POST /account/entity-transfers/{token}/accept
# DEPRECATED
# operationId: acceptEntityTransfer
@deprecated
export def "account-entity-transfers-accept acceptEntityTransfer" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/account/entity-transfers/{token_arg}/accept"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Events List
#
# GET /account/events
# operationId: getEvents
export def "account-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<action: string, created: string, duration: float, entity: record, id: int, message: string, percent_complete: int, rate: string, read: bool, secondary_entity: record, seen: bool, status: string, time_remaining: string, username: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Event View
#
# GET /account/events/{eventId}
# operationId: getEvent
export def "account-events get" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action: string, created: string, duration: float, entity: record<id: int, label: string, type: string, url: string>, id: int, message: string, percent_complete: int, rate: string, read: bool, secondary_entity: record<id: string, label: string, type: string, url: string>, seen: bool, status: string, time_remaining: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_id: $event_id} | format pattern "/account/events/{event_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Event Mark as Read
#
# POST /account/events/{eventId}/read
# operationId: eventRead
export def "account-events-read eventRead" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_id: $event_id} | format pattern "/account/events/{event_id}/read"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Event Mark as Seen
#
# POST /account/events/{eventId}/seen
# operationId: eventSeen
export def "account-events-seen eventSeen" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_id: $event_id} | format pattern "/account/events/{event_id}/seen"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoices List
#
# GET /account/invoices
# operationId: getInvoices
export def "account-invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<date: string, id: int, label: string, subtotal: float, tax: float, tax_summary: list, total: float>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoice View
#
# GET /account/invoices/{invoiceId}
# operationId: getInvoice
export def "account-invoices get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date: string, id: int, label: string, subtotal: float, tax: float, tax_summary: table<name: string, tax: float>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: $invoice_id} | format pattern "/account/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoice Items List
#
# GET /account/invoices/{invoiceId}/items
# operationId: getInvoiceItems
export def "account-invoices-items get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<amount: float, from: string, label: string, quantity: int, tax: float, to: string, total: float, type: string, unit_price: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: $invoice_id} | format pattern "/account/invoices/{invoice_id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User Logins List All
#
# GET /account/logins
# operationId: getAccountLogins
export def "account-logins list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<datetime: string, id: int, ip: string, restricted: bool, username: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/logins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login View
#
# GET /account/logins/{loginId}
# operationId: getAccountLogin
export def "account-logins get" [
  login_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<datetime: string, id: int, ip: string, restricted: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({login_id: $login_id} | format pattern "/account/logins/{login_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Maintenance List
#
# GET /account/maintenance
# operationId: getMaintenance
export def "account-maintenance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<entity: record, reason: string, status: string, type: string, when: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/account/maintenance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Notifications List
#
# GET /account/notifications
# operationId: getNotifications
export def "account-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<body: string, entity: record, label: string, message: string, severity: string, type: string, until: string, when: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OAuth Clients List
#
# GET /account/oauth-clients
# operationId: getClients
export def "account-oauth-clients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/oauth-clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OAuth Client Create
#
# POST /account/oauth-clients
# operationId: createClient
export def "account-oauth-clients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The name of this application.  This will be presented to users when they are asked to grant it access to their Account.  (e.g. Test_Client_1)
  --public: oneof<nothing, bool> # If this is a public or private OAuth Client.  Public clients have a slightly different authentication workflow than private clients.  See the <a target="_top" href="https://oauth.net/2/">OAuth spec</a> for more details.  (default: false, e.g. false)
  redirect_uri: string # The location a successful log in from <a target="_top" href="https://login.linode.com">https://login.linode.com</a> should be redirected to for this client.  The receiver of this redirect should be ready to accept an OAuth exchange code and finish the OAuth exchange.  (format: url, e.g. https://example.org/oauth/callback)
]: any -> record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/oauth-clients")
  let body = {"label": $label, "public": $public, "redirect_uri": $redirect_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OAuth Client Delete
#
# DELETE /account/oauth-clients/{clientId}
# operationId: deleteClient
export def "account-oauth-clients delete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/account/oauth-clients/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OAuth Client View
#
# GET /account/oauth-clients/{clientId}
# operationId: getClient
export def "account-oauth-clients get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/account/oauth-clients/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OAuth Client Update
#
# PUT /account/oauth-clients/{clientId}
# operationId: updateClient
export def "account-oauth-clients update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The name of this application.  This will be presented to users when they are asked to grant it access to their Account.  (e.g. Test_Client_1)
  --public: oneof<nothing, bool> # If this is a public or private OAuth Client.  Public clients have a slightly different authentication workflow than private clients.  See the <a target="_top" href="https://oauth.net/2/">OAuth spec</a> for more details.  (default: false, e.g. false)
  --redirect-uri: string # The location a successful log in from <a target="_top" href="https://login.linode.com">https://login.linode.com</a> should be redirected to for this client.  The receiver of this redirect should be ready to accept an OAuth exchange code and finish the OAuth exchange.  (format: url, e.g. https://example.org/oauth/callback)
]: any -> record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/account/oauth-clients/{client_id}"))
  let body = {"label": $label, "public": $public, "redirect_uri": $redirect_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OAuth Client Secret Reset
#
# POST /account/oauth-clients/{clientId}/reset-secret
# operationId: resetClientSecret
export def "account-oauth-clients-reset-secret reset" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, label: string, public: bool, redirect_uri: string, secret: string, status: string, thumbnail_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/account/oauth-clients/{client_id}/reset-secret"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OAuth Client Thumbnail View
#
# GET /account/oauth-clients/{clientId}/thumbnail
# operationId: getClientThumbnail
export def "account-oauth-clients-thumbnail get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/account/oauth-clients/{client_id}/thumbnail"))
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OAuth Client Thumbnail Update
#
# PUT /account/oauth-clients/{clientId}/thumbnail
# operationId: setClientThumbnail
export def "account-oauth-clients-thumbnail setClientThumbnail" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/account/oauth-clients/{client_id}/thumbnail"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "image/png" $body
}

# Payment Methods List
#
# GET /account/payment-methods
# operationId: getPaymentMethods
export def "account-payment-methods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, data: any, id: int, is_default: bool, type: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/payment-methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Payment Method Add
#
# POST /account/payment-methods
# operationId: createPaymentMethod
# --data shape: {card_number: string, cvv: string, expiry_month: int, expiry_year: int}
export def "account-payment-methods create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # An object representing the credit card information you have on file with Linode to make Payments against your Account. — shape: {card_number: string, cvv: string, expiry_month: int, expiry_year: int}
  is_default: any
  type: string@type-completer # The type of Payment Method.  Alternative Payment Methods including Google Pay and PayPal can be added using the Cloud Manager. See the [Manage Payment Methods](/docs/products/platform/billing/guides/payment-methods/) guide for details and instructions.  (e.g. credit_card)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/account/payment-methods")
  let body = {"data": $data, "is_default": $is_default, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Payment Method Delete
#
# DELETE /account/payment-methods/{paymentMethodId}
# operationId: deletePaymentMethod
export def "account-payment-methods delete" [
  payment_method_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/account/payment-methods/{payment_method_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Payment Method View
#
# GET /account/payment-methods/{paymentMethodId}
# operationId: getPaymentMethod
export def "account-payment-methods get" [
  payment_method_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, data: any, id: int, is_default: bool, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/account/payment-methods/{payment_method_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Payment Method Make Default
#
# POST /account/payment-methods/{paymentMethodId}/make-default
# operationId: makePaymentMethodDefault
export def "account-payment-methods-make-default makePaymentMethodDefault" [
  payment_method_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/account/payment-methods/{payment_method_id}/make-default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Payments List
#
# GET /account/payments
# operationId: getPayments
export def "account-payments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<date: string, id: int, usd: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Payment Make
#
# POST /account/payments
# operationId: createPayment
export def "account-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cvv: string # CVV (Card Verification Value) of the credit card to be used for the Payment. Required if paying by credit card.  (e.g. 123)
  --payment-method-id: int # The ID of the Payment Method to apply to the Payment.  (e.g. 123)
  usd: string # The amount in US Dollars of the Payment.  * Can begin with or without `$`. * Commas (`,`) are not accepted. * Must end with a decimal expression, such as `.00` or `.99`. * Minimum: `$5.00` or the Account balance, whichever is lower. * Maximum: `$2000.00` or the Account balance up to `$50000.00`, whichever is greater.  (e.g. $120.50)
]: any -> record<date: string, id: int, usd: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/payments")
  let body = {"cvv": $cvv, "payment_method_id": $payment_method_id, "usd": $usd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PayPal Payment Stage
#
# POST /account/payments/paypal
# DEPRECATED
# operationId: createPayPalPayment
@deprecated
export def "account-payments-paypal create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cancel_url: string # The URL to have PayPal redirect to when Payment is cancelled. (e.g. https://example.org)
  redirect_url: string # The URL to have PayPal redirect to when Payment is approved. (e.g. https://example.org)
  usd: string # The payment amount in USD. Minimum accepted value of $5 USD. Maximum accepted value of $500 USD or credit card payment limit; whichever value is highest. PayPal's maximum transaction limit is $10,000 USD. (e.g. 120.50)
]: any -> record<checkout_token: string, payment_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/payments/paypal")
  let body = {"cancel_url": $cancel_url, "redirect_url": $redirect_url, "usd": $usd} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Staged/Approved PayPal Payment Execute
#
# POST /account/payments/paypal/execute
# DEPRECATED
# operationId: executePayPalPayment
@deprecated
export def "account-payments-paypal-execute exec-ute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payer_id: string # The PayerID returned by PayPal during the transaction authorization process.  (e.g. ABCDEFGHIJKLM)
  payment_id: string # The PaymentID returned from [POST /account/payments/paypal](/docs/api/account/#paypal-payment-stage) that has been approved with PayPal.  (e.g. PAY-1234567890ABCDEFGHIJKLMN)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/payments/paypal/execute")
  let body = {"payer_id": $payer_id, "payment_id": $payment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Payment View
#
# GET /account/payments/{paymentId}
# operationId: getPayment
export def "account-payments get" [
  payment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date: string, id: int, usd: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: $payment_id} | format pattern "/account/payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Promo Credit Add
#
# POST /account/promo-codes
# operationId: createPromoCredit
export def "account-promo-codes create-promo-credit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  promo_code: string # The Promo Code.
]: any -> record<credit_monthly_cap: string, credit_remaining: string, description: string, expire_dt: string, image_url: string, service_type: string, summary: string, this_month_credit_remaining: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/promo-codes")
  let body = {"promo_code": $promo_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Service Transfers List
#
# GET /account/service-transfers
# operationId: getServiceTransfers
export def "account-service-transfers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, entities: record, expiry: string, is_sender: bool, status: string, token: string, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/service-transfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service Transfer Create
#
# POST /account/service-transfers
# operationId: createServiceTransfer
export def "account-service-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  entities: any
]: any -> record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/service-transfers")
  let body = {"entities": $entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Service Transfer Cancel
#
# DELETE /account/service-transfers/{token}
# operationId: deleteServiceTransfer
export def "account-service-transfers delete" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/account/service-transfers/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service Transfer View
#
# GET /account/service-transfers/{token}
# operationId: getServiceTransfer
export def "account-service-transfers get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, entities: record<linodes: list<int>>, expiry: string, is_sender: bool, status: string, token: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/account/service-transfers/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service Transfer Accept
#
# POST /account/service-transfers/{token}/accept
# operationId: acceptServiceTransfer
export def "account-service-transfers-accept acceptServiceTransfer" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/account/service-transfers/{token_arg}/accept"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Account Settings View
#
# GET /account/settings
# operationId: getAccountSettings
export def "account-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<backups_enabled: bool, longview_subscription: string, managed: bool, network_helper: bool, object_storage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Account Settings Update
#
# PUT /account/settings
# operationId: updateAccountSettings
export def "account-settings update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --backups-enabled: oneof<nothing, bool> # Account-wide backups default.  If `true`, all Linodes created will automatically be enrolled in the Backups service.  If `false`, Linodes will not be enrolled by default, but may still be enrolled on creation or later.  (e.g. true)
  --network-helper: oneof<nothing, bool> # Enables network helper across all users by default for new Linodes and Linode Configs.  (e.g. false)
]: any -> record<backups_enabled: bool, longview_subscription: string, managed: bool, network_helper: bool, object_storage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/settings")
  let body = {"backups_enabled": $backups_enabled, "network_helper": $network_helper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Managed Enable
#
# POST /account/settings/managed-enable
# operationId: enableAccountManaged
export def "account-settings-managed-enable enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/settings/managed-enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Network Utilization View
#
# GET /account/transfer
# operationId: getTransfer
export def "account-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billable: int, quota: int, used: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/transfer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Users List
#
# GET /account/users
# operationId: getUsers
export def "account-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<email: string, restricted: bool, ssh_keys: list, tfa_enabled: bool, username: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User Create
#
# POST /account/users
# operationId: createUser
export def "account-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email address for the User. Linode sends emails to this address for account management communications. May be used for other communications as configured.  (format: email, e.g. example_user@linode.com)
  --restricted: oneof<nothing, bool> # If true, the User must be granted access to perform actions or access entities on this Account. See User Grants View ([GET /account/users/{username}/grants](/docs/api/account/#users-grants-view)) for details on how to configure grants for a restricted User.  (e.g. true)
  username: string # The User's username. This is used for logging in, and may also be displayed alongside actions the User performs (for example, in Events or public StackScripts).  (e.g. example_user)
]: any -> record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/users")
  let body = {"email": $email, "restricted": $restricted, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# User Delete
#
# DELETE /account/users/{username}
# operationId: deleteUser
export def "account-users delete" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/account/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User View
#
# GET /account/users/{username}
# operationId: getUser
export def "account-users get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/account/users/{username}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User Update
#
# PUT /account/users/{username}
# operationId: updateUser
export def "account-users update" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address for the User. Linode sends emails to this address for account management communications. May be used for other communications as configured.  (format: email, e.g. example_user@linode.com)
  --restricted: oneof<nothing, bool> # If true, the User must be granted access to perform actions or access entities on this Account. See User Grants View ([GET /account/users/{username}/grants](/docs/api/account/#users-grants-view)) for details on how to configure grants for a restricted User.  (e.g. true)
  --body-username: string # The User's username. This is used for logging in, and may also be displayed alongside actions the User performs (for example, in Events or public StackScripts).  (e.g. example_user)
]: any -> record<email: string, restricted: bool, ssh_keys: list<string>, tfa_enabled: bool, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/account/users/{username}"))
  let body = {"email": $email, "restricted": $restricted, "username": $body_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# User's Grants View
#
# GET /account/users/{username}/grants
# operationId: getUserGrants
export def "account-users-grants get" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/account/users/{username}/grants"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User's Grants Update
#
# PUT /account/users/{username}/grants
# operationId: updateUserGrants
# --database item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --domain item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --global shape: {account_access?: "read_only"|"read_write", add_databases?: bool, add_domains?: bool, add_firewalls?: bool, add_images?: bool, add_linodes?: bool, add_longview?: bool, add_nodebalancers?: bool, add_stackscripts?: bool, add_volumes?: bool, cancel_account?: bool, longview_subscription?: bool}
# --image item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --linode item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --longview item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --nodebalancer item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --stackscript item shape: {id?: int, permissions?: "read_only"|"read_write"}
# --volume item shape: {id?: int, permissions?: "read_only"|"read_write"}
export def "account-users-grants update" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --database: list # The grants this User has for each Database that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --domain: list # The grants this User has for each Domain that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --global: record # A structure containing the Account-level grants a User has. — shape: {account_access?: "read_only"|"read_write", add_databases?: bool, add_domains?: bool, add_firewalls?: bool, add_images?: bool, add_linodes?: bool, add_longview?: bool, add_nodebalancers?: bool, add_stackscripts?: bool, add_volumes?: bool, cancel_account?: bool, longview_subscription?: bool}
  --image: list # The grants this User has for each Image that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --linode: list # The grants this User has for each Linode that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --longview: list # The grants this User has for each Longview Client that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --nodebalancer: list # The grants this User has for each NodeBalancer that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --stackscript: list # The grants this User has for each StackScript that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
  --volume: list # The grants this User has for each Block Storage Volume that is owned by this Account. — item shape: {id?: int, permissions?: "read_only"|"read_write"}
]: any -> record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/account/users/{username}/grants"))
  let body = {"database": $database, "domain": $domain, "global": $global, "image": $image, "linode": $linode, "longview": $longview, "nodebalancer": $nodebalancer, "stackscript": $stackscript, "volume": $volume} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Database Engines List
#
# GET /databases/engines
# operationId: getDatabasesEngines
export def "databases-engines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<engine: string, id: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/databases/engines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Database Engine View
#
# GET /databases/engines/{engineId}
# operationId: getDatabasesEngine
export def "databases-engines get" [
  engine_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<engine: string, id: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({engine_id: $engine_id} | format pattern "/databases/engines/{engine_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Databases List All
#
# GET /databases/instances
# operationId: getDatabasesInstances
export def "databases-instances get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<allow_list: list, cluster_size: int, created: string, encrypted: bool, engine: string, hosts: record, id: int, instance_uri: string, label: string, region: string, status: string, type: string, updated: string, updates: record, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/databases/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Databases List
#
# GET /databases/mongodb/instances
# operationId: getDatabasesMongoDBInstances
export def "databases-mongodb-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<allow_list: any, cluster_size: any, compression_type: string, created: any, encrypted: any, engine: string, hosts: record, id: any, label: any, peers: list, port: int, region: any, replica_set: string, ssl_connection: bool, status: any, storage_engine: string, type: any, updated: any, updates: any, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/databases/mongodb/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Delete
#
# DELETE /databases/mongodb/instances/{instanceId}
# operationId: deleteDatabasesMongoDBInstance
export def "databases-mongodb-instances delete" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database View
#
# GET /databases/mongodb/instances/{instanceId}
# operationId: getDatabasesMongoDBInstance
export def "databases-mongodb-instances get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_list: any, cluster_size: any, compression_type: string, created: any, encrypted: any, engine: string, hosts: record<primary: string, secondary: string>, id: any, label: any, peers: list<string>, port: int, region: any, replica_set: string, ssl_connection: bool, status: any, storage_engine: string, type: any, updated: any, updates: any, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Update
#
# PUT /databases/mongodb/instances/{instanceId}
# operationId: putDatabasesMongoDBInstance
export def "databases-mongodb-instances update" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: any
  --label: any
  --updates: any
]: any -> record<allow_list: any, cluster_size: any, compression_type: string, created: any, encrypted: any, engine: string, hosts: record<primary: string, secondary: string>, id: any, label: any, peers: list<string>, port: int, region: any, replica_set: string, ssl_connection: bool, status: any, storage_engine: string, type: any, updated: any, updates: any, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}"))
  let body = {"allow_list": $allow_list, "label": $label, "updates": $updates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed MongoDB Database Backups List
#
# GET /databases/mongodb/instances/{instanceId}/backups
# operationId: getDatabasesMongoDBInstanceBackups
export def "databases-mongodb-instances-backups list" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}/backups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Backup Snapshot Create
#
# POST /databases/mongodb/instances/{instanceId}/backups
# operationId: postDatabasesMongoDBInstanceBackup
export def "databases-mongodb-instances-backups create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the Database snapshot backup.  * Must include only ASCII letters or numbers. * Must be unique among other backup labels for this Database.  (e.g. db-snapshot)
  --target: string@target-completer # The Database cluster target. If the Database is a high availability cluster, choosing `secondary` creates a snapshot backup of a replica node.  (default: primary, e.g. primary)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}/backups"))
  let body = {"label": $label, "target": $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed MongoDB Database Backup Delete
#
# DELETE /databases/mongodb/instances/{instanceId}/backups/{backupId}
# operationId: deleteDatabaseMongoDBInstanceBackup
export def "databases-mongodb-instances-backups delete" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/mongodb/instances/{instance_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Backup View
#
# GET /databases/mongodb/instances/{instanceId}/backups/{backupId}
# operationId: getDatabasesMongoDBInstanceBackup
export def "databases-mongodb-instances-backups get" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: int, label: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/mongodb/instances/{instance_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Backup Restore
#
# POST /databases/mongodb/instances/{instanceId}/backups/{backupId}/restore
# operationId: postDatabasesMongoDBInstanceBackupRestore
export def "databases-mongodb-instances-backups-restore create" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/mongodb/instances/{instance_id}/backups/{backup_id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Credentials View
#
# GET /databases/mongodb/instances/{instanceId}/credentials
# operationId: getDatabasesMongoDBInstanceCredentials
export def "databases-mongodb-instances-credentials get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Credentials Reset
#
# POST /databases/mongodb/instances/{instanceId}/credentials/reset
# operationId: postDatabasesMongoDBInstanceCredentialsReset
export def "databases-mongodb-instances-credentials-reset create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}/credentials/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database Patch
#
# POST /databases/mongodb/instances/{instanceId}/patch
# operationId: postDatabasesMongoDBInstancePatch
export def "databases-mongodb-instances-patch create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}/patch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MongoDB Database SSL Certificate View
#
# GET /databases/mongodb/instances/{instanceId}/ssl
# operationId: getDatabasesMongoDBInstanceSSL
export def "databases-mongodb-instances-ssl get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ca_certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mongodb/instances/{instance_id}/ssl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Databases List
#
# GET /databases/mysql/instances
# operationId: getDatabasesMySQLInstances
export def "databases-mysql-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: any, id: any, label: any, port: int, region: any, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/databases/mysql/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Create
#
# POST /databases/mysql/instances
# operationId: postDatabasesMySQLInstances
export def "databases-mysql-instances create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: any
  --cluster-size: any
  --encrypted: any
  engine: string # The Managed Database engine in engine/version format. (e.g. mysql/8.0.26)
  label: any
  region: any
  --replication-type: any
  --ssl-connection: any
  type: any
]: any -> record<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: any, id: any, label: any, port: int, region: any, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/databases/mysql/instances")
  let body = {"allow_list": $allow_list, "cluster_size": $cluster_size, "encrypted": $encrypted, "engine": $engine, "label": $label, "region": $region, "replication_type": $replication_type, "ssl_connection": $ssl_connection, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed MySQL Database Delete
#
# DELETE /databases/mysql/instances/{instanceId}
# operationId: deleteDatabasesMySQLInstance
export def "databases-mysql-instances delete" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database View
#
# GET /databases/mysql/instances/{instanceId}
# operationId: getDatabasesMySQLInstance
export def "databases-mysql-instances get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: any, id: any, label: any, port: int, region: any, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Update
#
# PUT /databases/mysql/instances/{instanceId}
# operationId: putDatabasesMySQLInstance
export def "databases-mysql-instances update" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: any
  --label: any
  --updates: any
]: any -> record<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: any, id: any, label: any, port: int, region: any, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}"))
  let body = {"allow_list": $allow_list, "label": $label, "updates": $updates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed MySQL Database Backups List
#
# GET /databases/mysql/instances/{instanceId}/backups
# operationId: getDatabasesMySQLInstanceBackups
export def "databases-mysql-instances-backups list" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}/backups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Backup Snapshot Create
#
# POST /databases/mysql/instances/{instanceId}/backups
# operationId: postDatabasesMySQLInstanceBackup
export def "databases-mysql-instances-backups create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the Database snapshot backup.  * Must include only ASCII letters or numbers. * Must be unique among other backup labels for this Database.  (e.g. db-snapshot)
  --target: string@target-completer # The Database cluster target. If the Database is a high availability cluster, choosing `secondary` creates a snapshot backup of a replica node.  (default: primary, e.g. primary)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}/backups"))
  let body = {"label": $label, "target": $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed MySQL Database Backup Delete
#
# DELETE /databases/mysql/instances/{instanceId}/backups/{backupId}
# operationId: deleteDatabaseMySQLInstanceBackup
export def "databases-mysql-instances-backups delete" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/mysql/instances/{instance_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Backup View
#
# GET /databases/mysql/instances/{instanceId}/backups/{backupId}
# operationId: getDatabasesMySQLInstanceBackup
export def "databases-mysql-instances-backups get" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: int, label: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/mysql/instances/{instance_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Backup Restore
#
# POST /databases/mysql/instances/{instanceId}/backups/{backupId}/restore
# operationId: postDatabasesMySQLInstanceBackupRestore
export def "databases-mysql-instances-backups-restore create" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/mysql/instances/{instance_id}/backups/{backup_id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Credentials View
#
# GET /databases/mysql/instances/{instanceId}/credentials
# operationId: getDatabasesMySQLInstanceCredentials
export def "databases-mysql-instances-credentials get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Credentials Reset
#
# POST /databases/mysql/instances/{instanceId}/credentials/reset
# operationId: postDatabasesMySQLInstanceCredentialsReset
export def "databases-mysql-instances-credentials-reset create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}/credentials/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database Patch
#
# POST /databases/mysql/instances/{instanceId}/patch
# operationId: postDatabasesMySQLInstancePatch
export def "databases-mysql-instances-patch create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}/patch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed MySQL Database SSL Certificate View
#
# GET /databases/mysql/instances/{instanceId}/ssl
# operationId: getDatabasesMySQLInstanceSSL
export def "databases-mysql-instances-ssl get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ca_certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/mysql/instances/{instance_id}/ssl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Databases List
#
# GET /databases/postgresql/instances
# operationId: getDatabasesPostgreSQLInstances
export def "databases-postgresql-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: record, id: any, label: any, port: int, region: any, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/databases/postgresql/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Create
#
# POST /databases/postgresql/instances
# operationId: postDatabasesPostgreSQLInstances
export def "databases-postgresql-instances create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: any
  --cluster-size: any
  --encrypted: any
  engine: string # The Managed Database engine in engine/version format. (e.g. postgresql/13.2)
  label: any
  region: any
  --replication-commit-type: any
  --replication-type: any
  --ssl-connection: any
  type: any
]: any -> record<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: record<primary: string, secondary: string>, id: any, label: any, port: int, region: any, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/databases/postgresql/instances")
  let body = {"allow_list": $allow_list, "cluster_size": $cluster_size, "encrypted": $encrypted, "engine": $engine, "label": $label, "region": $region, "replication_commit_type": $replication_commit_type, "replication_type": $replication_type, "ssl_connection": $ssl_connection, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed PostgreSQL Database Delete
#
# DELETE /databases/postgresql/instances/{instanceId}
# operationId: deleteDatabasesPostgreSQLInstance
export def "databases-postgresql-instances delete" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database View
#
# GET /databases/postgresql/instances/{instanceId}
# operationId: getDatabasesPostgreSQLInstance
export def "databases-postgresql-instances get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: record<primary: string, secondary: string>, id: any, label: any, port: int, region: any, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Update
#
# PUT /databases/postgresql/instances/{instanceId}
# operationId: putDatabasesPostgreSQLInstance
export def "databases-postgresql-instances update" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-list: any
  --label: any
  --updates: any
]: any -> record<allow_list: any, cluster_size: any, created: any, encrypted: any, engine: string, hosts: record<primary: string, secondary: string>, id: any, label: any, port: int, region: any, replication_commit_type: string, replication_type: string, ssl_connection: bool, status: any, type: any, updated: any, updates: any, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}"))
  let body = {"allow_list": $allow_list, "label": $label, "updates": $updates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed PostgreSQL Database Backups List
#
# GET /databases/postgresql/instances/{instanceId}/backups
# operationId: getDatabasesPostgreSQLInstanceBackups
export def "databases-postgresql-instances-backups list" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<created: string, id: int, label: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}/backups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Backup Snapshot Create
#
# POST /databases/postgresql/instances/{instanceId}/backups
# operationId: postDatabasesPostgreSQLInstanceBackup
export def "databases-postgresql-instances-backups create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the Database snapshot backup.  * Must include only ASCII letters or numbers. * Must be unique among other backup labels for this Database.  (e.g. db-snapshot)
  --target: string@target-completer # The Database cluster target. If the Database is a high availability cluster, choosing `secondary` creates a snapshot backup of a replica node.  (default: primary, e.g. primary)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}/backups"))
  let body = {"label": $label, "target": $target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed PostgreSQL Database Backup Delete
#
# DELETE /databases/postgresql/instances/{instanceId}/backups/{backupId}
# operationId: deleteDatabasePostgreSQLInstanceBackup
export def "databases-postgresql-instances-backups delete" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/postgresql/instances/{instance_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Backup View
#
# GET /databases/postgresql/instances/{instanceId}/backups/{backupId}
# operationId: getDatabasesPostgreSQLInstanceBackup
export def "databases-postgresql-instances-backups get" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: int, label: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/postgresql/instances/{instance_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Backup Restore
#
# POST /databases/postgresql/instances/{instanceId}/backups/{backupId}/restore
# operationId: postDatabasesPostgreSQLInstanceBackupRestore
export def "databases-postgresql-instances-backups-restore create" [
  instance_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id, backup_id: $backup_id} | format pattern "/databases/postgresql/instances/{instance_id}/backups/{backup_id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Credentials View
#
# GET /databases/postgresql/instances/{instanceId}/credentials
# operationId: getDatabasesPostgreSQLInstanceCredentials
export def "databases-postgresql-instances-credentials get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<password: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Credentials Reset
#
# POST /databases/postgresql/instances/{instanceId}/credentials/reset
# operationId: postDatabasesPostgreSQLInstanceCredentialsReset
export def "databases-postgresql-instances-credentials-reset create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}/credentials/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database Patch
#
# POST /databases/postgresql/instances/{instanceId}/patch
# operationId: postDatabasesPostgreSQLInstancePatch
export def "databases-postgresql-instances-patch create" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}/patch"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed PostgreSQL Database SSL Certificate View
#
# GET /databases/postgresql/instances/{instanceId}/ssl
# operationId: getDatabasesPostgreSQLInstanceSSL
export def "databases-postgresql-instances-ssl get" [
  instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ca_certificate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({instance_id: $instance_id} | format pattern "/databases/postgresql/instances/{instance_id}/ssl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Database Types List
#
# GET /databases/types
# operationId: getDatabasesTypes
export def "databases-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<page: int, pages: int, results: int, data: table<class: string, deprecated: bool, disk: int, engines: record, id: string, label: string, memory: int, vcpus: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/databases/types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Database Type View
#
# GET /databases/types/{typeId}
# operationId: getDatabasesType
export def "databases-types get" [
  type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<class: string, deprecated: bool, disk: int, engines: record<mongodb: list<record>, mysql: list<record>, postgresql: list<record>>, id: string, label: string, memory: int, vcpus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type_id: $type_id} | format pattern "/databases/types/{type_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domains List
#
# GET /domains
# operationId: getDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<axfr_ips: list, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list, ttl_sec: int, type: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domain Create
#
# POST /domains
# operationId: createDomain
@deprecated --flag group
export def "domains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --axfr-ips: list # The list of IPs that may perform a zone transfer for this Domain. The total combined length of all data within this array cannot exceed 1000 characters.  **Note**: This is potentially dangerous, and should be set to an empty list unless you intend to use it.  (e.g. [])
  --description: string # A description for this Domain. This is for display purposes only.
  domain: string # The domain this Domain represents. Domain labels cannot be longer than 63 characters and must conform to [RFC1035](https://tools.ietf.org/html/rfc1035). Domains must be unique on Linode's platform, including across different Linode accounts; there cannot be two Domains representing the same domain.  (e.g. example.org)
  --expire-sec: int # The amount of time in seconds that may pass before this Domain is no longer authoritative.  * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200.  * Any other value is rounded up to the nearest valid value.  * A value of 0 is equivalent to the default value of 1209600.  (default: 0, e.g. 300)
  --group: string # The group this Domain belongs to.  This is for display purposes only.  (DEPRECATED)
  --master-ips: list # The IP addresses representing the master DNS for this Domain. At least one value is required for `type` slave Domains. The total combined length of all data within this array cannot exceed 1000 characters.  (e.g. [])
  --refresh-sec: int # The amount of time in seconds before this Domain should be refreshed.  * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200.  * Any other value is rounded up to the nearest valid value.  * A value of 0 is equivalent to the default value of 14400.  (default: 0, e.g. 300)
  --retry-sec: int # The interval, in seconds, at which a failed refresh should be retried.  * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200.  * Any other value is rounded up to the nearest valid value.  * A value of 0 is equivalent to the default value of 14400.  (default: 0, e.g. 300)
  --soa-email: string # Start of Authority email address. This is required for `type` master Domains.  (format: email, e.g. admin@example.org)
  --status: string@status-completer # Used to control whether this Domain is currently being rendered.  (default: active, e.g. active)
  --tags: list # An array of tags applied to this object.  Tags are for organizational purposes only.  (e.g. [example tag, another example])
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 86400.  (default: 0, e.g. 300)
  type: string@type-completer-1 # Whether this Domain represents the authoritative source of information for the domain it describes ("master"), or whether it is a read-only copy of a master ("slave").  (e.g. master)
]: any -> record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let body = {"axfr_ips": $axfr_ips, "description": $description, "domain": $domain, "expire_sec": $expire_sec, "group": $group, "master_ips": $master_ips, "refresh_sec": $refresh_sec, "retry_sec": $retry_sec, "soa_email": $soa_email, "status": $status, "tags": $tags, "ttl_sec": $ttl_sec, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domain Import
#
# POST /domains/import
# operationId: importDomain
export def "domains-import import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # The domain to import.  (e.g. example.com)
  remote_nameserver: string # The remote nameserver that allows zone transfers (AXFR).  (e.g. examplenameserver.com)
]: any -> record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains/import")
  let body = {"domain": $domain, "remote_nameserver": $remote_nameserver} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domain Delete
#
# DELETE /domains/{domainId}
# operationId: deleteDomain
export def "domains delete" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domain View
#
# GET /domains/{domainId}
# operationId: getDomain
export def "domains get" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domain Update
#
# PUT /domains/{domainId}
# operationId: updateDomain
@deprecated --flag group
export def "domains update" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --axfr-ips: list # The list of IPs that may perform a zone transfer for this Domain. The total combined length of all data within this array cannot exceed 1000 characters.  **Note**: This is potentially dangerous, and should be set to an empty list unless you intend to use it.  (e.g. [])
  --description: string # A description for this Domain. This is for display purposes only.
  --domain: string # The domain this Domain represents. Domain labels cannot be longer than 63 characters and must conform to [RFC1035](https://tools.ietf.org/html/rfc1035). Domains must be unique on Linode's platform, including across different Linode accounts; there cannot be two Domains representing the same domain.  (e.g. example.org)
  --expire-sec: int # The amount of time in seconds that may pass before this Domain is no longer authoritative.  * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200.  * Any other value is rounded up to the nearest valid value.  * A value of 0 is equivalent to the default value of 1209600.  (default: 0, e.g. 300)
  --group: string # The group this Domain belongs to.  This is for display purposes only.  (DEPRECATED)
  --master-ips: list # The IP addresses representing the master DNS for this Domain. At least one value is required for `type` slave Domains. The total combined length of all data within this array cannot exceed 1000 characters.  (e.g. [])
  --refresh-sec: int # The amount of time in seconds before this Domain should be refreshed.  * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200.  * Any other value is rounded up to the nearest valid value.  * A value of 0 is equivalent to the default value of 14400.  (default: 0, e.g. 300)
  --retry-sec: int # The interval, in seconds, at which a failed refresh should be retried.  * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200.  * Any other value is rounded up to the nearest valid value.  * A value of 0 is equivalent to the default value of 14400.  (default: 0, e.g. 300)
  --soa-email: string # Start of Authority email address. This is required for `type` master Domains.  (format: email, e.g. admin@example.org)
  --status: string@status-completer # Used to control whether this Domain is currently being rendered.  (default: active, e.g. active)
  --tags: list # An array of tags applied to this object.  Tags are for organizational purposes only.  (e.g. [example tag, another example])
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. * Valid values are 0, 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200. * Any other value is rounded up to the nearest valid value. * A value of 0 is equivalent to the default value of 86400.  (default: 0, e.g. 300)
  --type: string@type-completer-1 # Whether this Domain represents the authoritative source of information for the domain it describes ("master"), or whether it is a read-only copy of a master ("slave").  (e.g. master)
]: any -> record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}"))
  let body = {"axfr_ips": $axfr_ips, "description": $description, "domain": $domain, "expire_sec": $expire_sec, "group": $group, "master_ips": $master_ips, "refresh_sec": $refresh_sec, "retry_sec": $retry_sec, "soa_email": $soa_email, "status": $status, "tags": $tags, "ttl_sec": $ttl_sec, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domain Clone
#
# POST /domains/{domainId}/clone
# operationId: cloneDomain
export def "domains-clone clone" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # The new domain for the clone. Domain labels cannot be longer than 63 characters and must conform to [RFC1035](https://tools.ietf.org/html/rfc1035). Domains must be unique on Linode's platform, including across different Linode accounts; there cannot be two Domains representing the same domain.  (e.g. example.org)
]: any -> record<axfr_ips: list<string>, description: string, domain: string, expire_sec: int, group: string, id: int, master_ips: list<string>, refresh_sec: int, retry_sec: int, soa_email: string, status: string, tags: list<string>, ttl_sec: int, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}/clone"))
  let body = {"domain": $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domain Records List
#
# GET /domains/{domainId}/records
# operationId: getDomainRecords
export def "domains-records list" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domain Record Create
#
# POST /domains/{domainId}/records
# operationId: createDomainRecord
export def "domains-records create" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of this Record. For requests, this property's actual usage and whether it is required depends on the type of record this represents:  `A` and `AAAA`: The hostname or FQDN of the Record.  `NS`: The subdomain, if any, to use with the Domain of the Record. Wildcard NS records (`*`) are not supported.  `MX`: The mail subdomain. For example, `sub` for the address `user@sub.example.com` under the `example.com` Domain. Must be an empty string (`""`) for a Null MX Record.  `CNAME`: The hostname. Must be unique. Required.  `TXT`: The hostname.  `SRV`: Unused. Use the `service` property to set the service name for this record.  `CAA`: The subdomain. Omit or enter an empty string (`""`) to apply to the entire Domain.  `PTR`: See our guide on how to [Configure Your Linode for Reverse DNS (rDNS)](/docs/guides/configure-rdns/).  (e.g. test)
  --port: int # The port this Record points to. Only valid and required for SRV record requests.  (e.g. 80)
  --priority: int # The priority of the target host for this Record. Lower values are preferred. Only valid for MX and SRV record requests. Required for SRV record requests.  Defaults to `0` for MX record requests. Must be `0` for Null MX records.  (e.g. 50)
  --protocol: string # The protocol this Record's service communicates with. An underscore (`_`) is prepended automatically to the submitted value for this property. Only valid for SRV record requests.  (nullable)
  --service: string # The name of the service. An underscore (`_`) is prepended and a period (`.`) is appended automatically to the submitted value for this property. Only valid and required for SRV record requests.  (nullable)
  --tag: string@tag-completer # The tag portion of a CAA record. Only valid and required for CAA record requests.  (nullable)
  --target: string # The target for this Record. For requests, this property's actual usage and whether it is required depends on the type of record this represents:  `A` and `AAAA`: The IP address. Use `[remote_addr]` to submit the IPv4 address of the request. Required.  `NS`: The name server. Must be a valid domain. Required.  `MX`: The mail server. Must be a valid domain unless creating a Null MX Record. To create a [Null MX Record](https://datatracker.ietf.org/doc/html/rfc7505), first [remove](/docs/api/domains/#domain-record-delete) any additional MX records, create an MX record with empty strings (`""`) for the `target` and `name`. If a Domain has a Null MX record, new MX records cannot be created. Required.  `CNAME`: The alias. Must be a valid domain. Required.  `TXT`: The value. Required.  `SRV`: The target domain or subdomain. If a subdomain is entered, it is automatically used with the Domain. To configure for a different domain, enter a valid FQDN. For example, the value `www` with a Domain for `example.com` results in a target set to `www.example.com`, whereas the value `sample.com` results in a target set to `sample.com`. Required.  `CAA`: The value. For `issue` or `issuewild` tags, the domain of your certificate issuer. For the `iodef` tag, a contact or submission URL (domain, http, https, or mailto). Requirements depend on the tag for this record:   * `issue`: The domain of your certificate issuer. Must be a valid domain.   * `issuewild`: Must begin with `*`.   * `iodef`: Must be either (1) a valid domain, (2) a valid domain prepended with `http://` or `https://`, or (3) a valid email address prepended with `mailto:`.  `PTR`: Required. See our guide on how to [Configure Your Linode for Reverse DNS (rDNS)](/docs/guides/configure-rdns/).  With the exception of A, AAAA, and CAA records, this field accepts a trailing period.  (e.g. 192.0.2.0)
  --ttl-sec: int # "Time to Live" - the amount of time in seconds that this Domain's records may be cached by resolvers or other domain servers. Valid values are 300, 3600, 7200, 14400, 28800, 57600, 86400, 172800, 345600, 604800, 1209600, and 2419200 - any other value will be rounded to the nearest valid value.  (e.g. 604800)
  type: string@type-completer-2 # The type of Record this is in the DNS system. For example, A records associate a domain name with an IPv4 address, and AAAA records associate a domain name with an IPv6 address. For more information, see the guides on [DNS Record Types](/docs/products/networking/dns-manager/guides/#dns-record-types).  (e.g. A)
  --weight: int # The relative weight of this Record used in the case of identical priority. Higher values are preferred. Only valid and required for SRV record requests.  (e.g. 50)
]: any -> record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}/records"))
  let body = {"name": $name, "port": $port, "priority": $priority, "protocol": $protocol, "service": $service, "tag": $tag, "target": $target, "ttl_sec": $ttl_sec, "type": $type, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domain Record Delete
#
# DELETE /domains/{domainId}/records/{recordId}
# operationId: deleteDomainRecord
export def "domains-records delete" [
  domain_id: int
  record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id, record_id: $record_id} | format pattern "/domains/{domain_id}/records/{record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domain Record View
#
# GET /domains/{domainId}/records/{recordId}
# operationId: getDomainRecord
export def "domains-records get" [
  domain_id: int
  record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id, record_id: $record_id} | format pattern "/domains/{domain_id}/records/{record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Domain Record Update
#
# PUT /domains/{domainId}/records/{recordId}
# operationId: updateDomainRecord
export def "domains-records update" [
  domain_id: int
  record_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any
  --port: any
  --priority: any
  --protocol: any
  --service: any
  --tag: any
  --target: any
  --ttl-sec: any
  --weight: any
]: any -> record<created: string, id: int, name: string, port: int, priority: int, protocol: string, service: string, tag: string, target: string, ttl_sec: int, type: string, updated: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id, record_id: $record_id} | format pattern "/domains/{domain_id}/records/{record_id}"))
  let body = {"name": $name, "port": $port, "priority": $priority, "protocol": $protocol, "service": $service, "tag": $tag, "target": $target, "ttl_sec": $ttl_sec, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Domain Zone File View
#
# GET /domains/{domainId}/zone-file
# operationId: getDomainZone
export def "domains-zone-file get" [
  domain_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<zone_file: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({domain_id: $domain_id} | format pattern "/domains/{domain_id}/zone-file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Images List
#
# GET /images
# operationId: getImages
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Image Create
#
# POST /images
# operationId: createImage
export def "images create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A detailed description of this Image.
  disk_id: int # The ID of the Linode Disk that this Image will be created from.  (e.g. 42)
  --label: string # A short title of this Image. Defaults to the label of the Disk it is being created from if not provided.
]: any -> record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/images")
  let body = {"description": $description, "disk_id": $disk_id, "label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Image Upload
#
# POST /images/upload
export def "images-upload post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description for the uploaded Image. (e.g. This is an example image in the docs.)
  label: string # Label for the uploaded Image. (e.g. my-image-label)
  region: string # The region to upload to. Once uploaded, the Image can be used in any region.  (e.g. eu-central)
]: any -> record<image: record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string>, upload_to: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/images/upload")
  let body = {"description": $description, "label": $label, "region": $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Image Delete
#
# DELETE /images/{imageId}
# operationId: deleteImage
export def "images delete" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: $image_id} | format pattern "/images/{image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Image View
#
# GET /images/{imageId}
# operationId: getImage
export def "images get" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: $image_id} | format pattern "/images/{image_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Image Update
#
# PUT /images/{imageId}
# operationId: updateImage
export def "images update" [
  image_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A detailed description of this Image. (nullable, e.g. Example Image description.)
  --label: string # A short description of the Image.  (e.g. Debian 11)
]: any -> record<created: string, created_by: string, deprecated: bool, description: string, eol: string, expiry: string, id: string, is_public: bool, label: string, size: int, status: string, type: string, updated: string, vendor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({image_id: $image_id} | format pattern "/images/{image_id}"))
  let body = {"description": $description, "label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linodes List
#
# GET /linode/instances
# operationId: getLinodeInstances
export def "linode-instances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<alerts: record, backups: record, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: record, ipv4: list, ipv6: string, label: string, region: string, specs: record, status: string, tags: list, type: string, updated: string, watchdog_enabled: bool>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/linode/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode Create
#
# POST /linode/instances
# operationId: createLinodeInstance
# --interfaces item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
export def "linode-instances create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: any
  --authorized-users: any
  --booted: oneof<nothing, bool> # This field defaults to `true` if the Linode is created with an Image or from a Backup. If it is deployed from an Image or a Backup and you wish it to remain `offline` after deployment, set this to `false`.  (default: true)
  --image: any
  --root-pass: any
  --stackscript-data: any
  --stackscript-id: any
  --backup-id: int # A Backup ID from another Linode's available backups. Your User must have `read_write` access to that Linode, the Backup must have a `status` of `successful`, and the Linode must be deployed to the same `region` as the Backup. See [GET /linode/instances/{linodeId}/backups](/docs/api/linode-instances/#backups-list) for a Linode's available backups.  This field and the `image` field are mutually exclusive.  (e.g. 1234)
  --backups-enabled: oneof<nothing, bool> # If this field is set to `true`, the created Linode will automatically be enrolled in the Linode Backup service. This will incur an additional charge. The cost for the Backup service is dependent on the Type of Linode deployed.  This option is always treated as `true` if the account-wide `backups_enabled` setting is `true`.  See [account settings](/docs/api/account/#account-settings-view) for more information.  Backup pricing is included in the response from [/linodes/types](/docs/api/linode-types/#types-list)
  --group: any
  --interfaces: list # An array of Network Interfaces to add to this Linode's Configuration Profile.  Up to three interface objects can be entered in this array. The position in the array determines the interface to which the settings apply:  - First/0:  eth0 - Second/1: eth1 - Third/2:  eth2  When updating a Linode's interfaces, *each interface must be redefined*. An empty interfaces array results in a default public interface configuration only.  If no public interface is configured, public IP addresses are still assigned to the Linode but will not be usable without manual configuration.  **Note:** Changes to Linode interface configurations can be enabled by rebooting the Linode.  **Note:** Only Next Generation Network (NGN) data centers support VLANs. Use the Regions ([/regions](/docs/api/regions/)) endpoint to view the capabilities of data center regions. If a VLAN is attached to your Linode and you attempt to migrate or clone it to a non-NGN data center, the migration or cloning will not initiate. If a Linode cannot be migrated because of an incompatibility, you will be prompted to select a different data center or contact support.  **Note:** See the [VLANs Overview](/docs/products/networking/vlans/#technical-specifications) guide to view additional specifications and limitations. — item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
  --label: any
  --private-ip: oneof<nothing, bool> # If true, the created Linode will have private networking enabled and assigned a private IPv4 address.  (e.g. true)
  region: string # The [Region](/docs/api/regions/#regions-list) where the Linode will be located.  (e.g. us-east)
  --swap-size: int # When deploying from an Image, this field is optional, otherwise it is ignored. This is used to set the swap disk size for the newly-created Linode.  (default: 512, e.g. 512)
  --tags: any
  type: string # The [Linode Type](/docs/api/linode-types/#types-list) of the Linode you are creating.  (e.g. g6-standard-2)
]: any -> record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: record, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/linode/instances")
  let body = {"authorized_keys": $authorized_keys, "authorized_users": $authorized_users, "booted": $booted, "image": $image, "root_pass": $root_pass, "stackscript_data": $stackscript_data, "stackscript_id": $stackscript_id, "backup_id": $backup_id, "backups_enabled": $backups_enabled, "group": $group, "interfaces": $interfaces, "label": $label, "private_ip": $private_ip, "region": $region, "swap_size": $swap_size, "tags": $tags, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Delete
#
# DELETE /linode/instances/{linodeId}
# operationId: deleteLinodeInstance
export def "linode-instances delete" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode View
#
# GET /linode/instances/{linodeId}
# operationId: getLinodeInstance
export def "linode-instances get" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: record, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode Update
#
# PUT /linode/instances/{linodeId}
# operationId: updateLinodeInstance
# --alerts shape: {cpu?: int, io?: int, network_in?: int, network_out?: int, transfer_quota?: int}
# --backups shape: {schedule?: record}
@deprecated --flag group
export def "linode-instances update" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alerts: record # shape: {cpu?: int, io?: int, network_in?: int, network_out?: int, transfer_quota?: int}
  --backups: record # Information about this Linode's backups status. For information about available backups, see [/linode/instances/{linodeId}/backups](/docs/api/linode-instances/#backups-list). — shape: {schedule?: record}
  --group: string # A deprecated property denoting a group label for this Linode.  (DEPRECATED, e.g. Linode-Group)
  --label: string # The Linode's label is for display purposes only. If no label is provided for a Linode, a default will be assigned.  Linode labels have the following constraints:    * Must begin and end with an alphanumeric character.   * May only consist of alphanumeric characters, dashes (`-`), underscores (`_`) or periods (`.`).   * Cannot have two dashes (`--`), underscores (`__`) or periods (`..`) in a row.  (e.g. linode123)
  --tags: list # An array of tags applied to this object.  Tags are for organizational purposes only.  (e.g. [example tag, another example])
  --watchdog-enabled: oneof<nothing, bool> # The watchdog, named Lassie, is a Shutdown Watchdog that monitors your Linode and will reboot it if it powers off unexpectedly. It works by issuing a boot job when your Linode powers off without a shutdown job being responsible. To prevent a loop, Lassie will give up if there have been more than 5 boot jobs issued within 15 minutes.  (e.g. true)
]: any -> record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: record, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}"))
  let body = {"alerts": $alerts, "backups": $backups, "group": $group, "label": $label, "tags": $tags, "watchdog_enabled": $watchdog_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Backups List
#
# GET /linode/instances/{linodeId}/backups
# operationId: getBackups
export def "linode-instances-backups list" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<automatic: table<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>, snapshot: record<current: record<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>, in_progress: record<available: bool, configs: list, created: string, disks: list, finished: string, id: int, label: string, status: string, type: string, updated: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/backups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Snapshot Create
#
# POST /linode/instances/{linodeId}/backups
# operationId: createSnapshot
export def "linode-instances-backups create-snapshot" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the new snapshot. (e.g. SnapshotLabel)
]: any -> record<available: bool, configs: list<string>, created: string, disks: table<filesystem: any, label: string, size: int>, finished: string, id: int, label: string, status: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/backups"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Backups Cancel
#
# POST /linode/instances/{linodeId}/backups/cancel
# operationId: cancelBackups
export def "linode-instances-backups-cancel cancel" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/backups/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Backups Enable
#
# POST /linode/instances/{linodeId}/backups/enable
# operationId: enableBackups
export def "linode-instances-backups-enable enable" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/backups/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Backup View
#
# GET /linode/instances/{linodeId}/backups/{backupId}
# operationId: getBackup
export def "linode-instances-backups get" [
  linode_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: bool, configs: list<string>, created: string, disks: table<filesystem: any, label: string, size: int>, finished: string, id: int, label: string, status: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, backup_id: $backup_id} | format pattern "/linode/instances/{linode_id}/backups/{backup_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Backup Restore
#
# POST /linode/instances/{linodeId}/backups/{backupId}/restore
# operationId: restoreBackup
export def "linode-instances-backups-restore restoreBackup" [
  linode_id: int
  backup_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-linode-id: int # The ID of the Linode to restore a Backup to.  (e.g. 234)
  --overwrite: oneof<nothing, bool> # If True, deletes all Disks and Configs on the target Linode before restoring.  If False, and the Disk image size is larger than the available space on the Linode, an error message indicating insufficient space is returned.  (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, backup_id: $backup_id} | format pattern "/linode/instances/{linode_id}/backups/{backup_id}/restore"))
  let body = {"linode_id": $body_linode_id, "overwrite": $overwrite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Boot
#
# POST /linode/instances/{linodeId}/boot
# operationId: bootLinodeInstance
export def "linode-instances-boot bootLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # The Linode Config ID to boot into.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/boot"))
  let body = {"config_id": $config_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Clone
#
# POST /linode/instances/{linodeId}/clone
# operationId: cloneLinodeInstance
@deprecated --flag group
export def "linode-instances-clone clone" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --backups-enabled: oneof<nothing, bool> # If this field is set to `true`, the created Linode will automatically be enrolled in the Linode Backup service. This will incur an additional charge. Pricing is included in the response from [/linodes/types](/docs/api/linode-types/#types-list).  * Can only be included when cloning to a new Linode.  (e.g. true)
  --configs: list # An array of configuration profile IDs. * If the `configs` parameter **is not provided**, then **all configuration profiles and their associated disks will be cloned** from the source Linode. Any disks specified by the `disks` parameter will also be cloned. * **If an empty array is provided** for the `configs` parameter, then **no configuration profiles (nor their associated disks) will be cloned** from the source Linode. Any disks specified by the `disks` parameter will still be cloned. * **If a non-empty array is provided** for the `configs` parameter, then **the configuration profiles specified in the array (and their associated disks) will be cloned** from the source Linode. Any disks specified by the `disks` parameter will also be cloned.
  --disks: list # An array of disk IDs. * If the `disks` parameter **is not provided**, then **no extra disks will be cloned** from the source Linode. All disks associated with the configuration profiles specified by the `configs` parameter will still be cloned. * **If an empty array is provided** for the `disks` parameter, then **no extra disks will be cloned** from the source Linode. All disks associated with the configuration profiles specified by the `configs` parameter will still be cloned. * **If a non-empty array is provided** for the `disks` parameter, then **the disks specified in the array will be cloned** from the source Linode, in addition to any disks associated with the configuration profiles specified by the `configs` parameter.
  --group: string # A label used to group Linodes for display. Linodes are not required to have a group.  (DEPRECATED, e.g. Linode-Group)
  --label: string # The label to assign this Linode when cloning to a new Linode. * Can only be provided when cloning to a new Linode. * Defaults to "linode".  (e.g. cloned-linode)
  --body-linode-id: int # If an existing Linode is the target for the clone, the ID of that Linode. The existing Linode must have enough resources to accept the clone.  (e.g. 124)
  --private-ip: oneof<nothing, bool> # If true, the created Linode will have private networking enabled and assigned a private IPv4 address. * Can only be provided when cloning to a new Linode.  (e.g. true)
  --region: string # This is the Region where the Linode will be deployed. To view all available Regions you can deploy to see [/regions](/docs/api/regions/#regions-list). * Region can only be provided and is required when cloning to a new Linode.  (e.g. us-east)
  --type: string # A Linode's Type determines what resources are available to it, including disk space, memory, and virtual cpus. The amounts available to a specific Linode are returned as `specs` on the Linode object.  To view all available Linode Types you can deploy with see [/linode/types](/docs/api/linode-types/#types-list).  * Type can only be provided and is required when cloning to a new Linode.  (e.g. g6-standard-2)
]: any -> record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: record, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/clone"))
  let body = {"backups_enabled": $backups_enabled, "configs": $configs, "disks": $disks, "group": $group, "label": $label, "linode_id": $body_linode_id, "private_ip": $private_ip, "region": $region, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configuration Profiles List
#
# GET /linode/instances/{linodeId}/configs
# operationId: getLinodeConfigs
export def "linode-instances-configs list" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<comments: string, devices: record, helpers: record, id: int, interfaces: list, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/configs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configuration Profile Create
#
# POST /linode/instances/{linodeId}/configs
# operationId: addLinodeConfig
# --devices shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record, sdh?: record}
# --helpers shape: {devtmpfs_automount?: bool, distro?: bool, modules_dep?: bool, network?: bool, updatedb_disabled?: bool}
# --interfaces item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
export def "linode-instances-configs create" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string # Optional field for arbitrary User comments on this Config. (nullable, e.g. This is my main Config)
  devices: record # A dictionary of device disks to use as a device map in a Linode's configuration profile. * An empty device disk dictionary or a dictionary with empty values for device slots is allowed. * If no devices are specified, booting from this configuration will hold until a device exists that allows the boot process to start. — shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record, sdh?: record}
  --helpers: record # Helpers enabled when booting to this Linode Config. — shape: {devtmpfs_automount?: bool, distro?: bool, modules_dep?: bool, network?: bool, updatedb_disabled?: bool}
  --interfaces: list # An array of Network Interfaces to add to this Linode's Configuration Profile.  Up to three interface objects can be entered in this array. The position in the array determines the interface to which the settings apply:  - First/0:  eth0 - Second/1: eth1 - Third/2:  eth2  When updating a Linode's interfaces, *each interface must be redefined*. An empty interfaces array results in a default public interface configuration only.  If no public interface is configured, public IP addresses are still assigned to the Linode but will not be usable without manual configuration.  **Note:** Changes to Linode interface configurations can be enabled by rebooting the Linode.  **Note:** Only Next Generation Network (NGN) data centers support VLANs. Use the Regions ([/regions](/docs/api/regions/)) endpoint to view the capabilities of data center regions. If a VLAN is attached to your Linode and you attempt to migrate or clone it to a non-NGN data center, the migration or cloning will not initiate. If a Linode cannot be migrated because of an incompatibility, you will be prompted to select a different data center or contact support.  **Note:** See the [VLANs Overview](/docs/products/networking/vlans/#technical-specifications) guide to view additional specifications and limitations. — item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
  --kernel: string # A Kernel ID to boot a Linode with. Defaults to "linode/latest-64bit". (e.g. linode/latest-64bit)
  label: string # The Config's label is for display purposes only.  (e.g. My Config)
  --memory-limit: int # Defaults to the total RAM of the Linode.  (e.g. 2048)
  --root-device: string # The root device to boot. * If no value or an invalid value is provided, root device will default to `/dev/sda`. * If the device specified at the root device location is not mounted, the Linode will not boot until a device is mounted.  (e.g. /dev/sda)
  --run-level: string@run-level-completer # Defines the state of your Linode after booting. Defaults to `default`.  (e.g. default)
  --virt-mode: string@virt-mode-completer # Controls the virtualization mode. Defaults to `paravirt`. * `paravirt` is suitable for most cases. Linodes running in paravirt mode   share some qualities with the host, ultimately making it run faster since   there is less transition between it and the host. * `fullvirt` affords more customization, but is slower because 100% of the VM   is virtualized.  (e.g. paravirt)
]: any -> record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/configs"))
  let body = {"comments": $comments, "devices": $devices, "helpers": $helpers, "interfaces": $interfaces, "kernel": $kernel, "label": $label, "memory_limit": $memory_limit, "root_device": $root_device, "run_level": $run_level, "virt_mode": $virt_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configuration Profile Delete
#
# DELETE /linode/instances/{linodeId}/configs/{configId}
# operationId: deleteLinodeConfig
export def "linode-instances-configs delete" [
  linode_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, config_id: $config_id} | format pattern "/linode/instances/{linode_id}/configs/{config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configuration Profile View
#
# GET /linode/instances/{linodeId}/configs/{configId}
# operationId: getLinodeConfig
export def "linode-instances-configs get" [
  linode_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, config_id: $config_id} | format pattern "/linode/instances/{linode_id}/configs/{config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configuration Profile Update
#
# PUT /linode/instances/{linodeId}/configs/{configId}
# operationId: updateLinodeConfig
# --devices shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record, sdh?: record}
# --helpers shape: {devtmpfs_automount?: bool, distro?: bool, modules_dep?: bool, network?: bool, updatedb_disabled?: bool}
# --interfaces item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
export def "linode-instances-configs update" [
  linode_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comments: string # Optional field for arbitrary User comments on this Config. (nullable, e.g. This is my main Config)
  --devices: record # A dictionary of device disks to use as a device map in a Linode's configuration profile. * An empty device disk dictionary or a dictionary with empty values for device slots is allowed. * If no devices are specified, booting from this configuration will hold until a device exists that allows the boot process to start. — shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record, sdh?: record}
  --helpers: record # Helpers enabled when booting to this Linode Config. — shape: {devtmpfs_automount?: bool, distro?: bool, modules_dep?: bool, network?: bool, updatedb_disabled?: bool}
  --interfaces: list # An array of Network Interfaces to add to this Linode's Configuration Profile.  Up to three interface objects can be entered in this array. The position in the array determines the interface to which the settings apply:  - First/0:  eth0 - Second/1: eth1 - Third/2:  eth2  When updating a Linode's interfaces, *each interface must be redefined*. An empty interfaces array results in a default public interface configuration only.  If no public interface is configured, public IP addresses are still assigned to the Linode but will not be usable without manual configuration.  **Note:** Changes to Linode interface configurations can be enabled by rebooting the Linode.  **Note:** Only Next Generation Network (NGN) data centers support VLANs. Use the Regions ([/regions](/docs/api/regions/)) endpoint to view the capabilities of data center regions. If a VLAN is attached to your Linode and you attempt to migrate or clone it to a non-NGN data center, the migration or cloning will not initiate. If a Linode cannot be migrated because of an incompatibility, you will be prompted to select a different data center or contact support.  **Note:** See the [VLANs Overview](/docs/products/networking/vlans/#technical-specifications) guide to view additional specifications and limitations. — item shape: {ipam_address?: string, label?: string, purpose?: "public"|"vlan"}
  --kernel: string # A Kernel ID to boot a Linode with. Defaults to "linode/latest-64bit". (e.g. linode/latest-64bit)
  --label: string # The Config's label is for display purposes only.  (e.g. My Config)
  --memory-limit: int # Defaults to the total RAM of the Linode.  (e.g. 2048)
  --root-device: string # The root device to boot. * If no value or an invalid value is provided, root device will default to `/dev/sda`. * If the device specified at the root device location is not mounted, the Linode will not boot until a device is mounted.  (e.g. /dev/sda)
  --run-level: string@run-level-completer # Defines the state of your Linode after booting. Defaults to `default`.  (e.g. default)
  --virt-mode: string@virt-mode-completer # Controls the virtualization mode. Defaults to `paravirt`. * `paravirt` is suitable for most cases. Linodes running in paravirt mode   share some qualities with the host, ultimately making it run faster since   there is less transition between it and the host. * `fullvirt` affords more customization, but is slower because 100% of the VM   is virtualized.  (e.g. paravirt)
]: any -> record<comments: string, devices: record<sda: record<disk_id: int, volume_id: int>, sdb: record<disk_id: int, volume_id: int>, sdc: record<disk_id: int, volume_id: int>, sdd: record<disk_id: int, volume_id: int>, sde: record<disk_id: int, volume_id: int>, sdf: record<disk_id: int, volume_id: int>, sdg: record<disk_id: int, volume_id: int>, sdh: record<disk_id: int, volume_id: int>>, helpers: record<devtmpfs_automount: bool, distro: bool, modules_dep: bool, network: bool, updatedb_disabled: bool>, id: int, interfaces: table<ipam_address: string, label: string, purpose: string>, kernel: string, label: string, memory_limit: int, root_device: string, run_level: string, virt_mode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, config_id: $config_id} | format pattern "/linode/instances/{linode_id}/configs/{config_id}"))
  let body = {"comments": $comments, "devices": $devices, "helpers": $helpers, "interfaces": $interfaces, "kernel": $kernel, "label": $label, "memory_limit": $memory_limit, "root_device": $root_device, "run_level": $run_level, "virt_mode": $virt_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disks List
#
# GET /linode/instances/{linodeId}/disks
# operationId: getLinodeDisks
export def "linode-instances-disks list" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/disks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disk Create
#
# POST /linode/instances/{linodeId}/disks
# operationId: addLinodeDisk
export def "linode-instances-disks create" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: list # A list of public SSH keys that will be automatically appended to the root user's `~/.ssh/authorized_keys` file when deploying from an Image.  (e.g. [ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer])
  --authorized-users: list # A list of usernames. If the usernames have associated SSH keys, the keys will be appended to the root users `~/.ssh/authorized_keys` file automatically when deploying from an Image.  (e.g. [myUser, secondaryUser])
  --filesystem: any
  --image: string # An Image ID to deploy the Linode Disk from.  Access the Images List ([GET /images](/docs/api/images/#images-list)) endpoint with authentication to view all available Images. Official Linode Images start with `linode/`, while your Account's Images start with `private/`. Creating a disk from a Private Image requires `read_only` or `read_write` permissions for that Image. Access the User's Grant Update ([PUT /account/users/{username}/grants](/docs/api/account/#users-grants-update)) endpoint to adjust permissions for an Account Image.  (e.g. linode/debian9)
  --label: any
  --root-pass: string # This sets the root user's password on a newly-created Linode Disk when deploying from an Image.  * **Required** when creating a Linode Disk from an Image, including when using a StackScript.  * Must meet a password strength score requirement that is calculated internally by the API. If the strength requirement is not met, you will receive a `Password does not meet strength requirement` error.  (format: password, e.g. aComplexP@ssword)
  size: int # The size of the Disk in MB.  Images require a minimum size. Access the Image View ([GET /images/{imageID}](/docs/api/images/#image-view)) endpoint to view its size.  (e.g. 48640)
  --stackscript-data: record # This field is required only if the StackScript being deployed requires input data from the User for successful completion. See [User Defined Fields (UDFs)](/docs/guides/writing-scripts-for-use-with-linode-stackscripts-a-tutorial/#user-defined-fields-udfs) for more details.  This field is required to be valid JSON.  Total length cannot exceed 65,535 characters.  (e.g. {gh_username: linode})
  --stackscript-id: int # A StackScript ID that will cause the referenced StackScript to be run during deployment of this Linode. A compatible `image` is required to use a StackScript. To get a list of available StackScript and their permitted Images see [/stackscripts](/docs/api/stackscripts/#stackscripts-list). This field cannot be used when deploying from a Backup or a Private Image.  (e.g. 10079)
]: any -> record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/disks"))
  let body = {"authorized_keys": $authorized_keys, "authorized_users": $authorized_users, "filesystem": $filesystem, "image": $image, "label": $label, "root_pass": $root_pass, "size": $size, "stackscript_data": $stackscript_data, "stackscript_id": $stackscript_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disk Delete
#
# DELETE /linode/instances/{linodeId}/disks/{diskId}
# operationId: deleteDisk
export def "linode-instances-disks delete" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, disk_id: $disk_id} | format pattern "/linode/instances/{linode_id}/disks/{disk_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disk View
#
# GET /linode/instances/{linodeId}/disks/{diskId}
# operationId: getLinodeDisk
export def "linode-instances-disks get" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, disk_id: $disk_id} | format pattern "/linode/instances/{linode_id}/disks/{disk_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disk Update
#
# PUT /linode/instances/{linodeId}/disks/{diskId}
# operationId: updateDisk
export def "linode-instances-disks update" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filesystem: string@filesystem-completer # The Disk filesystem can be one of:    * raw - No filesystem, just a raw binary stream.   * swap - Linux swap area.   * ext3 - The ext3 journaling filesystem for Linux.   * ext4 - The ext4 journaling filesystem for Linux.   * initrd - initrd (uncompressed initrd, ext2, max 32 MB).  (e.g. ext4)
  --label: string # The Disk's label is for display purposes only.  (e.g. Debian 9 Disk)
  --size: int # The size of the Disk in MB. (e.g. 48640)
]: any -> record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, disk_id: $disk_id} | format pattern "/linode/instances/{linode_id}/disks/{disk_id}"))
  let body = {"filesystem": $filesystem, "label": $label, "size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disk Clone
#
# POST /linode/instances/{linodeId}/disks/{diskId}/clone
# operationId: cloneLinodeDisk
export def "linode-instances-disks-clone clone" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, filesystem: string, id: int, label: string, size: int, status: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, disk_id: $disk_id} | format pattern "/linode/instances/{linode_id}/disks/{disk_id}/clone"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disk Root Password Reset
#
# POST /linode/instances/{linodeId}/disks/{diskId}/password
# operationId: resetDiskPassword
export def "linode-instances-disks-password reset" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The new root password for the OS installed on this Disk. The password must meet the complexity strength validation requirements for a strong password.  (e.g. another@complex^Password123)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, disk_id: $disk_id} | format pattern "/linode/instances/{linode_id}/disks/{disk_id}/password"))
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disk Resize
#
# POST /linode/instances/{linodeId}/disks/{diskId}/resize
# operationId: resizeDisk
export def "linode-instances-disks-resize resize" [
  linode_id: int
  disk_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  size: int # The desired size, in MB, of the disk.  (e.g. 2048)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, disk_id: $disk_id} | format pattern "/linode/instances/{linode_id}/disks/{disk_id}/resize"))
  let body = {"size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Firewalls List
#
# GET /linode/instances/{linodeId}/firewalls
# operationId: getLinodeFirewalls
export def "linode-instances-firewalls get" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, id: int, label: string, rules: record, status: string, tags: list, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/firewalls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Networking Information List
#
# GET /linode/instances/{linodeId}/ips
# operationId: getLinodeIPs
export def "linode-instances-ips list" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ipv4: record<private: list<record>, public: list<record>, reserved: list<record>, shared: list<record>>, ipv6: record<global: record<prefix: int, range: string, region: string, route_target: string>, link_local: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>, slaac: record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/ips"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IPv4 Address Allocate
#
# POST /linode/instances/{linodeId}/ips
# operationId: addLinodeIP
export def "linode-instances-ips create" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public: oneof<nothing, bool> # Whether to create a public or private IPv4 address.  (e.g. true)
  type: string@type-completer-3 # The type of address you are allocating. Only IPv4 addresses may be allocated through this endpoint.  (e.g. ipv4)
]: any -> record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/ips"))
  let body = {"public": $public, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IPv4 Address Delete
#
# DELETE /linode/instances/{linodeId}/ips/{address}
# operationId: removeLinodeIP
export def "linode-instances-ips delete" [
  linode_id: int
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, address: $address} | format pattern "/linode/instances/{linode_id}/ips/{address}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IP Address View
#
# GET /linode/instances/{linodeId}/ips/{address}
# operationId: getLinodeIP
export def "linode-instances-ips get" [
  linode_id: int
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, address: $address} | format pattern "/linode/instances/{linode_id}/ips/{address}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IP Address Update
#
# PUT /linode/instances/{linodeId}/ips/{address}
# operationId: updateLinodeIP
export def "linode-instances-ips update" [
  linode_id: int
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rdns: string # The reverse DNS assigned to this address. For public IPv4 addresses, this will be set to a default value provided by Linode if not explicitly set.  (nullable, e.g. test.example.org)
]: any -> record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, address: $address} | format pattern "/linode/instances/{linode_id}/ips/{address}"))
  let body = {"rdns": $rdns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DC Migration/Pending Host Migration Initiate
#
# POST /linode/instances/{linodeId}/migrate
# operationId: migrateLinodeInstance
export def "linode-instances-migrate migrateLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --region: string # The region to which the Linode will be migrated. Must be a valid region slug. A list of regions can be viewed by using the [GET /regions](/docs/api/regions/#regions-list) endpoint. A cross data center migration will cancel a pending migration that has not yet been initiated. A cross data center migration will initiate a `linode_migrate_datacenter_create` event.  (e.g. us-east)
  --upgrade: oneof<nothing, bool> # When initiating a cross DC migration, setting this value to true will also ensure that the Linode is upgraded to the latest generation of hardware that corresponds to your Linode's Type, if any free upgrades are available for it. If no free upgrades are available, and this value is set to true, then the endpoint will return a 400 error code and the migration will not be performed. If the data center set in the `region` field does not allow upgrades, then the endpoint will return a 400 error code and the migration will not be performed.  (default: false, e.g. false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/migrate"))
  let body = {"region": $region, "upgrade": $upgrade} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Upgrade
#
# POST /linode/instances/{linodeId}/mutate
# operationId: mutateLinodeInstance
export def "linode-instances-mutate mutateLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-auto-disk-resize: oneof<nothing, bool> # Automatically resize disks when resizing a Linode. When resizing down to a smaller plan your Linode's data must fit within the smaller disk size.  (default: true, e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/mutate"))
  let body = {"allow_auto_disk_resize": $allow_auto_disk_resize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode NodeBalancers View
#
# GET /linode/instances/{linodeId}/nodebalancers
# operationId: getLinodeNodeBalancers
export def "linode-instances-nodebalancers get" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list, transfer: record, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/nodebalancers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode Root Password Reset
#
# POST /linode/instances/{linodeId}/password
# operationId: resetLinodePassword
export def "linode-instances-password reset" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  root_pass: string # The root user's password on this Linode. Linode passwords must meet a password strength score requirement that is calculated internally by the API. If the strength requirement is not met, you will receive a Password does not meet strength requirement error.  (e.g. a$eCure4assw0rd!43v51)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/password"))
  let body = {"root_pass": $root_pass} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Reboot
#
# POST /linode/instances/{linodeId}/reboot
# operationId: rebootLinodeInstance
export def "linode-instances-reboot rebootLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # The Linode Config ID to reboot into.  If null or omitted, the last booted config will be used.  If there was no last booted config and this Linode only has one config, it will be used.  If a config cannot be determined, an error will be returned.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/reboot"))
  let body = {"config_id": $config_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Rebuild
#
# POST /linode/instances/{linodeId}/rebuild
# operationId: rebuildLinodeInstance
export def "linode-instances-rebuild rebuildLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: any
  --authorized-users: any
  --booted: oneof<nothing, bool> # This field defaults to `true` if the Linode is created with an Image or from a Backup. If it is deployed from an Image or a Backup and you wish it to remain `offline` after deployment, set this to `false`.  (default: true)
  image: any
  root_pass: any
  --stackscript-data: any
  --stackscript-id: any
]: any -> record<alerts: record<cpu: int, io: int, network_in: int, network_out: int, transfer_quota: int>, backups: record<available: bool, enabled: bool, last_successful: string, schedule: record<day: string, window: string>>, created: string, group: string, host_uuid: string, hypervisor: string, id: int, image: record, ipv4: list<string>, ipv6: string, label: string, region: string, specs: record<disk: int, memory: int, transfer: int, vcpus: int>, status: string, tags: list<string>, type: string, updated: string, watchdog_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/rebuild"))
  let body = {"authorized_keys": $authorized_keys, "authorized_users": $authorized_users, "booted": $booted, "image": $image, "root_pass": $root_pass, "stackscript_data": $stackscript_data, "stackscript_id": $stackscript_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Boot into Rescue Mode
#
# POST /linode/instances/{linodeId}/rescue
# operationId: rescueLinodeInstance
# --devices shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record}
export def "linode-instances-rescue rescueLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: record # shape: {sda?: record, sdb?: record, sdc?: record, sdd?: record, sde?: record, sdf?: record, sdg?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/rescue"))
  let body = {"devices": $devices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Resize
#
# POST /linode/instances/{linodeId}/resize
# operationId: resizeLinodeInstance
export def "linode-instances-resize resize" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-auto-disk-resize: oneof<nothing, bool> # Automatically resize disks when resizing a Linode. When resizing down to a smaller plan your Linode's data must fit within the smaller disk size.  (default: true, e.g. true)
  type: string # The ID representing the Linode Type. (e.g. g6-standard-2)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/resize"))
  let body = {"allow_auto_disk_resize": $allow_auto_disk_resize, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linode Shut Down
#
# POST /linode/instances/{linodeId}/shutdown
# operationId: shutdownLinodeInstance
export def "linode-instances-shutdown shutdownLinodeInstance" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/shutdown"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode Statistics View
#
# GET /linode/instances/{linodeId}/stats
# operationId: getLinodeStats
export def "linode-instances-stats get-by-linodeId" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cpu: list<list<float>>, io: record<io: list<list>, swap: list<list>>, netv4: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, netv6: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Statistics View (year/month)
#
# GET /linode/instances/{linodeId}/stats/{year}/{month}
# operationId: getLinodeStatsByYearMonth
export def "linode-instances-stats get-by-linodeId-year-month" [
  linode_id: int
  year: int
  month: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cpu: list<list<float>>, io: record<io: list<list>, swap: list<list>>, netv4: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, netv6: record<in: list<list>, out: list<list>, private_in: list<list>, private_out: list<list>>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, year: $year, month: $month} | format pattern "/linode/instances/{linode_id}/stats/{year}/{month}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Network Transfer View
#
# GET /linode/instances/{linodeId}/transfer
# operationId: getLinodeTransfer
export def "linode-instances-transfer get-by-linodeId" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billable: int, quota: int, used: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/transfer"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Network Transfer View (year/month)
#
# GET /linode/instances/{linodeId}/transfer/{year}/{month}
# operationId: getLinodeTransferByYearMonth
export def "linode-instances-transfer get-by-linodeId-year-month" [
  linode_id: int
  year: int
  month: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bytes_in: int, bytes_out: int, bytes_total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id, year: $year, month: $month} | format pattern "/linode/instances/{linode_id}/transfer/{year}/{month}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode's Volumes List
#
# GET /linode/instances/{linodeId}/volumes
# operationId: getLinodeVolumes
export def "linode-instances-volumes get" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/linode/instances/{linode_id}/volumes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kernels List
#
# GET /linode/kernels
# operationId: getKernels
export def "linode-kernels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<architecture: string, built: string, deprecated: bool, id: string, kvm: bool, label: string, pvops: bool, version: string, xen: bool>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/linode/kernels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kernel View
#
# GET /linode/kernels/{kernelId}
# operationId: getKernel
export def "linode-kernels get" [
  kernel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<architecture: string, built: string, deprecated: bool, id: string, kvm: bool, label: string, pvops: bool, version: string, xen: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({kernel_id: $kernel_id} | format pattern "/linode/kernels/{kernel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StackScripts List
#
# GET /linode/stackscripts
# operationId: getStackScripts
export def "linode-stackscripts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: list, user_gravatar_id: string, username: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/linode/stackscripts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StackScript Create
#
# POST /linode/stackscripts
# operationId: addStackScript
export def "linode-stackscripts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the StackScript.  (e.g. This StackScript installs and configures MySQL )
  images: list # An array of Image IDs. These are the Images that can be deployed with this StackScript.  `any/all` indicates that all available Images, including private Images, are accepted.  (e.g. [linode/debian9, linode/debian8])
  --is-public: oneof<nothing, bool> # This determines whether other users can use your StackScript. **Once a StackScript is made public, it cannot be made private.**  (e.g. true)
  label: string # The StackScript's label is for display purposes only.  (e.g. a-stackscript)
  --rev-note: string # This field allows you to add notes for the set of revisions made to this StackScript.  (e.g. Set up MySQL)
  script: string # The script to execute when provisioning a new Linode with this StackScript.  (e.g. "#!/bin/bash" )
]: any -> record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/linode/stackscripts")
  let body = {"description": $description, "images": $images, "is_public": $is_public, "label": $label, "rev_note": $rev_note, "script": $script} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# StackScript Delete
#
# DELETE /linode/stackscripts/{stackscriptId}
# operationId: deleteStackScript
export def "linode-stackscripts delete" [
  stackscript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stackscript_id: $stackscript_id} | format pattern "/linode/stackscripts/{stackscript_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StackScript View
#
# GET /linode/stackscripts/{stackscriptId}
# operationId: getStackScript
export def "linode-stackscripts get" [
  stackscript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stackscript_id: $stackscript_id} | format pattern "/linode/stackscripts/{stackscript_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# StackScript Update
#
# PUT /linode/stackscripts/{stackscriptId}
# operationId: updateStackScript
export def "linode-stackscripts update" [
  stackscript_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A description for the StackScript.  (e.g. This StackScript installs and configures MySQL )
  --images: list # An array of Image IDs. These are the Images that can be deployed with this StackScript.  `any/all` indicates that all available Images, including private Images, are accepted.  (e.g. [linode/debian9, linode/debian8])
  --is-public: oneof<nothing, bool> # This determines whether other users can use your StackScript. **Once a StackScript is made public, it cannot be made private.**  (e.g. true)
  --label: string # The StackScript's label is for display purposes only.  (e.g. a-stackscript)
  --rev-note: string # This field allows you to add notes for the set of revisions made to this StackScript.  (e.g. Set up MySQL)
  --script: string # The script to execute when provisioning a new Linode with this StackScript.  (e.g. "#!/bin/bash" )
]: any -> record<created: string, deployments_active: int, deployments_total: int, description: string, id: int, images: list<string>, is_public: bool, label: string, mine: bool, rev_note: string, script: string, updated: string, user_defined_fields: table<default: string, example: string, label: string, manyOf: string, name: string, oneOf: string>, user_gravatar_id: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stackscript_id: $stackscript_id} | format pattern "/linode/stackscripts/{stackscript_id}"))
  let body = {"description": $description, "images": $images, "is_public": $is_public, "label": $label, "rev_note": $rev_note, "script": $script} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Types List
#
# GET /linode/types
# operationId: getLinodeTypes
export def "linode-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<addons: record, class: string, disk: int, gpus: int, id: string, label: string, memory: int, network_out: int, price: record, successor: string, transfer: int, vcpus: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/linode/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Type View
#
# GET /linode/types/{typeId}
# operationId: getLinodeType
export def "linode-types get" [
  type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addons: record<backups: record<price: record>>, class: string, disk: int, gpus: int, id: string, label: string, memory: int, network_out: int, price: record<hourly: int, monthly: int>, successor: string, transfer: int, vcpus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type_id: $type_id} | format pattern "/linode/types/{type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Clusters List
#
# GET /lke/clusters
# operationId: getLKEClusters
export def "lke-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<control_plane: record, created: string, id: int, k8s_version: string, label: string, region: string, tags: list, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lke/clusters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Cluster Create
#
# POST /lke/clusters
# operationId: createLKECluster
# --control_plane shape: {high_availability?: bool}
# --node_pools item shape: {autoscaler?: record, count?: any, disks?: list, tags?: any, type?: any}
export def "lke-clusters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --control-plane: record # Defines settings for the Kubernetes Control Plane. Allows for the enabling of High Availability (HA) for Control Plane Components. Enabling High Availability for LKE is an **irreversible** change. — shape: {high_availability?: bool}
  k8s_version: any
  label: any
  node_pools: list # item shape: {autoscaler?: record, count?: any, disks?: list, tags?: any, type?: any}
  region: any
  --tags: any
]: any -> record<control_plane: record<high_availability: bool>, created: string, id: int, k8s_version: string, label: string, region: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lke/clusters")
  let body = {"control_plane": $control_plane, "k8s_version": $k8s_version, "label": $label, "node_pools": $node_pools, "region": $region, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Kubernetes Cluster Delete
#
# DELETE /lke/clusters/{clusterId}
# operationId: deleteLKECluster
export def "lke-clusters delete" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Cluster View
#
# GET /lke/clusters/{clusterId}
# operationId: getLKECluster
export def "lke-clusters get" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<control_plane: record<high_availability: bool>, created: string, id: int, k8s_version: string, label: string, region: string, tags: list<string>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Cluster Update
#
# PUT /lke/clusters/{clusterId}
# operationId: putLKECluster
# --control_plane shape: {high_availability?: bool}
export def "lke-clusters update" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --control-plane: record # Defines settings for the Kubernetes Control Plane. Allows for the enabling of High Availability (HA) for Control Plane Components.  Enabling High Availability for LKE is an **irreversible** change.  When upgrading pre-existing LKE clusters to use the HA Control Plane, the following changes will additionally occur:  - All nodes will be deleted and new nodes will be created to replace them.  - Any local storage (such as `hostPath` volumes) will be erased.  - The upgrade process may take several minutes to complete, as nodes will be replaced on a rolling basis. — shape: {high_availability?: bool}
  --k8s-version: string # The desired Kubernetes version for this Kubernetes cluster in the format of &lt;major&gt;.&lt;minor&gt;. New and recycled Nodes in this cluster will be installed with the latest available patch for the Cluster's Kubernetes version.  When upgrading the Kubernetes version, only the next latest minor version following the current version can be deployed. For example, a cluster with Kubernetes version 1.19 can be upgraded to version 1.20, but not directly to 1.21.  The Kubernetes version of a cluster can not be downgraded.
  --label: any
  --tags: list # An array of tags applied to the Kubernetes cluster. Tags are for organizational purposes only. To delete a tag, exclude it from your `tags` array.  (e.g. [prod, monitoring, ecomm, blog])
]: any -> record<created: any, k8s_version: any, label: any, region: any, tags: list<string>, updated: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}"))
  let body = {"control_plane": $control_plane, "k8s_version": $k8s_version, "label": $label, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Kubernetes API Endpoints List
#
# GET /lke/clusters/{clusterId}/api-endpoints
# operationId: getLKEClusterAPIEndpoints
export def "lke-clusters-api-endpoints get" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<endpoint: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/api-endpoints"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Cluster Dashboard URL View
#
# GET /lke/clusters/{clusterId}/dashboard
# operationId: getLKEClusterDashboard
export def "lke-clusters-dashboard get" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/dashboard"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubeconfig Delete
#
# DELETE /lke/clusters/{clusterId}/kubeconfig
# operationId: deleteLKEClusterKubeconfig
export def "lke-clusters-kubeconfig delete" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/kubeconfig"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubeconfig View
#
# GET /lke/clusters/{clusterId}/kubeconfig
# operationId: getLKEClusterKubeconfig
export def "lke-clusters-kubeconfig get" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<kubeconfig: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/kubeconfig"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Delete
#
# DELETE /lke/clusters/{clusterId}/nodes/{nodeId}
# operationId: deleteLKEClusterNode
export def "lke-clusters-nodes delete" [
  cluster_id: int
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, node_id: $node_id} | format pattern "/lke/clusters/{cluster_id}/nodes/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node View
#
# GET /lke/clusters/{clusterId}/nodes/{nodeId}
# operationId: getLKEClusterNode
export def "lke-clusters-nodes get" [
  cluster_id: int
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, instance_id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, node_id: $node_id} | format pattern "/lke/clusters/{cluster_id}/nodes/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Recycle
#
# POST /lke/clusters/{clusterId}/nodes/{nodeId}/recycle
# operationId: postLKEClusterNodeRecycle
export def "lke-clusters-nodes-recycle create" [
  cluster_id: int
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, node_id: $node_id} | format pattern "/lke/clusters/{cluster_id}/nodes/{node_id}/recycle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Pools List
#
# GET /lke/clusters/{clusterId}/pools
# operationId: getLKEClusterPools
export def "lke-clusters-pools get" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<autoscaler: record, count: int, disks: list, id: int, nodes: list, tags: list, type: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/pools"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Pool Create
#
# POST /lke/clusters/{clusterId}/pools
# operationId: postLKEClusterPools
# --autoscaler shape: {enabled?: bool, max?: int, min?: int}
export def "lke-clusters-pools create" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoscaler: record # When enabled, the number of nodes autoscales within the defined minimum and maximum values.  When making a request, `max` and `min` require each other. — shape: {enabled?: bool, max?: int, min?: int}
  count: any
  --disks: list # **Note**: This field should be omitted except for special use cases. The disks specified here are partitions in *addition* to the primary partition and reduce the size of the primary partition, which can lead to stability problems for the Node.  This Node Pool's custom disk layout. Each item in this array will create a new disk partition for each node in this Node Pool.    * The custom disk layout is applied to each node in this Node Pool.   * The maximum number of custom disk partitions that can be configured is 7.   * Once the requested disk paritions are allocated, the remaining disk space is allocated to the node's boot disk.   * A Node Pool's custom disk layout is immutable over the lifetime of the Node Pool.
  --tags: any
  type: any
]: any -> record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/pools"))
  let body = {"autoscaler": $autoscaler, "count": $count, "disks": $disks, "tags": $tags, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Node Pool Delete
#
# DELETE /lke/clusters/{clusterId}/pools/{poolId}
# operationId: deleteLKENodePool
export def "lke-clusters-pools delete-lke-node" [
  cluster_id: int
  pool_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, pool_id: $pool_id} | format pattern "/lke/clusters/{cluster_id}/pools/{pool_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Pool View
#
# GET /lke/clusters/{clusterId}/pools/{poolId}
# operationId: getLKENodePool
export def "lke-clusters-pools get-lke-node" [
  cluster_id: int
  pool_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, pool_id: $pool_id} | format pattern "/lke/clusters/{cluster_id}/pools/{pool_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Pool Update
#
# PUT /lke/clusters/{clusterId}/pools/{poolId}
# operationId: putLKENodePool
export def "lke-clusters-pools update-lke-node" [
  cluster_id: int
  pool_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --autoscaler: any
  --count: any
]: any -> record<autoscaler: record<enabled: bool, max: int, min: int>, count: int, disks: table<size: int, type: string>, id: int, nodes: table<id: string, instance_id: string, status: string>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, pool_id: $pool_id} | format pattern "/lke/clusters/{cluster_id}/pools/{pool_id}"))
  let body = {"autoscaler": $autoscaler, "count": $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Node Pool Recycle
#
# POST /lke/clusters/{clusterId}/pools/{poolId}/recycle
# operationId: postLKEClusterPoolRecycle
export def "lke-clusters-pools-recycle create" [
  cluster_id: int
  pool_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id, pool_id: $pool_id} | format pattern "/lke/clusters/{cluster_id}/pools/{pool_id}/recycle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cluster Nodes Recycle
#
# POST /lke/clusters/{clusterId}/recycle
# operationId: postLKEClusterRecycle
export def "lke-clusters-recycle create" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/recycle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Cluster Regenerate
#
# POST /lke/clusters/{clusterId}/regenerate
# operationId: postLKEClusterRegenerate
export def "lke-clusters-regenerate create" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --kubeconfig: oneof<nothing, bool> # Whether to delete and regenerate the Kubeconfig file for this Cluster.  (default: false, e.g. true)
  --servicetoken: oneof<nothing, bool> # Whether to delete and regenerate the service access token for this Cluster.  (default: false, e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/regenerate"))
  let body = {"kubeconfig": $kubeconfig, "servicetoken": $servicetoken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Service Token Delete
#
# DELETE /lke/clusters/{clusterId}/servicetoken
# operationId: postLKECServiceTokenDelete
export def "lke-clusters-servicetoken create-lkec-service-token-delete" [
  cluster_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/lke/clusters/{cluster_id}/servicetoken"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Versions List
#
# GET /lke/versions
# operationId: getLKEVersions
export def "lke-versions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lke/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Kubernetes Version View
#
# GET /lke/versions/{version}
# operationId: getLKEVersion
export def "lke-versions get" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({version: $version} | format pattern "/lke/versions/{version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Longview Clients List
#
# GET /longview/clients
# operationId: getLongviewClients
export def "longview-clients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<api_key: string, apps: record, created: string, id: int, install_code: string, label: string, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/longview/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Longview Client Create
#
# POST /longview/clients
# operationId: createLongviewClient
export def "longview-clients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # This Client's unique label. This is for display purposes only.  (e.g. client789)
]: any -> record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/longview/clients")
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Longview Client Delete
#
# DELETE /longview/clients/{clientId}
# operationId: deleteLongviewClient
export def "longview-clients delete" [
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/longview/clients/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Longview Client View
#
# GET /longview/clients/{clientId}
# operationId: getLongviewClient
export def "longview-clients get" [
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/longview/clients/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Longview Client Update
#
# PUT /longview/clients/{clientId}
# operationId: updateLongviewClient
export def "longview-clients update" [
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # This Client's unique label. This is for display purposes only.  (e.g. client789)
]: any -> record<api_key: string, apps: record<apache: bool, mysql: bool, nginx: bool>, created: string, id: int, install_code: string, label: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/longview/clients/{client_id}"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Longview Plan View
#
# GET /longview/plan
# operationId: getLongviewPlan
export def "longview-plan get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/longview/plan")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Longview Plan Update
#
# PUT /longview/plan
# operationId: updateLongviewPlan
export def "longview-plan update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --longview-subscription: string@longview-subscription-completer # The subscription ID for a particular Longview plan. A value of `null` corresponds to Longview Free.  You can send a request to the [List Longview Subscriptions](/docs/api/longview/#longview-subscriptions-list) endpoint to receive the details of each plan.  (nullable, e.g. longview-10)
]: any -> record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/longview/plan")
  let body = {"longview_subscription": $longview_subscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Longview Subscriptions List
#
# GET /longview/subscriptions
# operationId: getLongviewSubscriptions
export def "longview-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<clients_included: int, id: string, label: string, price: record>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/longview/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Longview Subscription View
#
# GET /longview/subscriptions/{subscriptionId}
# operationId: getLongviewSubscription
export def "longview-subscriptions get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clients_included: int, id: string, label: string, price: record<hourly: float, monthly: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: $subscription_id} | format pattern "/longview/subscriptions/{subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Contacts List
#
# GET /managed/contacts
# operationId: getManagedContacts
export def "managed-contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<email: string, group: string, id: int, name: string, phone: record, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/managed/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Contact Create
#
# POST /managed/contacts
# operationId: createManagedContact
# --phone shape: {primary?: string, secondary?: string}
export def "managed-contacts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The address to email this Contact to alert them of issues.  (format: email, e.g. john.doe@example.org)
  --group: string # A grouping for this Contact. This is for display purposes only.  (nullable, e.g. on-call)
  --name: string # The name of this Contact.  (e.g. John Doe)
  --phone: record # Information about how to reach this Contact by phone. — shape: {primary?: string, secondary?: string}
]: any -> record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed/contacts")
  let body = {"email": $email, "group": $group, "name": $name, "phone": $phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Contact Delete
#
# DELETE /managed/contacts/{contactId}
# operationId: deleteManagedContact
export def "managed-contacts delete" [
  contact_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: $contact_id} | format pattern "/managed/contacts/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Contact View
#
# GET /managed/contacts/{contactId}
# operationId: getManagedContact
export def "managed-contacts get" [
  contact_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: $contact_id} | format pattern "/managed/contacts/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Contact Update
#
# PUT /managed/contacts/{contactId}
# operationId: updateManagedContact
# --phone shape: {primary?: string, secondary?: string}
export def "managed-contacts update" [
  contact_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The address to email this Contact to alert them of issues.  (format: email, e.g. john.doe@example.org)
  --group: string # A grouping for this Contact. This is for display purposes only.  (nullable, e.g. on-call)
  --name: string # The name of this Contact.  (e.g. John Doe)
  --phone: record # Information about how to reach this Contact by phone. — shape: {primary?: string, secondary?: string}
]: any -> record<email: string, group: string, id: int, name: string, phone: record<primary: string, secondary: string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: $contact_id} | format pattern "/managed/contacts/{contact_id}"))
  let body = {"email": $email, "group": $group, "name": $name, "phone": $phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Credentials List
#
# GET /managed/credentials
# operationId: getManagedCredentials
export def "managed-credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<id: int, label: string, last_decrypted: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/managed/credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Credential Create
#
# POST /managed/credentials
# operationId: createManagedCredential
export def "managed-credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The unique label for this Credential. This is for display purposes only.  (e.g. prod-password-1)
  password: string # The password to use when accessing the Managed Service.  (e.g. s3cur3P@ssw0rd)
  --username: string # The username to use when accessing the Managed Service.  (e.g. johndoe)
]: any -> record<id: int, label: string, last_decrypted: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed/credentials")
  let body = {"label": $label, "password": $password, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed SSH Key View
#
# GET /managed/credentials/sshkey
# operationId: viewManagedSSHKey
export def "managed-credentials-sshkey viewManagedSSHKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ssh_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed/credentials/sshkey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Credential View
#
# GET /managed/credentials/{credentialId}
# operationId: getManagedCredential
export def "managed-credentials get" [
  credential_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, label: string, last_decrypted: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credential_id: $credential_id} | format pattern "/managed/credentials/{credential_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Credential Update
#
# PUT /managed/credentials/{credentialId}
# operationId: updateManagedCredential
export def "managed-credentials update" [
  credential_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The unique label for this Credential. This is for display purposes only.  (e.g. prod-password-1)
]: any -> record<id: int, label: string, last_decrypted: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credential_id: $credential_id} | format pattern "/managed/credentials/{credential_id}"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Credential Delete
#
# POST /managed/credentials/{credentialId}/revoke
# operationId: deleteManagedCredential
export def "managed-credentials-revoke delete" [
  credential_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credential_id: $credential_id} | format pattern "/managed/credentials/{credential_id}/revoke"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Credential Username and Password Update
#
# POST /managed/credentials/{credentialId}/update
# operationId: updateManagedCredentialUsernamePassword
export def "managed-credentials-update update-managed-credential-username-password" [
  credential_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The password to use when accessing the Managed Service.  (e.g. s3cur3P@ssw0rd)
  --username: string # The username to use when accessing the Managed Service.  (e.g. johndoe)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credential_id: $credential_id} | format pattern "/managed/credentials/{credential_id}/update"))
  let body = {"password": $password, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Issues List
#
# GET /managed/issues
# operationId: getManagedIssues
export def "managed-issues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, entity: record, id: int, services: list>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/managed/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Issue View
#
# GET /managed/issues/{issueId}
# operationId: getManagedIssue
export def "managed-issues get" [
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, services: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issue_id: $issue_id} | format pattern "/managed/issues/{issue_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Linode Settings List
#
# GET /managed/linode-settings
# operationId: getManagedLinodeSettings
export def "managed-linode-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<group: string, id: int, label: string, ssh: record>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/managed/linode-settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode's Managed Settings View
#
# GET /managed/linode-settings/{linodeId}
# operationId: getManagedLinodeSetting
export def "managed-linode-settings get" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: string, id: int, label: string, ssh: record<access: bool, ip: string, port: int, user: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/managed/linode-settings/{linode_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Linode's Managed Settings Update
#
# PUT /managed/linode-settings/{linodeId}
# operationId: updateManagedLinodeSetting
# --ssh shape: {access?: bool, ip?: string, port?: int, user?: string}
export def "managed-linode-settings update" [
  linode_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ssh: record # The SSH settings for this Linode. — shape: {access?: bool, ip?: string, port?: int, user?: string}
]: any -> record<group: string, id: int, label: string, ssh: record<access: bool, ip: string, port: int, user: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linode_id: $linode_id} | format pattern "/managed/linode-settings/{linode_id}"))
  let body = {"ssh": $ssh} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Services List
#
# GET /managed/services
# operationId: getManagedServices
export def "managed-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<address: string, body: string, consultation_group: string, created: string, credentials: list, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Service Create
#
# POST /managed/services
# operationId: createManagedService
export def "managed-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The URL at which this Service is monitored.  URL parameters such as `?no-cache=1` are preserved.  URL fragments/anchors such as `#monitor` are **not** preserved.  (format: url, e.g. https://example.org)
  --body-body: string # What to expect to find in the response body for the Service to be considered up.  (nullable, e.g. it worked)
  --consultation-group: string # The group of ManagedContacts who should be notified or consulted with when an Issue is detected.  (e.g. on-call)
  --credentials: list # An array of ManagedCredential IDs that should be used when attempting to resolve issues with this Service.
  label: string # The label for this Service. This is for display purposes only.  (e.g. prod-1)
  --notes: string # Any information relevant to the Service that Linode special forces should know when attempting to resolve Issues.  (nullable, e.g. The service name is my-cool-application)
  --region: string # The Region in which this Service is located. This is required if address is a private IP, and may not be set otherwise.
  service_type: string@service-type-completer # How this Service is monitored.  (e.g. url)
  timeout: int # How long to wait, in seconds, for a response before considering the Service to be down.  (e.g. 30)
]: any -> record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed/services")
  let body = {"address": $address, "body": $body_body, "consultation_group": $consultation_group, "credentials": $credentials, "label": $label, "notes": $notes, "region": $region, "service_type": $service_type, "timeout": $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Service Delete
#
# DELETE /managed/services/{serviceId}
# operationId: deleteManagedService
export def "managed-services delete" [
  service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/managed/services/{service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Service View
#
# GET /managed/services/{serviceId}
# operationId: getManagedService
export def "managed-services get" [
  service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/managed/services/{service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Service Update
#
# PUT /managed/services/{serviceId}
# operationId: updateManagedService
export def "managed-services update" [
  service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The URL at which this Service is monitored.  URL parameters such as `?no-cache=1` are preserved.  URL fragments/anchors such as `#monitor` are **not** preserved.  (format: url, e.g. https://example.org)
  --body-body: string # What to expect to find in the response body for the Service to be considered up.  (nullable, e.g. it worked)
  --consultation-group: string # The group of ManagedContacts who should be notified or consulted with when an Issue is detected.  (e.g. on-call)
  --credentials: list # An array of ManagedCredential IDs that should be used when attempting to resolve issues with this Service.
  --label: string # The label for this Service. This is for display purposes only.  (e.g. prod-1)
  --notes: string # Any information relevant to the Service that Linode special forces should know when attempting to resolve Issues.  (nullable, e.g. The service name is my-cool-application)
  --region: string # The Region in which this Service is located. This is required if address is a private IP, and may not be set otherwise.
  --service-type: string@service-type-completer # How this Service is monitored.  (e.g. url)
  --timeout: int # How long to wait, in seconds, for a response before considering the Service to be down.  (e.g. 30)
]: any -> record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/managed/services/{service_id}"))
  let body = {"address": $address, "body": $body_body, "consultation_group": $consultation_group, "credentials": $credentials, "label": $label, "notes": $notes, "region": $region, "service_type": $service_type, "timeout": $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Managed Service Disable
#
# POST /managed/services/{serviceId}/disable
# operationId: disableManagedService
export def "managed-services-disable disable" [
  service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/managed/services/{service_id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Service Enable
#
# POST /managed/services/{serviceId}/enable
# operationId: enableManagedService
export def "managed-services-enable enable" [
  service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, body: string, consultation_group: string, created: string, credentials: list<int>, id: int, label: string, notes: string, region: string, service_type: string, status: string, timeout: int, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({service_id: $service_id} | format pattern "/managed/services/{service_id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managed Stats List
#
# GET /managed/stats
# operationId: getManagedStats
export def "managed-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewalls List
#
# GET /networking/firewalls
# operationId: getFirewalls
export def "networking-firewalls list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, id: int, label: string, rules: record, status: string, tags: list, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networking/firewalls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall Create
#
# POST /networking/firewalls
# operationId: createFirewalls
# --devices shape: {linodes?: list}
# --rules shape: {inbound?: list, inbound_policy?: "ACCEPT"|"DROP", outbound?: list, outbound_policy?: "ACCEPT"|"DROP"}
export def "networking-firewalls create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: record # Devices to create for this Firewall. When a Device is created, the Firewall is assigned to its associated service. Currently, Devices can only be created for Linode instances. — shape: {linodes?: list}
  rules: record # The inbound and outbound access rules to apply to the Firewall.  A Firewall may have up to 25 rules across its inbound and outbound rulesets. — shape: {inbound?: list, inbound_policy?: "ACCEPT"|"DROP", outbound?: list, outbound_policy?: "ACCEPT"|"DROP"}
  label: string # The Firewall's label, for display purposes only.  Firewall labels have the following constraints:    * Must begin and end with an alphanumeric character.   * May only consist of alphanumeric characters, dashes (`-`), underscores (`_`) or periods (`.`).   * Cannot have two dashes (`--`), underscores (`__`) or periods (`..`) in a row.   * Must be between 3 and 32 characters.   * Must be unique.  (e.g. firewall123)
  --tags: list # An array of tags applied to this object. Tags are for organizational purposes only.  (e.g. [example tag, another example])
]: any -> record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/networking/firewalls")
  let body = {"devices": $devices, "rules": $rules, "label": $label, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Firewall Delete
#
# DELETE /networking/firewalls/{firewallId}
# operationId: deleteFirewall
export def "networking-firewalls delete" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall View
#
# GET /networking/firewalls/{firewallId}
# operationId: getFirewall
export def "networking-firewalls get" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall Update
#
# PUT /networking/firewalls/{firewallId}
# operationId: updateFirewall
export def "networking-firewalls update" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: any
  --status: string@status-completer-1 # The status to be applied to this Firewall.    * When a Firewall is first created its status is `enabled`.  * Use the [Delete Firewall](/docs/api/networking/#firewall-delete) endpoint to delete a Firewall.  (e.g. enabled)
  --tags: any
]: any -> record<created: string, id: int, label: string, rules: record<inbound: list<record>, inbound_policy: string, outbound: list<record>, outbound_policy: string>, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}"))
  let body = {"label": $label, "status": $status, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Firewall Devices List
#
# GET /networking/firewalls/{firewallId}/devices
# operationId: getFirewallDevices
export def "networking-firewalls-devices list" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, entity: record, id: int, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall Device Create
#
# POST /networking/firewalls/{firewallId}/devices
# operationId: createFirewallDevice
export def "networking-firewalls-devices create" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}/devices"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Firewall Device Delete
#
# DELETE /networking/firewalls/{firewallId}/devices/{deviceId}
# operationId: deleteFirewallDevice
export def "networking-firewalls-devices delete" [
  firewall_id: int
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id, device_id: $device_id} | format pattern "/networking/firewalls/{firewall_id}/devices/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall Device View
#
# GET /networking/firewalls/{firewallId}/devices/{deviceId}
# operationId: getFirewallDevice
export def "networking-firewalls-devices get" [
  firewall_id: int
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, entity: record<id: int, label: string, type: string, url: string>, id: int, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id, device_id: $device_id} | format pattern "/networking/firewalls/{firewall_id}/devices/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall Rules List
#
# GET /networking/firewalls/{firewallId}/rules
# operationId: getFirewallRules
export def "networking-firewalls-rules get" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}/rules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Firewall Rules Update
#
# PUT /networking/firewalls/{firewallId}/rules
# operationId: updateFirewallRules
export def "networking-firewalls-rules update" [
  firewall_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbound: any
  --outbound: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({firewall_id: $firewall_id} | format pattern "/networking/firewalls/{firewall_id}/rules"))
  let body = {"inbound": $inbound, "outbound": $outbound} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IP Addresses List
#
# GET /networking/ips
# operationId: getIPs
export def "networking-ips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networking/ips")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IP Address Allocate
#
# POST /networking/ips
# operationId: allocateIP
export def "networking-ips allocateIP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  linode_id: int # The ID of a Linode you you have access to that this address will be allocated to.  (e.g. 123)
  --public: oneof<nothing, bool> # Whether to create a public or private IPv4 address.  (e.g. true)
  type: string@type-completer-3 # The type of address you are requesting. Only IPv4 addresses may be allocated through this endpoint.  (e.g. ipv4)
]: any -> record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networking/ips")
  let body = {"linode_id": $linode_id, "public": $public, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IP Addresses Assign
#
# POST /networking/ips/assign
# operationId: assignIPs
# --assignments item shape: {address?: string, linode_id?: int}
export def "networking-ips-assign assignIPs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assignments: list # The list of assignments to make. You must have read_write access to all IPs being assigned and all Linodes being assigned to in order for the assignments to succeed. — item shape: {address?: string, linode_id?: int}
  region: string # The ID of the Region in which these assignments are to take place. All IPs and Linodes must exist in this Region.  (e.g. us-east)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networking/ips/assign")
  let body = {"assignments": $assignments, "region": $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IP Addresses Share
#
# POST /networking/ips/share
# operationId: shareIPs
export def "networking-ips-share shareIPs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ips: list # A list of secondary Linode IPs to share with the primary Linode. * Can include both IPv4 addresses and IPv6 ranges (omit /56 and /64 prefix lengths) * Can include both private and public IPv4 addresses. * You must have access to all of these addresses and they must be in the same Region as the primary Linode. * Enter an empty array to remove all shared IP addresses.  (e.g. [192.0.2.1, 2001:db8:3c4d:15::])
  linode_id: int # The ID of the primary Linode that the addresses will be shared with.  (e.g. 123)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4beta")
  let full_url = (build-url $base "/networking/ips/share")
  let body = {"ips": $ips, "linode_id": $linode_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IP Address View
#
# GET /networking/ips/{address}
# operationId: getIP
export def "networking-ips get" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({address: $address} | format pattern "/networking/ips/{address}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IP Address RDNS Update
#
# PUT /networking/ips/{address}
# operationId: updateIP
export def "networking-ips update" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rdns: string # The reverse DNS assigned to this address. For public IPv4 addresses, this will be set to a default value provided by Linode if not explicitly set.  (nullable, e.g. test.example.org)
]: any -> record<address: string, gateway: string, linode_id: int, prefix: int, public: bool, rdns: string, region: string, subnet_mask: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({address: $address} | format pattern "/networking/ips/{address}"))
  let body = {"rdns": $rdns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Linodes Assign IPv4s
#
# POST /networking/ipv4/assign
# operationId: assignIPv4s
# --assignments item shape: {address?: string, linode_id?: int}
export def "networking-ipv4-assign assignIPv4s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assignments: list # The list of assignments to make. You must have read_write access to all IPs being assigned and all Linodes being assigned to in order for the assignments to succeed. — item shape: {address?: string, linode_id?: int}
  region: string # The ID of the Region in which these assignments are to take place. All IPs and Linodes must exist in this Region.  (e.g. us-east)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networking/ipv4/assign")
  let body = {"assignments": $assignments, "region": $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IPv4 Sharing Configure
#
# POST /networking/ipv4/share
# operationId: shareIPv4s
export def "networking-ipv4-share shareIPv4s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ips: list # A list of secondary Linode IPs to share with the primary Linode. * Can include both IPv4 addresses and IPv6 ranges (omit /56 and /64 prefix lengths) * Can include both private and public IPv4 addresses. * You must have access to all of these addresses and they must be in the same Region as the primary Linode. * Enter an empty array to remove all shared IP addresses.  (e.g. [192.0.2.1, 2001:db8:3c4d:15::])
  linode_id: int # The ID of the primary Linode that the addresses will be shared with.  (e.g. 123)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networking/ipv4/share")
  let body = {"ips": $ips, "linode_id": $linode_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IPv6 Pools List
#
# GET /networking/ipv6/pools
# operationId: getIPv6Pools
export def "networking-ipv6-pools get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<prefix: int, range: string, region: string, route_target: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networking/ipv6/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IPv6 Ranges List
#
# GET /networking/ipv6/ranges
# operationId: getIPv6Ranges
export def "networking-ipv6-ranges list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<prefix: int, range: string, region: string, route_target: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networking/ipv6/ranges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IPv6 Range Create
#
# POST /networking/ipv6/ranges
# operationId: postIPv6Range
export def "networking-ipv6-ranges create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --linode-id: int # The ID of the Linode to assign this range to. The SLAAC address for the provided Linode is used as the range's `route_target`.  * **Required** if `route_target` is omitted from the request.  * Mutually exclusive with `route_target`. Submitting values for both properties in a request results in an error.  (e.g. 123)
  prefix_length: int@prefix-length-completer # The prefix length of the IPv6 range.
  --route-target: string # The IPv6 SLAAC address to assign this range to.  * **Required** if `linode_id` is omitted from the request.  * Mutually exclusive with `linode_id`. Submitting values for both properties in a request results in an error.  * **Note**: Omit the `/128` prefix length of the SLAAC address when using this property.  (format: ipv6, e.g. 2001:0db8::1)
]: any -> record<range: string, route_target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networking/ipv6/ranges")
  let body = {"linode_id": $linode_id, "prefix_length": $prefix_length, "route_target": $route_target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# IPv6 Range Delete
#
# DELETE /networking/ipv6/ranges/{range}
# operationId: deleteIPv6Range
export def "networking-ipv6-ranges delete" [
  range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({range: $range} | format pattern "/networking/ipv6/ranges/{range}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IPv6 Range View
#
# GET /networking/ipv6/ranges/{range}
# operationId: getIPv6Range
export def "networking-ipv6-ranges get" [
  range: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<is_bgp: bool, linodes: list<int>, prefix: int, range: string, region: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({range: $range} | format pattern "/networking/ipv6/ranges/{range}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# VLANs List
#
# GET /networking/vlans
# operationId: getVLANs
export def "networking-vlans get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, label: string, linodes: list, region: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4beta")
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/networking/vlans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NodeBalancers List
#
# GET /nodebalancers
# operationId: getNodeBalancers
export def "nodebalancers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list, transfer: record, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nodebalancers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NodeBalancer Create
#
# POST /nodebalancers
# operationId: createNodeBalancer
# --configs item shape: {algorithm?: any, check?: any, check_attempts?: any, check_body?: any, check_interval?: any, check_passive?: any, check_path?: any, check_timeout?: any, cipher_suite?: any, nodes?: list, port?: any, protocol?: any, proxy_protocol?: any, ssl_cert?: any, ssl_key?: any, stickiness?: any}
export def "nodebalancers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-conn-throttle: any
  --configs: list # The port Config(s) to create for this NodeBalancer.  Each Config must have a unique port and at least one Node. — item shape: {algorithm?: any, check?: any, check_attempts?: any, check_body?: any, check_interval?: any, check_passive?: any, check_path?: any, check_timeout?: any, cipher_suite?: any, nodes?: list, port?: any, protocol?: any, proxy_protocol?: any, ssl_cert?: any, ssl_key?: any, stickiness?: any}
  --label: any
  region: string # The ID of the Region to create this NodeBalancer in.  (e.g. us-east)
]: any -> record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nodebalancers")
  let body = {"client_conn_throttle": $client_conn_throttle, "configs": $configs, "label": $label, "region": $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# NodeBalancer Delete
#
# DELETE /nodebalancers/{nodeBalancerId}
# operationId: deleteNodeBalancer
export def "nodebalancers delete" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id} | format pattern "/nodebalancers/{node_balancer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NodeBalancer View
#
# GET /nodebalancers/{nodeBalancerId}
# operationId: getNodeBalancer
export def "nodebalancers get" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id} | format pattern "/nodebalancers/{node_balancer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# NodeBalancer Update
#
# PUT /nodebalancers/{nodeBalancerId}
# operationId: updateNodeBalancer
export def "nodebalancers update" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-conn-throttle: int # Throttle connections per second.  Set to 0 (zero) to disable throttling.  (e.g. 0)
  --label: string # This NodeBalancer's label. These must be unique on your Account.  (e.g. balancer12345)
  --tags: list # An array of Tags applied to this object.  Tags are for organizational purposes only.  (e.g. [example tag, another example])
]: any -> record<client_conn_throttle: int, created: string, hostname: string, id: int, ipv4: string, ipv6: string, label: string, region: string, tags: list<string>, transfer: record<in: float, out: float, total: float>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id} | format pattern "/nodebalancers/{node_balancer_id}"))
  let body = {"client_conn_throttle": $client_conn_throttle, "label": $label, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configs List
#
# GET /nodebalancers/{nodeBalancerId}/configs
# operationId: getNodeBalancerConfigs
export def "nodebalancers-configs list" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id} | format pattern "/nodebalancers/{node_balancer_id}/configs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Config Create
#
# POST /nodebalancers/{nodeBalancerId}/configs
# operationId: createNodeBalancerConfig
export def "nodebalancers-configs create" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # What algorithm this NodeBalancer should use for routing traffic to backends.  (default: roundrobin, e.g. roundrobin)
  --check: string@check-completer # The type of check to perform against backends to ensure they are serving requests. This is used to determine if backends are up or down. * If `none` no check is performed. * `connection` requires only a connection to the backend to succeed. * `http` and `http_body` rely on the backend serving HTTP, and that   the response returned matches what is expected.  (default: none, e.g. http_body)
  --check-attempts: int # How many times to attempt a check before considering a backend to be down.  (default: 3, e.g. 3)
  --check-body: string # This value must be present in the response body of the check in order for it to pass. If this value is not present in the response body of a check request, the backend is considered to be down.  (e.g. it works)
  --check-interval: int # How often, in seconds, to check that backends are up and serving requests.  Must be greater than `check_timeout`.  (default: 31, e.g. 90)
  --check-passive: oneof<nothing, bool> # If true, any response from this backend with a `5xx` status code will be enough for it to be considered unhealthy and taken out of rotation.  (default: true, e.g. true)
  --check-path: string # The URL path to check on each backend. If the backend does not respond to this request it is considered to be down.  (e.g. /test)
  --check-timeout: int # How long, in seconds, to wait for a check attempt before considering it failed.  Must be less than `check_interval`.  (default: 30, e.g. 10)
  --cipher-suite: string@cipher-suite-completer # What ciphers to use for SSL connections served by this NodeBalancer.  * `legacy` is considered insecure and should only be used if necessary.  (default: recommended, e.g. recommended)
  --port: int # The port this Config is for. These values must be unique across configs on a single NodeBalancer (you can't have two configs for port 80, for example).  While some ports imply some protocols, no enforcement is done and you may configure your NodeBalancer however is useful to you. For example, while port 443 is generally used for HTTPS, you do not need SSL configured to have a NodeBalancer listening on port 443.  (default: 80, e.g. 80)
  --protocol: string@protocol-completer # The protocol this port is configured to serve.  * The `http` and `tcp` protocols do not support `ssl_cert` and `ssl_key`.  * The `https` protocol is mutually required with `ssl_cert` and `ssl_key`.  Review our guide on [Available Protocols](/docs/products/networking/nodebalancers/guides/protocols/) for information on protocol features.  (default: http, e.g. http)
  --proxy-protocol: string@proxy-protocol-completer # ProxyProtocol is a TCP extension that sends initial TCP connection information such as source/destination IPs and ports to backend devices. This information would be lost otherwise. Backend devices must be configured to work with ProxyProtocol if enabled.  * If ommited, or set to `none`, the NodeBalancer doesn't send any auxilary data over TCP connections. This is the default. * If set to `v1`, the human-readable header format (Version 1) is used. Requires `tcp` protocol. * If set to `v2`, the binary header format (Version 2) is used. Requires `tcp` protocol.  (default: none, e.g. none)
  --ssl-cert: string # The PEM-formatted public SSL certificate (or the combined PEM-formatted SSL certificate and Certificate Authority chain) that should be served on this NodeBalancerConfig's port.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI).  [Diffie-Hellman Parameters](/docs/products/networking/nodebalancers/guides/ssl-termination/#diffie-hellman-parameters) can be included in this value to enable forward secrecy.  The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `<REDACTED>` will be printed where the field appears.  The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig.  (nullable, format: ssl-cert, e.g. <REDACTED>)
  --ssl-key: string # The PEM-formatted private key for the SSL certificate set in the `ssl_cert` field.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI).  The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `<REDACTED>` will be printed where the field appears.  The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig.  (nullable, format: ssl-key, e.g. <REDACTED>)
  --stickiness: string@stickiness-completer # Controls how session stickiness is handled on this port. * If set to `none` connections will always be assigned a backend based on the algorithm configured. * If set to `table` sessions from the same remote address will be routed to the same   backend.  * For HTTP or HTTPS clients, `http_cookie` allows sessions to be   routed to the same backend based on a cookie set by the NodeBalancer.  (default: none, e.g. http_cookie)
]: any -> record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id} | format pattern "/nodebalancers/{node_balancer_id}/configs"))
  let body = {"algorithm": $algorithm, "check": $check, "check_attempts": $check_attempts, "check_body": $check_body, "check_interval": $check_interval, "check_passive": $check_passive, "check_path": $check_path, "check_timeout": $check_timeout, "cipher_suite": $cipher_suite, "port": $port, "protocol": $protocol, "proxy_protocol": $proxy_protocol, "ssl_cert": $ssl_cert, "ssl_key": $ssl_key, "stickiness": $stickiness} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Config Delete
#
# DELETE /nodebalancers/{nodeBalancerId}/configs/{configId}
# operationId: deleteNodeBalancerConfig
export def "nodebalancers-configs delete" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Config View
#
# GET /nodebalancers/{nodeBalancerId}/configs/{configId}
# operationId: getNodeBalancerConfig
export def "nodebalancers-configs get" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Config Update
#
# PUT /nodebalancers/{nodeBalancerId}/configs/{configId}
# operationId: updateNodeBalancerConfig
export def "nodebalancers-configs update" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # What algorithm this NodeBalancer should use for routing traffic to backends.  (default: roundrobin, e.g. roundrobin)
  --check: string@check-completer # The type of check to perform against backends to ensure they are serving requests. This is used to determine if backends are up or down. * If `none` no check is performed. * `connection` requires only a connection to the backend to succeed. * `http` and `http_body` rely on the backend serving HTTP, and that   the response returned matches what is expected.  (default: none, e.g. http_body)
  --check-attempts: int # How many times to attempt a check before considering a backend to be down.  (default: 3, e.g. 3)
  --check-body: string # This value must be present in the response body of the check in order for it to pass. If this value is not present in the response body of a check request, the backend is considered to be down.  (e.g. it works)
  --check-interval: int # How often, in seconds, to check that backends are up and serving requests.  Must be greater than `check_timeout`.  (default: 31, e.g. 90)
  --check-passive: oneof<nothing, bool> # If true, any response from this backend with a `5xx` status code will be enough for it to be considered unhealthy and taken out of rotation.  (default: true, e.g. true)
  --check-path: string # The URL path to check on each backend. If the backend does not respond to this request it is considered to be down.  (e.g. /test)
  --check-timeout: int # How long, in seconds, to wait for a check attempt before considering it failed.  Must be less than `check_interval`.  (default: 30, e.g. 10)
  --cipher-suite: string@cipher-suite-completer # What ciphers to use for SSL connections served by this NodeBalancer.  * `legacy` is considered insecure and should only be used if necessary.  (default: recommended, e.g. recommended)
  --port: int # The port this Config is for. These values must be unique across configs on a single NodeBalancer (you can't have two configs for port 80, for example).  While some ports imply some protocols, no enforcement is done and you may configure your NodeBalancer however is useful to you. For example, while port 443 is generally used for HTTPS, you do not need SSL configured to have a NodeBalancer listening on port 443.  (default: 80, e.g. 80)
  --protocol: string@protocol-completer # The protocol this port is configured to serve.  * The `http` and `tcp` protocols do not support `ssl_cert` and `ssl_key`.  * The `https` protocol is mutually required with `ssl_cert` and `ssl_key`.  Review our guide on [Available Protocols](/docs/products/networking/nodebalancers/guides/protocols/) for information on protocol features.  (default: http, e.g. http)
  --proxy-protocol: string@proxy-protocol-completer # ProxyProtocol is a TCP extension that sends initial TCP connection information such as source/destination IPs and ports to backend devices. This information would be lost otherwise. Backend devices must be configured to work with ProxyProtocol if enabled.  * If ommited, or set to `none`, the NodeBalancer doesn't send any auxilary data over TCP connections. This is the default. * If set to `v1`, the human-readable header format (Version 1) is used. Requires `tcp` protocol. * If set to `v2`, the binary header format (Version 2) is used. Requires `tcp` protocol.  (default: none, e.g. none)
  --ssl-cert: string # The PEM-formatted public SSL certificate (or the combined PEM-formatted SSL certificate and Certificate Authority chain) that should be served on this NodeBalancerConfig's port.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI).  [Diffie-Hellman Parameters](/docs/products/networking/nodebalancers/guides/ssl-termination/#diffie-hellman-parameters) can be included in this value to enable forward secrecy.  The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `<REDACTED>` will be printed where the field appears.  The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig.  (nullable, format: ssl-cert, e.g. <REDACTED>)
  --ssl-key: string # The PEM-formatted private key for the SSL certificate set in the `ssl_cert` field.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI).  The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `<REDACTED>` will be printed where the field appears.  The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig.  (nullable, format: ssl-key, e.g. <REDACTED>)
  --stickiness: string@stickiness-completer # Controls how session stickiness is handled on this port. * If set to `none` connections will always be assigned a backend based on the algorithm configured. * If set to `table` sessions from the same remote address will be routed to the same   backend.  * For HTTP or HTTPS clients, `http_cookie` allows sessions to be   routed to the same backend based on a cookie set by the NodeBalancer.  (default: none, e.g. http_cookie)
]: any -> record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}"))
  let body = {"algorithm": $algorithm, "check": $check, "check_attempts": $check_attempts, "check_body": $check_body, "check_interval": $check_interval, "check_passive": $check_passive, "check_path": $check_path, "check_timeout": $check_timeout, "cipher_suite": $cipher_suite, "port": $port, "protocol": $protocol, "proxy_protocol": $proxy_protocol, "ssl_cert": $ssl_cert, "ssl_key": $ssl_key, "stickiness": $stickiness} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Nodes List
#
# GET /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes
# operationId: getNodeBalancerConfigNodes
export def "nodebalancers-configs-nodes list" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}/nodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Create
#
# POST /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes
# operationId: createNodeBalancerNode
export def "nodebalancers-configs-nodes create" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The private IP Address where this backend can be reached. This _must_ be a private IP address.  (format: ip, e.g. 192.168.210.120:80)
  label: string # The label for this node.  This is for display purposes only.  (e.g. node54321)
  --mode: string@mode-completer # The mode this NodeBalancer should use when sending traffic to this backend. * If set to `accept` this backend is accepting traffic. * If set to `reject` this backend will not receive traffic. * If set to `drain` this backend will not receive _new_ traffic, but connections already   pinned to it will continue to be routed to it.  * If set to `backup`, this backend will only receive traffic if all `accept` nodes   are down.  (e.g. accept)
  --weight: int # Used when picking a backend to serve a request and is not pinned to a single backend yet.  Nodes with a higher weight will receive more traffic.  (e.g. 50)
]: any -> record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}/nodes"))
  let body = {"address": $address, "label": $label, "mode": $mode, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Node Delete
#
# DELETE /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}
# operationId: deleteNodeBalancerConfigNode
export def "nodebalancers-configs-nodes delete" [
  node_balancer_id: int
  config_id: int
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id, node_id: $node_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}/nodes/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node View
#
# GET /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}
# operationId: getNodeBalancerNode
export def "nodebalancers-configs-nodes get" [
  node_balancer_id: int
  config_id: int
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id, node_id: $node_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}/nodes/{node_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Node Update
#
# PUT /nodebalancers/{nodeBalancerId}/configs/{configId}/nodes/{nodeId}
# operationId: updateNodeBalancerNode
export def "nodebalancers-configs-nodes update" [
  node_balancer_id: int
  config_id: int
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The private IP Address where this backend can be reached. This _must_ be a private IP address.  (format: ip, e.g. 192.168.210.120:80)
  --label: string # The label for this node.  This is for display purposes only.  (e.g. node54321)
  --mode: string@mode-completer # The mode this NodeBalancer should use when sending traffic to this backend. * If set to `accept` this backend is accepting traffic. * If set to `reject` this backend will not receive traffic. * If set to `drain` this backend will not receive _new_ traffic, but connections already   pinned to it will continue to be routed to it.  * If set to `backup`, this backend will only receive traffic if all `accept` nodes   are down.  (e.g. accept)
  --weight: int # Used when picking a backend to serve a request and is not pinned to a single backend yet.  Nodes with a higher weight will receive more traffic.  (e.g. 50)
]: any -> record<address: string, config_id: int, id: int, label: string, mode: string, nodebalancer_id: int, status: string, weight: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id, node_id: $node_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}/nodes/{node_id}"))
  let body = {"address": $address, "label": $label, "mode": $mode, "weight": $weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Config Rebuild
#
# POST /nodebalancers/{nodeBalancerId}/configs/{configId}/rebuild
# operationId: rebuildNodeBalancerConfig
# --nodes item shape: {address?: any, id?: int, label?: any, mode?: any, weight?: any}
export def "nodebalancers-configs-rebuild rebuildNodeBalancerConfig" [
  node_balancer_id: int
  config_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # What algorithm this NodeBalancer should use for routing traffic to backends.  (default: roundrobin, e.g. roundrobin)
  --check: string@check-completer # The type of check to perform against backends to ensure they are serving requests. This is used to determine if backends are up or down. * If `none` no check is performed. * `connection` requires only a connection to the backend to succeed. * `http` and `http_body` rely on the backend serving HTTP, and that   the response returned matches what is expected.  (default: none, e.g. http_body)
  --check-attempts: int # How many times to attempt a check before considering a backend to be down.  (default: 3, e.g. 3)
  --check-body: string # This value must be present in the response body of the check in order for it to pass. If this value is not present in the response body of a check request, the backend is considered to be down.  (e.g. it works)
  --check-interval: int # How often, in seconds, to check that backends are up and serving requests.  Must be greater than `check_timeout`.  (default: 31, e.g. 90)
  --check-passive: oneof<nothing, bool> # If true, any response from this backend with a `5xx` status code will be enough for it to be considered unhealthy and taken out of rotation.  (default: true, e.g. true)
  --check-path: string # The URL path to check on each backend. If the backend does not respond to this request it is considered to be down.  (e.g. /test)
  --check-timeout: int # How long, in seconds, to wait for a check attempt before considering it failed.  Must be less than `check_interval`.  (default: 30, e.g. 10)
  --cipher-suite: string@cipher-suite-completer # What ciphers to use for SSL connections served by this NodeBalancer.  * `legacy` is considered insecure and should only be used if necessary.  (default: recommended, e.g. recommended)
  --port: int # The port this Config is for. These values must be unique across configs on a single NodeBalancer (you can't have two configs for port 80, for example).  While some ports imply some protocols, no enforcement is done and you may configure your NodeBalancer however is useful to you. For example, while port 443 is generally used for HTTPS, you do not need SSL configured to have a NodeBalancer listening on port 443.  (default: 80, e.g. 80)
  --protocol: string@protocol-completer # The protocol this port is configured to serve.  * The `http` and `tcp` protocols do not support `ssl_cert` and `ssl_key`.  * The `https` protocol is mutually required with `ssl_cert` and `ssl_key`.  Review our guide on [Available Protocols](/docs/products/networking/nodebalancers/guides/protocols/) for information on protocol features.  (default: http, e.g. http)
  --proxy-protocol: string@proxy-protocol-completer # ProxyProtocol is a TCP extension that sends initial TCP connection information such as source/destination IPs and ports to backend devices. This information would be lost otherwise. Backend devices must be configured to work with ProxyProtocol if enabled.  * If ommited, or set to `none`, the NodeBalancer doesn't send any auxilary data over TCP connections. This is the default. * If set to `v1`, the human-readable header format (Version 1) is used. Requires `tcp` protocol. * If set to `v2`, the binary header format (Version 2) is used. Requires `tcp` protocol.  (default: none, e.g. none)
  --ssl-cert: string # The PEM-formatted public SSL certificate (or the combined PEM-formatted SSL certificate and Certificate Authority chain) that should be served on this NodeBalancerConfig's port.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI).  [Diffie-Hellman Parameters](/docs/products/networking/nodebalancers/guides/ssl-termination/#diffie-hellman-parameters) can be included in this value to enable forward secrecy.  The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `<REDACTED>` will be printed where the field appears.  The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig.  (nullable, format: ssl-cert, e.g. <REDACTED>)
  --ssl-key: string # The PEM-formatted private key for the SSL certificate set in the `ssl_cert` field.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI).  The contents of this field will not be shown in any responses that display the NodeBalancerConfig. Instead, `<REDACTED>` will be printed where the field appears.  The read-only `ssl_commonname` and `ssl_fingerprint` fields in a NodeBalancerConfig response are automatically derived from your certificate. Please refer to these fields to verify that the appropriate certificate was assigned to your NodeBalancerConfig.  (nullable, format: ssl-key, e.g. <REDACTED>)
  --stickiness: string@stickiness-completer # Controls how session stickiness is handled on this port. * If set to `none` connections will always be assigned a backend based on the algorithm configured. * If set to `table` sessions from the same remote address will be routed to the same   backend.  * For HTTP or HTTPS clients, `http_cookie` allows sessions to be   routed to the same backend based on a cookie set by the NodeBalancer.  (default: none, e.g. http_cookie)
  nodes: list # The NodeBalancer Node(s) that serve this Config.  Some considerations for Nodes when rebuilding a config:   * Current Nodes excluded from the request body will be deleted from the Config.   * Current Nodes (identified by their Node ID) will be updated.   * New Nodes (included without a Node ID) will be created. — item shape: {address?: any, id?: int, label?: any, mode?: any, weight?: any}
]: any -> record<algorithm: string, check: string, check_attempts: int, check_body: string, check_interval: int, check_passive: bool, check_path: string, check_timeout: int, cipher_suite: string, id: int, nodebalancer_id: int, nodes_status: record<down: int, up: int>, port: int, protocol: string, proxy_protocol: string, ssl_cert: string, ssl_commonname: string, ssl_fingerprint: string, ssl_key: string, stickiness: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id, config_id: $config_id} | format pattern "/nodebalancers/{node_balancer_id}/configs/{config_id}/rebuild"))
  let body = {"algorithm": $algorithm, "check": $check, "check_attempts": $check_attempts, "check_body": $check_body, "check_interval": $check_interval, "check_passive": $check_passive, "check_path": $check_path, "check_timeout": $check_timeout, "cipher_suite": $cipher_suite, "port": $port, "protocol": $protocol, "proxy_protocol": $proxy_protocol, "ssl_cert": $ssl_cert, "ssl_key": $ssl_key, "stickiness": $stickiness, "nodes": $nodes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# NodeBalancer Statistics View
#
# GET /nodebalancers/{nodeBalancerId}/stats
export def "nodebalancers-stats get" [
  node_balancer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<connections: list<float>, traffic: record<in: list, out: list>>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_balancer_id: $node_balancer_id} | format pattern "/nodebalancers/{node_balancer_id}/stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Buckets List
#
# GET /object-storage/buckets
# operationId: getObjectStorageBuckets
export def "object-storage-buckets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/buckets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Bucket Create
#
# POST /object-storage/buckets
# operationId: createObjectStorageBucket
export def "object-storage-buckets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: string@acl-completer # The Access Control Level of the bucket using a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly.  (default: private, e.g. private)
  cluster: string # The ID of the Object Storage Cluster where this bucket should be created.  (e.g. us-east-1)
  --cors-enabled: oneof<nothing, bool> # If true, the bucket will be created with CORS enabled for all origins. For more fine-grained controls of CORS, use the S3 API directly.  (default: false, e.g. true)
  label: string # The name for this bucket. Must be unique in the cluster you are creating the bucket in, or an error will be returned. Labels will be reserved only for the cluster that active buckets are created and stored in. If you want to reserve this bucket's label in another cluster, you must create a new bucket with the same label in the new cluster.  (e.g. example-bucket)
]: any -> record<cluster: string, created: string, hostname: string, label: string, objects: int, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/buckets")
  let body = {"acl": $acl, "cluster": $cluster, "cors_enabled": $cors_enabled, "label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Buckets in Cluster List
#
# GET /object-storage/buckets/{clusterId}
# operationId: getObjectStorageBucketinCluster
export def "object-storage-buckets get-object-storage-bucketin-cluster" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<cluster: string, created: string, hostname: string, label: string, objects: int, size: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/object-storage/buckets/{cluster_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Bucket Remove
#
# DELETE /object-storage/buckets/{clusterId}/{bucket}
# operationId: deleteObjectStorageBucket
export def "object-storage-buckets delete" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Bucket View
#
# GET /object-storage/buckets/{clusterId}/{bucket}
# operationId: getObjectStorageBucket
export def "object-storage-buckets get-by-clusterId-bucket" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cluster: string, created: string, hostname: string, label: string, objects: int, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Bucket Access Modify
#
# POST /object-storage/buckets/{clusterId}/{bucket}/access
# operationId: modifyObjectStorageBucketAccess
export def "object-storage-buckets-access modifyObjectStorageBucketAccess" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: string@acl-completer-1 # The Access Control Level of the bucket, as a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly.  (e.g. private)
  --cors-enabled: oneof<nothing, bool> # If true, the bucket will be created with CORS enabled for all origins. For more fine-grained controls of CORS, use the S3 API directly.  (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/access"))
  let body = {"acl": $acl, "cors_enabled": $cors_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Bucket Access Update
#
# PUT /object-storage/buckets/{clusterId}/{bucket}/access
# operationId: updateObjectStorageBucketAccess
export def "object-storage-buckets-access update" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acl: string@acl-completer-1 # The Access Control Level of the bucket, as a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly.  (e.g. private)
  --cors-enabled: oneof<nothing, bool> # If true, the bucket will be created with CORS enabled for all origins. For more fine-grained controls of CORS, use the S3 API directly.  (e.g. true)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/access"))
  let body = {"acl": $acl, "cors_enabled": $cors_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Object ACL Config View
#
# GET /object-storage/buckets/{clusterId}/{bucket}/object-acl
# operationId: viewObjectStorageBucketACL
export def "object-storage-buckets-object-acl viewObjectStorageBucketACL" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The `name` of the object for which to retrieve its Access Control List (ACL). Use the [Object Storage Bucket Contents List](/docs/api/object-storage/#object-storage-bucket-contents-list) endpoint to access all object names in a bucket.
]: nothing -> record<acl: string, acl_xml: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/object-acl") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Object ACL Config Update
#
# PUT /object-storage/buckets/{clusterId}/{bucket}/object-acl
# operationId: updateObjectStorageBucketACL
export def "object-storage-buckets-object-acl update" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: string@acl-completer-1 # The Access Control Level of the bucket, as a canned ACL string. For more fine-grained control of ACLs, use the S3 API directly.  (e.g. public-read)
  name: string # The `name` of the object for which to update its Access Control List (ACL). Use the [Object Storage Bucket Contents List](/docs/api/object-storage/#object-storage-bucket-contents-list) endpoint to access all object names in a bucket.
]: any -> record<acl: string, acl_xml: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/object-acl"))
  let body = {"acl": $acl, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Bucket Contents List
#
# GET /object-storage/buckets/{clusterId}/{bucket}/object-list
# operationId: getObjectStorageBucketContent
export def "object-storage-buckets-object-list get-object-storage-content" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marker: string # The "marker" for this request, which can be used to paginate through large buckets. Its value should be the value of the `next_marker` property returned with the last page. Listing bucket contents *does not* support arbitrary page access. See the `next_marker` property in the responses section for more details.
  --delimiter: string # The delimiter for object names; if given, object names will be returned up to the first occurrence of this character. This is most commonly used with the `/` character to allow bucket transversal in a manner similar to a filesystem, however any delimiter may be used. Use in conjunction with `prefix` to see object names past the first occurrence of the delimiter.
  --prefix: string # Filters objects returned to only those whose name start with the given prefix. Commonly used in conjunction with `delimiter` to allow transversal of bucket contents in a manner similar to a filesystem.
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<etag: string, is_truncated: bool, last_modified: string, name: string, next_marker: string, owner: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let qp = [(serialize-qp "marker" $marker "scalar") (serialize-qp "delimiter" $delimiter "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/object-list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Object URL Create
#
# POST /object-storage/buckets/{clusterId}/{bucket}/object-url
# operationId: createObjectStorageObjectURL
export def "object-storage-buckets-object-url create" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # The expected `Content-type` header of the request this signed URL will be valid for.  If provided, the `Content-type` header _must_ be sent with the request when this URL is used, and _must_ be the same as it was when the signed URL was created. Required for all methods *except* "GET" or "DELETE".
  --expires-in: int # How long this signed URL will be valid for, in seconds.  If omitted, the URL will be valid for 3600 seconds (1 hour).  (default: 3600)
  method: string # The HTTP method allowed to be used with the pre-signed URL. (default: GET, e.g. GET)
  name: string # The name of the object that will be accessed with the pre-signed URL. This object need not exist, and no error will be returned if it doesn't. This behavior is useful for generating pre-signed URLs to upload new objects to by setting the `method` to "PUT".  (e.g. example)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/object-url"))
  let body = {"content_type": $content_type, "expires_in": $expires_in, "method": $method, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage TLS/SSL Cert Delete
#
# DELETE /object-storage/buckets/{clusterId}/{bucket}/ssl
# operationId: deleteObjectStorageSSL
export def "object-storage-buckets-ssl delete" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/ssl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage TLS/SSL Cert View
#
# GET /object-storage/buckets/{clusterId}/{bucket}/ssl
# operationId: getObjectStorageSSL
export def "object-storage-buckets-ssl get" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ssl: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/ssl"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage TLS/SSL Cert Upload
#
# POST /object-storage/buckets/{clusterId}/{bucket}/ssl
# operationId: createObjectStorageSSL
export def "object-storage-buckets-ssl create" [
  cluster_id: string
  bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  certificate: string # Your Base64 encoded and PEM formatted SSL certificate.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI)  (e.g. -----BEGIN CERTIFICATE----- CERTIFICATE_INFORMATION -----END CERTIFICATE-----)
  private_key: string # The private key associated with this TLS/SSL certificate.  Line breaks must be represented as "\n" in the string for requests (but not when using the Linode CLI)  (e.g. -----BEGIN PRIVATE KEY----- PRIVATE_KEY_INFORMATION -----END PRIVATE KEY-----)
]: any -> record<ssl: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id, bucket: $bucket} | format pattern "/object-storage/buckets/{cluster_id}/{bucket}/ssl"))
  let body = {"certificate": $certificate, "private_key": $private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Cancel
#
# POST /object-storage/cancel
# operationId: cancelObjectStorage
export def "object-storage-cancel cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clusters List
#
# GET /object-storage/clusters
# operationId: getObjectStorageClusters
export def "object-storage-clusters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<domain: string, id: string, region: string, static_site_domain: string, status: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/clusters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cluster View
#
# GET /object-storage/clusters/{clusterId}
# operationId: getObjectStorageCluster
export def "object-storage-clusters get" [
  cluster_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, id: string, region: string, static_site_domain: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({cluster_id: $cluster_id} | format pattern "/object-storage/clusters/{cluster_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Keys List
#
# GET /object-storage/keys
# operationId: getObjectStorageKeys
export def "object-storage-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<access_key: string, bucket_access: list, id: int, label: string, limited: bool, secret_key: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Key Create
#
# POST /object-storage/keys
# operationId: createObjectStorageKeys
# --bucket_access item shape: {bucket_name?: string, cluster?: string, permissions?: "read_write"|"read_only"}
export def "object-storage-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bucket-access: list # Defines this key as a Limited Access Key. Limited Access Keys restrict this Object Storage key's access to only the bucket(s) declared in this array and define their bucket-level permissions.     Limited Access Keys can:    * [list all buckets](/docs/api/object-storage/#object-storage-buckets-list) available on this Account, but cannot perform any actions on a bucket unless it has access to the bucket.     * [create new buckets](/docs/api/object-storage/#object-storage-bucket-create), but do not have any access to the buckets it creates, unless explicitly given access to them.     **Note:** You can create an Object Storage Limited Access Key without access to any buckets.   This is achieved by sending a request with an empty `bucket_access` array.     **Note:** If this field is omitted, a regular unlimited access key is issued. — item shape: {bucket_name?: string, cluster?: string, permissions?: "read_write"|"read_only"}
  --label: string # The label given to this key. For display purposes only. (e.g. my-key)
]: any -> record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/keys")
  let body = {"bucket_access": $bucket_access, "label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Key Revoke
#
# DELETE /object-storage/keys/{keyId}
# operationId: deleteObjectStorageKey
export def "object-storage-keys delete" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({key_id: $key_id} | format pattern "/object-storage/keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Key View
#
# GET /object-storage/keys/{keyId}
# operationId: getObjectStorageKey
export def "object-storage-keys get" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({key_id: $key_id} | format pattern "/object-storage/keys/{key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Object Storage Key Update
#
# PUT /object-storage/keys/{keyId}
# operationId: updateObjectStorageKey
export def "object-storage-keys update" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The label for this keypair, for display purposes only. (e.g. my-key)
]: any -> record<access_key: string, bucket_access: table<bucket_name: string, cluster: string, permissions: string>, id: int, label: string, limited: bool, secret_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base ({key_id: $key_id} | format pattern "/object-storage/keys/{key_id}"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Object Storage Transfer View
#
# GET /object-storage/transfer
# operationId: getObjectStorageTransfer
export def "object-storage-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<used: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/object-storage/transfer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Profile View
#
# GET /profile
# operationId: getProfile
export def "profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authentication_type: string, authorized_keys: list<string>, email: string, email_notifications: bool, ip_whitelist_enabled: bool, lish_auth_method: string, referrals: record<code: string, completed: int, credit: int, pending: int, total: int, url: string>, restricted: bool, timezone: string, two_factor_auth: bool, uid: int, username: string, verified_phone_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Profile Update
#
# PUT /profile
# operationId: updateProfile
@deprecated --flag ip-whitelist-enabled
export def "profile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorized-keys: list # The list of SSH Keys authorized to use Lish for your User. This value is ignored if `lish_auth_method` is "disabled."  (nullable)
  --email: string # Your email address.  This address will be used for communication with Linode as necessary.  (format: email, e.g. example-user@gmail.com)
  --email-notifications: oneof<nothing, bool> # If true, you will receive email notifications about account activity.  If false, you may still receive business-critical communications through email.  (e.g. true)
  --ip-whitelist-enabled: oneof<nothing, bool> # If true, logins for your User will only be allowed from whitelisted IPs. This setting is currently deprecated, and cannot be enabled.  If you disable this setting, you will not be able to re-enable it.  (DEPRECATED, e.g. false)
  --lish-auth-method: string@lish-auth-method-completer # The authentication methods that are allowed when connecting to [the Linode Shell (Lish)](/docs/guides/lish/). * `keys_only` is the most secure if you intend to use Lish. * `disabled` is recommended if you do not intend to use Lish at all. * If this account's Cloud Manager authentication type is set to a Third-Party Authentication method, `password_keys` cannot be used as your Lish authentication method. To view this account's Cloud Manager `authentication_type` field, send a request to the [View Profile](/docs/api/profile/#profile-view) endpoint.  (e.g. keys_only)
  --restricted: oneof<nothing, bool> # If true, your User has restrictions on what can be accessed on your Account. To get details on what entities/actions you can access/perform, see [/profile/grants](/docs/api/profile/#grants-list).  (e.g. false)
  --timezone: string # The timezone you prefer to see times in. This is not used by the API directly. It is provided for the benefit of clients such as the Linode Cloud Manager and other clients built on the API. All times returned by the API are in UTC.  (e.g. US/Eastern)
  --two-factor-auth: oneof<nothing, bool> # If true, logins from untrusted computers will require Two Factor Authentication.  See [/profile/tfa-enable](/docs/api/profile/#two-factor-secret-create) to enable Two Factor Authentication.  (e.g. true)
]: any -> record<authentication_type: string, authorized_keys: list<string>, email: string, email_notifications: bool, ip_whitelist_enabled: bool, lish_auth_method: string, referrals: record<code: string, completed: int, credit: int, pending: int, total: int, url: string>, restricted: bool, timezone: string, two_factor_auth: bool, uid: int, username: string, verified_phone_number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let body = {"authorized_keys": $authorized_keys, "email": $email, "email_notifications": $email_notifications, "ip_whitelist_enabled": $ip_whitelist_enabled, "lish_auth_method": $lish_auth_method, "restricted": $restricted, "timezone": $timezone, "two_factor_auth": $two_factor_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorized Apps List
#
# GET /profile/apps
# operationId: getProfileApps
export def "profile-apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, expiry: string, id: int, label: string, scopes: string, thumbnail_url: string, website: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profile/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# App Access Revoke
#
# DELETE /profile/apps/{appId}
# operationId: deleteProfileApp
export def "profile-apps delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: $app_id} | format pattern "/profile/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authorized App View
#
# GET /profile/apps/{appId}
# operationId: getProfileApp
export def "profile-apps get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, expiry: string, id: int, label: string, scopes: string, thumbnail_url: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: $app_id} | format pattern "/profile/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trusted Devices List
#
# GET /profile/devices
# operationId: getDevices
export def "profile-devices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, expiry: string, id: int, last_authenticated: string, last_remote_addr: string, user_agent: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/devices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trusted Device Revoke
#
# DELETE /profile/devices/{deviceId}
# operationId: revokeTrustedDevice
export def "profile-devices delete-trusted" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/profile/devices/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trusted Device View
#
# GET /profile/devices/{deviceId}
# operationId: getTrustedDevice
export def "profile-devices get-trusted" [
  device_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, expiry: string, id: int, last_authenticated: string, last_remote_addr: string, user_agent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/profile/devices/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Grants List
#
# GET /profile/grants
# operationId: getProfileGrants
export def "profile-grants get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<database: table<id: int, label: string, permissions: string>, domain: table<id: int, label: string, permissions: string>, global: record<account_access: string, add_databases: bool, add_domains: bool, add_firewalls: bool, add_images: bool, add_linodes: bool, add_longview: bool, add_nodebalancers: bool, add_stackscripts: bool, add_volumes: bool, cancel_account: bool, longview_subscription: bool>, image: table<id: int, label: string, permissions: string>, linode: table<id: int, label: string, permissions: string>, longview: table<id: int, label: string, permissions: string>, nodebalancer: table<id: int, label: string, permissions: string>, stackscript: table<id: int, label: string, permissions: string>, volume: table<id: int, label: string, permissions: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/grants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logins List
#
# GET /profile/logins
# operationId: getProfileLogins
export def "profile-logins list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<datetime: string, id: int, ip: string, restricted: bool, username: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/logins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login View
#
# GET /profile/logins/{loginId}
# operationId: getProfileLogin
export def "profile-logins get" [
  login_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<datetime: string, id: int, ip: string, restricted: bool, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({login_id: $login_id} | format pattern "/profile/logins/{login_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Phone Number Delete
#
# DELETE /profile/phone-number
# operationId: deleteProfilePhoneNumber
export def "profile-phone-number delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/phone-number")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Phone Number Verification Code Send
#
# POST /profile/phone-number
# operationId: postProfilePhoneNumber
export def "profile-phone-number create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  iso_code: string # The two-letter ISO 3166 country code associated with the phone number. (e.g. US)
  phone_number: string # A valid phone number. (format: phone, e.g. 555-555-5555)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/phone-number")
  let body = {"iso_code": $iso_code, "phone_number": $phone_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Phone Number Verify
#
# POST /profile/phone-number/verify
# operationId: postProfilePhoneNumberVerify
export def "profile-phone-number-verify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  otp_code: string # The one-time code received via SMS message after accessing the **Phone Verification Code Send** ([POST /profile/phone-number](/docs/api/profile/#phone-number-verification-code-send)) command. (e.g. US)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/phone-number/verify")
  let body = {"otp_code": $otp_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# User Preferences View
#
# GET /profile/preferences
# operationId: getUserPreferences
export def "profile-preferences get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User Preferences Update
#
# PUT /profile/preferences
# operationId: updateUserPreferences
export def "profile-preferences update-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/preferences")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Security Questions List
#
# GET /profile/security-questions
# operationId: getSecurityQuestions
export def "profile-security-questions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<security_questions: table<id: any, question: any, response: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api.linode.com/v4")
  let full_url = (build-url $base "/profile/security-questions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Security Questions Answer
#
# POST /profile/security-questions
# operationId: postSecurityQuestions
# --security_questions item shape: {question_id?: any, response?: any, security_question?: any}
export def "profile-security-questions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --security-questions: list # item shape: {question_id?: any, response?: any, security_question?: any}
]: any -> record<security_questions: table<question_id: any, response: any, security_question: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/security-questions")
  let body = {"security_questions": $security_questions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SSH Keys List
#
# GET /profile/sshkeys
# operationId: getSSHKeys
export def "profile-sshkeys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, id: int, label: string, ssh_key: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/profile/sshkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SSH Key Add
#
# POST /profile/sshkeys
# operationId: addSSHKey
export def "profile-sshkeys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # A label for the SSH Key.  (e.g. My SSH Key)
  --ssh-key: string # The public SSH Key, which is used to authenticate to the root user of the Linodes you deploy.  Accepted formats: * ssh-dss * ssh-rsa * ecdsa-sha2-nistp * ssh-ed25519 * sk-ecdsa-sha2-nistp256 (Akamai-specific)  (format: ssh-key, e.g. ssh-rsa AAAA_valid_public_ssh_key_123456785== user@their-computer)
]: any -> record<created: string, id: int, label: string, ssh_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/sshkeys")
  let body = {"label": $label, "ssh_key": $ssh_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SSH Key Delete
#
# DELETE /profile/sshkeys/{sshKeyId}
# operationId: deleteSSHKey
export def "profile-sshkeys delete" [
  ssh_key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ssh_key_id: $ssh_key_id} | format pattern "/profile/sshkeys/{ssh_key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SSH Key View
#
# GET /profile/sshkeys/{sshKeyId}
# operationId: getSSHKey
export def "profile-sshkeys get" [
  ssh_key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, id: int, label: string, ssh_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ssh_key_id: $ssh_key_id} | format pattern "/profile/sshkeys/{ssh_key_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SSH Key Update
#
# PUT /profile/sshkeys/{sshKeyId}
# operationId: updateSSHKey
export def "profile-sshkeys update" [
  ssh_key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: any
]: any -> record<created: string, id: int, label: string, ssh_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ssh_key_id: $ssh_key_id} | format pattern "/profile/sshkeys/{ssh_key_id}"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Two Factor Authentication Disable
#
# POST /profile/tfa-disable
# operationId: tfaDisable
export def "profile-tfa-disable tfaDisable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/tfa-disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Two Factor Secret Create
#
# POST /profile/tfa-enable
# operationId: tfaEnable
export def "profile-tfa-enable tfaEnable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<expiry: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/tfa-enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Two Factor Authentication Confirm/Enable
#
# POST /profile/tfa-enable-confirm
# operationId: tfaConfirm
export def "profile-tfa-enable-confirm tfaConfirm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tfa-code: string # The Two Factor code you generated with your Two Factor secret. These codes are time-based, so be sure it is current.  (e.g. 213456)
]: any -> record<scratch: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/tfa-enable-confirm")
  let body = {"tfa_code": $tfa_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Personal Access Tokens List
#
# GET /profile/tokens
# operationId: getPersonalAccessTokens
export def "profile-tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, expiry: string, id: int, label: string, scopes: string, token: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Personal Access Token Create
#
# POST /profile/tokens
# operationId: createPersonalAccessToken
export def "profile-tokens create-personal-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry: string # When this token should be valid until.  If omitted, the new token will be valid until it is manually revoked.  (format: date-time)
  --label: any
  --scopes: string # The scopes to create the token with.  These cannot be changed after creation, and may not exceed the scopes of the acting token. If omitted, the new token will have the same scopes as the acting token.  (format: oauth-scope, e.g. *)
]: any -> record<created: string, expiry: string, id: int, label: string, scopes: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/tokens")
  let body = {"expiry": $expiry, "label": $label, "scopes": $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Personal Access Token Revoke
#
# DELETE /profile/tokens/{tokenId}
# operationId: deletePersonalAccessToken
export def "profile-tokens delete-personal-access" [
  token_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_id: $token_id} | format pattern "/profile/tokens/{token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Personal Access Token View
#
# GET /profile/tokens/{tokenId}
# operationId: getPersonalAccessToken
export def "profile-tokens get-personal-access" [
  token_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, expiry: string, id: int, label: string, scopes: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_id: $token_id} | format pattern "/profile/tokens/{token_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Personal Access Token Update
#
# PUT /profile/tokens/{tokenId}
# operationId: updatePersonalAccessToken
export def "profile-tokens update-personal-access" [
  token_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # This token's label.  This is for display purposes only, but can be used to more easily track what you're using each token for.  (e.g. linode-cli)
]: any -> record<created: string, expiry: string, id: int, label: string, scopes: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_id: $token_id} | format pattern "/profile/tokens/{token_id}"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Regions List
#
# GET /regions
# operationId: getRegions
export def "regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<capabilities: list, country: string, id: string, label: string, resolvers: record, status: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Region View
#
# GET /regions/{regionId}
# operationId: getRegion
export def "regions get" [
  region_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<capabilities: list<string>, country: string, id: string, label: string, resolvers: record<ipv4: string, ipv6: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({region_id: $region_id} | format pattern "/regions/{region_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Support Tickets List
#
# GET /support/tickets
# operationId: getTickets
export def "support-tickets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<attachments: list, closable: bool, closed: string, description: string, entity: record, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/support/tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Support Ticket Open
#
# POST /support/tickets
# operationId: createTicket
export def "support-tickets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --database-id: int # The ID of the Managed Database this ticket is regarding, if relevant.
  description: string # The full details of the issue or question.  (e.g. I'm having trouble setting the root password on my Linode. I tried following the instructions but something is not working and I'm not sure what I'm doing wrong. Can you please help me figure out how I can reset it? )
  --domain-id: int # The ID of the Domain this ticket is regarding, if relevant.
  --firewall-id: int # The ID of the Firewall this ticket is regarding, if relevant.
  --linode-id: int # The ID of the Linode this ticket is regarding, if relevant.  (e.g. 123)
  --lkecluster-id: int # The ID of the Kubernetes cluster this ticket is regarding, if relevant.  (e.g. 123)
  --longviewclient-id: int # The ID of the Longview client this ticket is regarding, if relevant.
  --managed-issue: oneof<nothing, bool> # Designates if this ticket is related to a [Managed service](https://www.linode.com/products/managed/). If `true`, the following constraints will apply: * No ID attributes (i.e. `linode_id`, `domain_id`, etc.) should be provided with this request. * Your account must have a [Managed service enabled](/docs/api/managed/#managed-service-enable).  (e.g. false)
  --nodebalancer-id: int # The ID of the NodeBalancer this ticket is regarding, if relevant.
  --region: string # The [Region](/docs/api/regions/) ID for the associated VLAN this ticket is regarding.  Only allowed when submitting a VLAN ticket.
  summary: string # The summary or title for this SupportTicket.  (e.g. Having trouble resetting root password on my Linode )
  --vlan: string # The label of the VLAN this ticket is regarding, if relevant. To view your VLANs, use the VLANs List ([GET /networking/vlans](/docs/api/networking/#vlans-list)) endpoint.  Requires a specified `region` to identify the VLAN.
  --volume-id: int # The ID of the Volume this ticket is regarding, if relevant.
]: any -> record<attachments: list<string>, closable: bool, closed: string, description: string, entity: record<id: int, label: string, type: string, url: string>, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/support/tickets")
  let body = {"database_id": $database_id, "description": $description, "domain_id": $domain_id, "firewall_id": $firewall_id, "linode_id": $linode_id, "lkecluster_id": $lkecluster_id, "longviewclient_id": $longviewclient_id, "managed_issue": $managed_issue, "nodebalancer_id": $nodebalancer_id, "region": $region, "summary": $summary, "vlan": $vlan, "volume_id": $volume_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Support Ticket View
#
# GET /support/tickets/{ticketId}
# operationId: getTicket
export def "support-tickets get" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<string>, closable: bool, closed: string, description: string, entity: record<id: int, label: string, type: string, url: string>, gravatar_id: string, id: int, opened: string, opened_by: string, status: string, summary: string, updated: string, updated_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ticket_id: $ticket_id} | format pattern "/support/tickets/{ticket_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Support Ticket Attachment Create
#
# POST /support/tickets/{ticketId}/attachments
# operationId: createTicketAttachment
export def "support-tickets-attachments create" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The local, absolute path to the file you want to attach to your Support Ticket.  (e.g. /Users/LinodeGuy/pictures/screen_shot.jpg)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ticket_id: $ticket_id} | format pattern "/support/tickets/{ticket_id}/attachments"))
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Support Ticket Close
#
# POST /support/tickets/{ticketId}/close
# operationId: closeTicket
export def "support-tickets-close close" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ticket_id: $ticket_id} | format pattern "/support/tickets/{ticket_id}/close"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replies List
#
# GET /support/tickets/{ticketId}/replies
# operationId: getTicketReplies
export def "support-tickets-replies get" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, created_by: string, description: string, from_linode: bool, gravatar_id: string, id: int>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ticket_id: $ticket_id} | format pattern "/support/tickets/{ticket_id}/replies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reply Create
#
# POST /support/tickets/{ticketId}/replies
# operationId: createTicketReply
export def "support-tickets-replies create-ticket-reply" [
  ticket_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # The content of your reply.  (e.g. Thank you for your help. I was able to figure out what the problem was and I successfully reset my password. You guys are the best! )
]: any -> record<created: string, created_by: string, description: string, from_linode: bool, gravatar_id: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ticket_id: $ticket_id} | format pattern "/support/tickets/{ticket_id}/replies"))
  let body = {"description": $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tags List
#
# GET /tags
# operationId: getTags
export def "tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<label: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# New Tag Create
#
# POST /tags
# operationId: createTag
export def "tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domains: list # A list of Domain IDs to apply the new Tag to.  You must be allowed to `read_write` all of the requested Domains, or the Tag will not be created and an error will be returned.  (e.g. [564, 565])
  label: string # The new Tag.  (e.g. example tag)
  --linodes: list # A list of Linode IDs to apply the new Tag to.  You must be allowed to `read_write` all of the requested Linodes, or the Tag will not be created and an error will be returned.  (e.g. [123, 456])
  --nodebalancers: list # A list of NodeBalancer IDs to apply the new Tag to. You must be allowed to `read_write` all of the requested NodeBalancers, or the Tag will not be created and an error will be returned.  (e.g. [10301, 10501])
  --volumes: list # A list of Volume IDs to apply the new Tag to.  You must be allowed to `read_write` all of the requested Volumes, or the Tag will not be created and an error will be returned.  (e.g. [9082, 10003])
]: any -> record<label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {"domains": $domains, "label": $label, "linodes": $linodes, "nodebalancers": $nodebalancers, "volumes": $volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tag Delete
#
# DELETE /tags/{label}
# operationId: deleteTag
export def "tags delete" [
  label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({label: $label} | format pattern "/tags/{label}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tagged Objects List
#
# GET /tags/{label}
# operationId: getTaggedObjects
export def "tags get-tagged-objects" [
  label: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<data: any, type: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({label: $label} | format pattern "/tags/{label}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Volumes List
#
# GET /volumes
# operationId: getVolumes
export def "volumes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<data: table<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list, updated: string>, page: any, pages: any, results: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Volume Create
#
# POST /volumes
# operationId: createVolume
export def "volumes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # When creating a Volume attached to a Linode, the ID of the Linode Config to include the new Volume in. This Config must belong to the Linode referenced by `linode_id`. Must _not_ be provided if `linode_id` is not sent. If a `linode_id` is sent without a `config_id`, the volume will be attached:    * to the Linode's only config if it only has one config.   * to the Linode's last used config, if possible.  If no config can be selected for attachment, an error will be returned.  (e.g. 23456)
  label: string # The Volume's label, which is also used in the `filesystem_path` of the resulting volume.  (e.g. my-volume)
  --linode-id: int # The Linode this volume should be attached to upon creation. If not given, the volume will be created without an attachment.  (e.g. 123)
  --region: string # The Region to deploy this Volume in. This is only required if a linode_id is not given.
  --size: int # The initial size of this volume, in GB.  Be aware that volumes may only be resized up after creation.  (default: 20, e.g. 20)
  --tags: list # An array of Tags applied to this object.  Tags are for organizational purposes only.  (e.g. [example tag, another example])
]: any -> record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/volumes")
  let body = {"config_id": $config_id, "label": $label, "linode_id": $linode_id, "region": $region, "size": $size, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Volume Delete
#
# DELETE /volumes/{volumeId}
# operationId: deleteVolume
export def "volumes delete" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Volume View
#
# GET /volumes/{volumeId}
# operationId: getVolume
export def "volumes get" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of a collection to return. (default: 1)
  --page-size: int # The number of items to return per page. (default: 100)
]: nothing -> record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list<string>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Volume Update
#
# PUT /volumes/{volumeId}
# operationId: updateVolume
export def "volumes update" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --label: string # The Volume's label is for display purposes only.  (e.g. my-volume)
  --region: any
  --tags: list # An array of Tags applied to this object.  Tags are for organizational purposes only.  (e.g. [example tag, another example])
]: any -> record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}"))
  let body = {"label": $label, "region": $region, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Volume Attach
#
# POST /volumes/{volumeId}/attach
# operationId: attachVolume
export def "volumes-attach attach" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config-id: int # The ID of the Linode Config to include this Volume in. Must belong to the Linode referenced by `linode_id`. If not given, the last booted Config will be chosen.  (e.g. 23456)
  linode_id: int # The ID of the Linode to attach the volume to.
  --persist-across-boots: oneof<nothing, bool> # Defaults to true, if false is provided, the Volume will not be attached to the Linode Config. In this case more than 8 Volumes may be attached to a Linode if a Linode has 16GB of RAM or more. The number of volumes that can be attached is equal to the number of GB of RAM that the Linode has, up to a maximum of 64. `config_id` should not be passed if this is set to false and linode_id must be passed. The Linode must be running.
]: any -> record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}/attach"))
  let body = {"config_id": $config_id, "linode_id": $linode_id, "persist_across_boots": $persist_across_boots} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Volume Clone
#
# POST /volumes/{volumeId}/clone
# operationId: cloneVolume
export def "volumes-clone clone" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: any
]: any -> record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}/clone"))
  let body = {"label": $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Volume Detach
#
# POST /volumes/{volumeId}/detach
# operationId: detachVolume
export def "volumes-detach detachVolume" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}/detach"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Volume Resize
#
# POST /volumes/{volumeId}/resize
# operationId: resizeVolume
export def "volumes-resize resize" [
  volume_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  size: any
]: any -> record<created: string, filesystem_path: string, hardware_type: string, id: int, label: string, linode_id: int, linode_label: string, region: any, size: int, status: string, tags: list<string>, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({volume_id: $volume_id} | format pattern "/volumes/{volume_id}/resize"))
  let body = {"size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
