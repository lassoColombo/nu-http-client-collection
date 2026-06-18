# Auto-generated client for Sinao API v1.1.0
# Source: https://api.apis.guru/v2/specs/sinao.app/1.1.0/openapi.json
# Auth: --token flag or $env.SINAO_API_TOKEN

const BASE_URL = "https://api.sinao.app/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SINAO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["https://api.sinao.app/v1" "https://api.sinao.dev/v1" "https://api.sinao.test/v1"] }
def auth-scheme-completer [] { ["basic" "bearer" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["invoice" "none" "purchase" "quote" "relationship" "transaction"] }
def type-completer-1 [] { ["sap"] }
def type-completer-2 [] { ["bank" "cashdesk" "waiting"] }
def account-type-completer [] { ["card" "checking" "life_insurance" "loan" "pending" "savings" "securities" "share_savings_plan" "special" "unknown"] }
def format-completer [] { ["acd" "fiducial" "quadra" "universal"] }
def template-completer [] { ["command" "delivery"] }
def status-completer [] { ["draft" "final" "paid"] }
def type-completer-3 [] { ["product" "service"] }
def vat-repayment-completer [] { ["billing" "payment"] }
def status-completer-1 [] { ["completed" "paid"] }
def status-completer-2 [] { ["deleted" "goodforagreement" "refused" "transformed" "waiting"] }
def type-completer-4 [] { ["purchase" "sales" "transaction"] }
def frequency-duration-completer [] { ["day" "month" "semester" "trimester" "week" "year"] }
def discount-mode-completer [] { ["percent"] }
def period-completer [] { ["daily" "hourly" "monthly" "quarterly" "weekly" "yearly"] }
def object-completer [] { ["invoice" "payment" "purchase" "quote" "relationship" "transaction"] }
def calcul-completer [] { ["avg" "count" "sum"] }
def period-completer-1 [] { ["half-yearly" "monthly" "quarterly" "yearly"] }
def object-completer-1 [] { ["invoice" "product" "purchase" "quote"] }
def method-completer [] { ["automatic_debit" "cash" "check" "creditcard" "creditnote" "transfer"] }
def type-completer-5 [] { ["contact" "invoice" "quote"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps list" } } | get name | first)
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

# List apps
#
# GET /apps
# operationId: app.list
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an app
#
# POST /apps
# operationId: app.create
export def "apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --organization-name: string # Organization name. Minimum 3 characters with 1 alpha
]: nothing -> record<admin: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: table<app: any, policy_profile: record, user: record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_name" $organization_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an invitation from token
#
# DELETE /apps/access/invite/{accessToken}
# operationId: app.policies.registration.delete
export def "apps-access-invite delete-by-accessToken" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token)} | format pattern "/apps/access/invite/{access_token}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invitation informations
#
# GET /apps/access/invite/{accessToken}
# operationId: app.policies.registration.get
export def "apps-access-invite get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>, recipient_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token)} | format pattern "/apps/access/invite/{access_token}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an User by invitation
#
# POST /apps/access/invite/{accessToken}/register
# operationId: app.policies.registration.register
export def "apps-access-invite-register create" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # Password for account
  --firstname: string # First name of user before account creation / account link
  --lastname: string # Last name of user before account creation / account link
  --cgu: oneof<nothing, bool> # User has valided CGU ?
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "password" $password "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "cgu" $cgu "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token)} | format pattern "/apps/access/invite/{access_token}/register") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an app
#
# GET /apps/{appId}
# operationId: app.get
export def "apps get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: table<app: any, policy_profile: record, user: record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get policies for an app
#
# GET /apps/{appId}/access
# operationId: app.policies.list
export def "apps-access list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/access") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invitations
#
# GET /apps/{appId}/access/invite
# operationId: app.policies.invitations.list
export def "apps-access-invite list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<app: record<admin: record, config: list, hostname_alias: string, id: int, last_access_at: string, last_user: record, organization: record, policies: list, subscription: record, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list, visible: int>, recipient_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/access/invite") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite an user
#
# POST /apps/{appId}/access/invite
# operationId: app.policies.invitations.create
export def "apps-access-invite create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email for invitation. Will be used to account creation or account matching with an existing user
  --policy-profile-id: int # Profile for policies set
  --firstname: string # First name of user before account creation / account link
  --lastname: string # Last name of user before account creation / account link
  --civility: string # Last name of user before account creation / account link
  --password: string # Password for new user
]: nothing -> record<app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: any>, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>, id: int, profile: record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int>, recipient_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, sender_user: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, used_at: string, validity: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "policy_profile_id" $policy_profile_id "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "civility" $civility "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/access/invite") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an invitation
#
# DELETE /apps/{appId}/access/invite/{id}
# operationId: app.policies.invitations.delete
export def "apps-access-invite delete-by-appId-id" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/access/invite/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profiles
#
# GET /apps/{appId}/access/profiles
# operationId: app.policies.profiles.list
export def "apps-access-profiles list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/access/profiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete police for an user
#
# DELETE /apps/{appId}/access/{userId}
# operationId: app.policies.delete
export def "apps-access delete" [
  app_id: int
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), user_id: (encode-path-segment $user_id)} | format pattern "/apps/{app_id}/access/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get police for an user
#
# GET /apps/{appId}/access/{userId}
# operationId: app.policies.get
export def "apps-access get" [
  app_id: int
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), user_id: (encode-path-segment $user_id)} | format pattern "/apps/{app_id}/access/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update police for an user
#
# POST /apps/{appId}/access/{userId}
# operationId: app.policies.update
export def "apps-access update" [
  app_id: int
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy-profile-id: int
]: nothing -> record<description: string, homepage: string, name: string, restricted: bool, rights: list<string>, visible: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "policy_profile_id" $policy_profile_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), user_id: (encode-path-segment $user_id)} | format pattern "/apps/{app_id}/access/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List categories
#
# GET /apps/{appId}/accountcategories/
# operationId: app.accounting.categories.list
export def "apps-accountcategories list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<description: string, id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accountcategories/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a category
#
# POST /apps/{appId}/accountcategories/
# operationId: app.accounting.categories.create
export def "apps-accountcategories create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --type: string
]: nothing -> record<description: string, id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accountcategories/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a category
#
# DELETE /apps/{appId}/accountcategories/{id}
# operationId: app.accounting.categories.delete
export def "apps-accountcategories delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/accountcategories/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a category
#
# GET /apps/{appId}/accountcategories/{id}
# operationId: app.accounting.categories.get
export def "apps-accountcategories get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/accountcategories/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a category
#
# POST /apps/{appId}/accountcategories/{id}
# operationId: app.accounting.categories.update
export def "apps-accountcategories update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --description: string
  --type: string
]: nothing -> record<description: string, id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/accountcategories/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List accounting entries
#
# GET /apps/{appId}/accounting_entries/
# operationId: app.accounting.entries.list
export def "apps-accounting-entries list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accounting_entries/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Account
#
# GET /apps/{appId}/accounts/
# operationId: app.accounting.accounts.list
export def "apps-accounts list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accounts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Account
#
# POST /apps/{appId}/accounts/
# operationId: app.accounting.accounts.create
export def "apps-accounts create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --journalcode: string
  --name: string
  --description: string
  --keywords: string
  --accounting-number: string
  --is-cashflow: oneof<nothing, bool>
  --is-sales: oneof<nothing, bool>
  --is-purchase: oneof<nothing, bool>
]: nothing -> record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "journalcode" $journalcode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "accounting_number" $accounting_number "scalar") (serialize-qp "is_cashflow" $is_cashflow "scalar") (serialize-qp "is_sales" $is_sales "scalar") (serialize-qp "is_purchase" $is_purchase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accounts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create many accounts
#
# POST /apps/{appId}/accounts/batch
# operationId: app.accounting.accounts.batch
export def "apps-accounts-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of accounts. Without ID for insert
]: nothing -> record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/accounts/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Account
#
# DELETE /apps/{appId}/accounts/{id}
# operationId: app.accounting.accounts.delete
export def "apps-accounts delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Account
#
# GET /apps/{appId}/accounts/{id}
# operationId: app.accounting.accounts.get
export def "apps-accounts get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Account
#
# POST /apps/{appId}/accounts/{id}
# operationId: app.accounting.accounts.update
export def "apps-accounts update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --journalcode: string
  --name: string
  --description: string
  --keywords: string
  --accounting-number: string
  --is-cashflow: oneof<nothing, bool>
  --is-sales: oneof<nothing, bool>
  --is-purchase: oneof<nothing, bool>
]: nothing -> record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "journalcode" $journalcode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "accounting_number" $accounting_number "scalar") (serialize-qp "is_cashflow" $is_cashflow "scalar") (serialize-qp "is_sales" $is_sales "scalar") (serialize-qp "is_purchase" $is_purchase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/accounts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all api keys
#
# GET /apps/{appId}/apikeys
# operationId: app.apikeys.list
export def "apps-apikeys list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/apikeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new API key
#
# POST /apps/{appId}/apikeys
# operationId: app.apikeys.create
export def "apps-apikeys create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Key name
  --api-partner-id: int # Partner ID for official connexion (nullable)
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "api_partner_id" $api_partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/apikeys") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an api key
#
# DELETE /apps/{appId}/apikeys/{id}
# operationId: app.apikeys.delete
export def "apps-apikeys delete" [
  app_id: int
  id: string
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/apikeys/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all api parners
#
# GET /apps/{appId}/apipartners
# operationId: app.apipartners.list
export def "apps-apipartners list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/apipartners") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List attachments
#
# GET /apps/{appId}/attachments
# operationId: app.attachments.list
export def "apps-attachments list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<attachable_id: string, attachable_type: string, file_url: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/attachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file on an object
#
# POST /apps/{appId}/attachments
# operationId: app.attachments.create
export def "apps-attachments create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Object to attach file
  --attachable-id: int # Object id
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "attachable_id" $attachable_id "scalar") (serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/attachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recreate S.A.P attestations
#
# PUT /apps/{appId}/attachments
# operationId: app.sapAttestations.generateSapAttestations
export def "apps-attachments generate-sap-attestations" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a list of attachments in pdf into a .zip file
#
# GET /apps/{appId}/attachments/download
# operationId: app.attachments.download
export def "apps-attachments-download download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Array of attachments id
  --type: string@type-completer-1 # Type of attachment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/attachments/download") $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a list of SAP attestations in pdf into a .zip file
#
# GET /apps/{appId}/attachments/sap-download
# operationId: app.sapAttestations.download
export def "apps-attachments-sap-download download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Array of attachments id
  --type: string@type-completer-1 # Type of attachment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/attachments/sap-download") $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file from id
#
# DELETE /apps/{appId}/attachments/{id}
# operationId: app.attachments.delete
export def "apps-attachments delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attachment by id
#
# GET /apps/{appId}/attachments/{id}
# operationId: app.attachments.get
export def "apps-attachments get" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/attachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the attachment as pdf
#
# GET /apps/{appId}/attachments/{id}/pdf
# operationId: app.attachments.RedirectToPublicUrl
export def "apps-attachments-pdf get-redirect-to-public-url" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --random: int # random number to force fresh pdf
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "random" $random "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/attachments/{id}/pdf") $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List BankDetails
#
# GET /apps/{appId}/bankdetails
# operationId: app.documents.sales.bankdetails.list
export def "apps-bankdetails list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<bic: string, iban: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/bankdetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a BankDetails
#
# POST /apps/{appId}/bankdetails
# operationId: app.documents.sales.bankdetails.create
export def "apps-bankdetails create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --iban: string
  --bic: string
]: nothing -> record<bic: string, iban: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "iban" $iban "scalar") (serialize-qp "bic" $bic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/bankdetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a BankDetails
#
# DELETE /apps/{appId}/bankdetails/{id}
# operationId: app.documents.sales.bankdetails.delete
export def "apps-bankdetails delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/bankdetails/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a BankDetails
#
# GET /apps/{appId}/bankdetails/{id}
# operationId: app.documents.sales.bankdetails.get
export def "apps-bankdetails get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bic: string, iban: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/bankdetails/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a BankDetails
#
# POST /apps/{appId}/bankdetails/{id}
# operationId: app.documents.sales.bankdetails.update
export def "apps-bankdetails update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --iban: string
  --bic: string
]: nothing -> record<bic: string, iban: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "iban" $iban "scalar") (serialize-qp "bic" $bic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/bankdetails/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Bankin synchronization
#
# DELETE /apps/{appId}/banks/
# operationId: app.cashflow.banks.delete
export def "apps-banks delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-id: int
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "item_id" $item_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/banks/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List banks connected to bankin
#
# GET /apps/{appId}/banks/
# operationId: app.cashflow.banks.list
export def "apps-banks list" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/banks/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the link to the funnel to connect a bank with Sinao
#
# GET /apps/{appId}/banks/connect
# operationId: app.cashflow.banks.connect
export def "apps-banks-connect get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/banks/connect"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers synchronization at Bankin then synchronizes transactions with Sinao
#
# POST /apps/{appId}/banks/synchronize
# operationId: app.cashflow.banks.synchronize
export def "apps-banks-synchronize create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Optional item id to refresh. If set, triggers a refresh at Bankin before synchronizing transactions
  --is-incremential: oneof<nothing, bool> # The value 'false' triggers a non-incremental syncronization of the maximum possible duration. The value 'true' updates the transactions updated by Bankin since a certain date
]: nothing -> record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "is_incremential" $is_incremential "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/banks/synchronize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the link to the funnel to edit password
#
# GET /apps/{appId}/banks/{id}/funnel/edit
# operationId: app.cashflow.banks.url_edit
export def "apps-banks-funnel-edit get-url" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/banks/{id}/funnel/edit"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the link to the funnel to start manually a synchronization (SCA)
#
# GET /apps/{appId}/banks/{id}/funnel/sync
# operationId: app.cashflow.banks.url_sync
export def "apps-banks-funnel-sync sync-url" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/banks/{id}/funnel/sync"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the link to the funnel to validate a pro item (SCA)
#
# GET /apps/{appId}/banks/{id}/funnel/validate
# operationId: app.cashflow.banks.url_validate
export def "apps-banks-funnel-validate validate-url" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/banks/{id}/funnel/validate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Select accounts to synchronize
#
# POST /apps/{appId}/banks/{id}/select_accounts
# operationId: app.cashflow.banks.select_accounts
export def "apps-banks-select-accounts create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bank-account-ids: list<int> # List of enables accounts (nullable)
]: nothing -> record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bank_account_ids" $bank_account_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/banks/{id}/select_accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List CashflowSource
#
# GET /apps/{appId}/cashflowsources/
# operationId: app.cashflow.cashflowsources.list
export def "apps-cashflowsources list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/cashflowsources/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a CashflowSource
#
# POST /apps/{appId}/cashflowsources/
# operationId: app.cashflow.cashflowsources.create
export def "apps-cashflowsources create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --identifiant: string
  --type: string@type-completer-2
  --balance-amount: int
  --account-type: string@account-type-completer
  --parent-cashflow-source-id: int
]: nothing -> record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "identifiant" $identifiant "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "balance_amount" $balance_amount "scalar") (serialize-qp "account_type" $account_type "scalar") (serialize-qp "parent_cashflow_source_id" $parent_cashflow_source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/cashflowsources/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a CashflowSource
#
# DELETE /apps/{appId}/cashflowsources/{id}
# operationId: app.cashflow.cashflowsources.delete
export def "apps-cashflowsources delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/cashflowsources/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a CashflowSource
#
# GET /apps/{appId}/cashflowsources/{id}
# operationId: app.cashflow.cashflowsources.get
export def "apps-cashflowsources get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/cashflowsources/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a CashflowSource
#
# POST /apps/{appId}/cashflowsources/{id}
# operationId: app.cashflow.cashflowsources.update
export def "apps-cashflowsources update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --identifiant: string
  --type: string@type-completer-2
  --balance-amount: int
  --account-type: string@account-type-completer
  --parent-cashflow-source-id: int
]: nothing -> record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "identifiant" $identifiant "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "balance_amount" $balance_amount "scalar") (serialize-qp "account_type" $account_type "scalar") (serialize-qp "parent_cashflow_source_id" $parent_cashflow_source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/cashflowsources/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge many contacts
#
# POST /apps/{appId}/contacts/merge
# operationId: app.contacts.transform.merge
export def "apps-contacts-merge create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contacts: list # nullable
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contacts" $contacts "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/contacts/merge") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send emails
#
# POST /apps/{appId}/email/batch
# operationId: app.contacts.email.batch
export def "apps-email-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # format: email
  --messages: list
  --need-copy-bcc: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "messages" $messages "multi") (serialize-qp "need_copy_bcc" $need_copy_bcc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/email/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an email
#
# POST /apps/{appId}/email/document
# operationId: app.contacts.email.send
export def "apps-email-document send" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # format: email
  --recipients: list<string>
  --recipients-cc: list<string>
  --recipients-bcc: list<string>
  --title: string
  --body: string
  --documents: list
  --need-copy-bcc: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "recipients" $recipients "multi") (serialize-qp "recipients_cc" $recipients_cc "multi") (serialize-qp "recipients_bcc" $recipients_bcc "multi") (serialize-qp "title" $title "scalar") (serialize-qp "body" $body "scalar") (serialize-qp "documents" $documents "multi") (serialize-qp "need_copy_bcc" $need_copy_bcc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/email/document") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an establishment
#
# DELETE /apps/{appId}/establishments/{id}
# operationId: app.contacts.establishments.delete
export def "apps-establishments delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/establishments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an establishment
#
# GET /apps/{appId}/establishments/{id}
# operationId: app.contacts.establishments.get
export def "apps-establishments get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: list<string>, id: int, name: string, nic: string, phones: list<string>, place: record<administrative_area_level1: string, administrative_area_level2: string, administrative_area_level3: string, country: string, countryiso2: string, formatted_address: string, id: int, latitude: int, locality: string, longitude: int, postal_code: string, route: string, route2: string, street_number: string, sublocality: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/establishments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an establishment
#
# POST /apps/{appId}/establishments/{id}
# operationId: app.contacts.establishments.update
export def "apps-establishments update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --phones: list<string>
  --emails: list<string>
  --nic: string # Establishment number (french NIC) (nullable)
  --place: record
]: nothing -> record<emails: list<string>, id: int, name: string, nic: string, phones: list<string>, place: record<administrative_area_level1: string, administrative_area_level2: string, administrative_area_level3: string, country: string, countryiso2: string, formatted_address: string, id: int, latitude: int, locality: string, longitude: int, postal_code: string, route: string, route2: string, street_number: string, sublocality: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "phones" $phones "multi") (serialize-qp "emails" $emails "multi") (serialize-qp "nic" $nic "scalar") (serialize-qp "place" $place "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/establishments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ExportEntity
#
# GET /apps/{appId}/exports
# operationId: app.accounting.export.list
export def "apps-exports list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/exports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a ExportEntity
#
# POST /apps/{appId}/exports
# operationId: app.accounting.export.create
export def "apps-exports create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --until: string # format: date-time
]: nothing -> record<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/exports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the ACD UUID for authentification
#
# GET /apps/{appId}/exports/acd_compta
# operationId: app.accounting.export.AcdComptaGetUuid
export def "apps-exports-acd-compta get-uuid" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/exports/acd_compta"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register ACD identifiants
#
# POST /apps/{appId}/exports/acd_compta
# operationId: app.accounting.export.AcdComptaSetUuid
export def "apps-exports-acd-compta update-uuid" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # the login provided by ACD Compta
  --password: string # the password provided by ACD Compta
  --qp-base: string # Your ACD account number (3XXXX)
  --cnx: string # your CNX by ACD Compta
]: nothing -> record<uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "base" $qp_base "scalar") (serialize-qp "cnx" $cnx "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/exports/acd_compta") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the export entity as zip
#
# GET /apps/{appId}/exports/download
# operationId: app.accounting.export.download
export def "apps-exports-download download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The export format can be a FEC (universal - similar to the French legal file 'Fichier des Ecritures Comptables') or specific for accounting software
  --export-entities-ids: list<int>
  --start-at: string # Automatically find export entities from a date range (format: date-time)
  --end-at: string # Automatically find export entities from a date range (format: date-time)
  --since: string # Automatically find export entities since a date (format: date-time)
  --since-last: oneof<nothing, bool> # Automatically find the export entities since the last export downloaded
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "export_entities_ids" $export_entities_ids "multi") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "since_last" $since_last "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/exports/download") $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ExportEntity
#
# GET /apps/{appId}/exports/months
# operationId: app.accounting.export.list_by_months
export def "apps-exports-months list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/exports/months"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a ExportEntity
#
# DELETE /apps/{appId}/exports/{id}
# operationId: app.accounting.export.delete
export def "apps-exports delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/exports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a ExportEntity
#
# GET /apps/{appId}/exports/{id}
# operationId: app.accounting.export.get
export def "apps-exports get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, entries_count: int, id: int, period_end: string, period_start: string, status: string, total_credit: int, total_debit: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/exports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invoices
#
# GET /apps/{appId}/invoices
# operationId: app.documents.sales.invoices.list
export def "apps-invoices list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: record, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: int, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an invoice
#
# POST /apps/{appId}/invoices
# operationId: app.documents.sales.invoices.create
export def "apps-invoices create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string # nullable
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document (nullable)
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --downpayments: list<int> # nullable
  --downpayment-cash: int # nullable
  --avoid-of: int # nullable
  --delivered-at: string # nullable, format: date-time
  --payment-period: int # Days count before considere this invoice as late (nullable, default: 30)
  --payment-methods: string # Accepted methods of payment for this invoice. Methods comma separated (default: virement bancaire, chèque)
  --number-from-other-software: string # Invoices imported from another software are not counted in the numbering and are not locked
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_infos" $contact_infos "multi") (serialize-qp "third_account" $third_account "multi") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi") (serialize-qp "reference" $reference "scalar") (serialize-qp "discount" $discount "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "legal_notice" $legal_notice "scalar") (serialize-qp "bank_details_id" $bank_details_id "scalar") (serialize-qp "vat_exemption" $vat_exemption "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "downpayments" $downpayments "multi") (serialize-qp "downpayment_cash" $downpayment_cash "scalar") (serialize-qp "avoid_of" $avoid_of "scalar") (serialize-qp "delivered_at" $delivered_at "scalar") (serialize-qp "payment_period" $payment_period "scalar") (serialize-qp "payment_methods" $payment_methods "scalar") (serialize-qp "number_from_other_software" $number_from_other_software "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete many invoices
#
# DELETE /apps/{appId}/invoices/batch
# operationId: app.documents.sales.invoices.batch_delete
export def "apps-invoices-batch delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of invoices ID
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update many invoices
#
# POST /apps/{appId}/invoices/batch
# operationId: app.documents.sales.invoices.batch
export def "apps-invoices-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of invoices. With ID for update, without for insert
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a list of invoices in pdf into a .zip file
#
# GET /apps/{appId}/invoices/download
# operationId: app.documents.sales.invoices.download
export def "apps-invoices-download download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of invoices id
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "template" $template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices/download") $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate pdf and recalcul amounts of invoice
#
# POST /apps/{appId}/invoices/fresh
# operationId: app.documents.sales.invoices.fresh
export def "apps-invoices-fresh create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of invoices id
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices/fresh") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the next invoice number for preview
#
# GET /apps/{appId}/invoices/nextnumber
# operationId: app.documents.sales.invoices.nextnumber
export def "apps-invoices-nextnumber get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --written-at: string # Write date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "written_at" $written_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices/nextnumber") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about invoices
#
# GET /apps/{appId}/invoices/statistics
# operationId: app.documents.sales.invoices.statistics
export def "apps-invoices-statistics get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/invoices/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an invoice
#
# DELETE /apps/{appId}/invoices/{id}
# operationId: app.documents.sales.invoices.delete
export def "apps-invoices delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an invoice
#
# GET /apps/{appId}/invoices/{id}
# operationId: app.documents.sales.invoices.get
export def "apps-invoices get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an invoice
#
# POST /apps/{appId}/invoices/{id}
# operationId: app.documents.sales.invoices.update
export def "apps-invoices update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string # nullable
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document (nullable)
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --downpayments: list<int> # nullable
  --downpayment-cash: int # nullable
  --avoid-of: int # nullable
  --delivered-at: string # nullable, format: date-time
  --payment-period: int # Days count before considere this invoice as late (nullable, default: 30)
  --payment-methods: string # Accepted methods of payment for this invoice. Methods comma separated (default: virement bancaire, chèque)
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_infos" $contact_infos "multi") (serialize-qp "third_account" $third_account "multi") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi") (serialize-qp "reference" $reference "scalar") (serialize-qp "discount" $discount "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "legal_notice" $legal_notice "scalar") (serialize-qp "bank_details_id" $bank_details_id "scalar") (serialize-qp "vat_exemption" $vat_exemption "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "downpayments" $downpayments "multi") (serialize-qp "downpayment_cash" $downpayment_cash "scalar") (serialize-qp "avoid_of" $avoid_of "scalar") (serialize-qp "delivered_at" $delivered_at "scalar") (serialize-qp "payment_period" $payment_period "scalar") (serialize-qp "payment_methods" $payment_methods "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file at an invoice
#
# DELETE /apps/{appId}/invoices/{id}/attach
# operationId: app.documents.sales.invoices.detach
export def "apps-invoices-attach delete-detach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File to detach
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file at an invoice
#
# POST /apps/{appId}/invoices/{id}/attach
# operationId: app.documents.sales.invoices.attach
export def "apps-invoices-attach attach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a creditnote on an invoice
#
# POST /apps/{appId}/invoices/{id}/avoid
# operationId: app.documents.sales.invoices.avoid
export def "apps-invoices-avoid create" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/avoid"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate an invoice
#
# POST /apps/{appId}/invoices/{id}/duplicate
# operationId: app.documents.sales.invoices.duplicate
export def "apps-invoices-duplicate create" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/duplicate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finalize an invoice
#
# POST /apps/{appId}/invoices/{id}/finalize
# operationId: app.documents.sales.invoices.finalize
export def "apps-invoices-finalize finalize" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-date: oneof<nothing, bool> # Automatically updates the date if earlier than the last invoice
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_date" $force_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/finalize") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the invoice as pdf
#
# GET /apps/{appId}/invoices/{id}/pdf
# operationId: app.documents.sales.invoices.pdf
export def "apps-invoices-pdf get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template" $template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/pdf") $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download invoice as jpeg
#
# GET /apps/{appId}/invoices/{id}/preview.jpg
# operationId: app.documents.sales.invoices.preview
export def "apps-invoices-preview-jpg get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string # Template name to generate document (nullable)
  --disable-cache: oneof<nothing, bool> # Force the regeneration of the preview (nullable)
  --base64: oneof<nothing, bool> # Get the image in base64 (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template" $template "scalar") (serialize-qp "disable_cache" $disable_cache "scalar") (serialize-qp "base64" $base64 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/preview.jpg") $qp)
  let accept_val = "application/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a tag on an invoice
#
# DELETE /apps/{appId}/invoices/{id}/tag
# operationId: app.documents.sales.invoices.untag
export def "apps-invoices-tag untag" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/tag") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tag on an invoice
#
# POST /apps/{appId}/invoices/{id}/tag
# operationId: app.documents.sales.invoices.tag
export def "apps-invoices-tag tag" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag to add
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/tag") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of an invoice
#
# POST /apps/{appId}/invoices/{id}/updatestatus
# operationId: app.documents.sales.invoices.updatestatus
export def "apps-invoices-updatestatus create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Status to update
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/invoices/{id}/updatestatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear autoreconciliation logs
#
# DELETE /apps/{appId}/logs/autoreconcile/
# operationId: app.cashflow.logsautoreconciliations.clear
export def "apps-logs-autoreconcile delete-clear" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/logs/autoreconcile/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List autoreconciliation logs
#
# GET /apps/{appId}/logs/autoreconcile/
# operationId: app.cashflow.logsautoreconciliations.list
export def "apps-logs-autoreconcile list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/logs/autoreconcile/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start force autoreconciliation
#
# POST /apps/{appId}/logs/autoreconcile/
# operationId: app.cashflow.logsautoreconciliations.start
export def "apps-logs-autoreconcile start" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/logs/autoreconcile/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get organization profile for current app
#
# GET /apps/{appId}/organization
# operationId: app.organization.get
export def "apps-organization get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: record<admin: record, config: list, hostname_alias: string, id: int, last_access_at: string, last_user: record, organization: any, policies: list, subscription: record, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/organization"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update organization profile for current app
#
# POST /apps/{appId}/organization
# operationId: app.organization.update
export def "apps-organization update" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Company name visible on the app
  --billing-name: string # Company name for billing
  --logo: string
  --legal-form: string
  --country-iso2: string # format: ISO 3166-1 alpha-2
  --founding-date: string # format: date
  --founding-location: string
  --dissolution-date: string # format: date
  --closeaccounting-period: string
  --national-id: string # Unique National Id, format by country. **In France : [0-9]{9} with last number as security key.**
  --trade-directory-registration: string # France Directory Registration : Unique national ID SIRET [0-9]{9} + 'RM' + CMA identification number [0-9a-z]{2,}
  --vat-id: string # European VAT Id. **In France : FR [0-9]{2} [0-9]{9}** (nullable)
  --code-naf: string # French NAF Code (nullable)
  --number-of-employees: string
  --industry: string
  --slogan: string
  --rcs: string # French. Registre du Commerce et des Sociétés
  --greffe: string # French. Tribunal de commerce
  --sap-number-registration: string # NOVA agreement/registration number (nullable)
  --sap-activities: string # Organisation activities displayed in annual taxes customer attestation (nullable)
  --sap-date-registration: string # NOVA agreement/registration date (nullable)
  --capital: int
]: nothing -> record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string, app: record<admin: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, config: list<any>, hostname_alias: string, id: int, last_access_at: string, last_user: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, organization: any, policies: list<record>, subscription: record<access_level: string, id: int, payment_card: string, payment_failed_count: int, period_ending_date: string, period_remaining_days: int, period_starting_date: string, plan_color: string, plan_name: string, status: string, stripe_customer_id: string, stripe_plan_id: string, stripe_subscription_id: string>, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "billing_name" $billing_name "scalar") (serialize-qp "logo" $logo "scalar") (serialize-qp "legal_form" $legal_form "scalar") (serialize-qp "country_iso2" $country_iso2 "scalar") (serialize-qp "founding_date" $founding_date "scalar") (serialize-qp "founding_location" $founding_location "scalar") (serialize-qp "dissolution_date" $dissolution_date "scalar") (serialize-qp "closeaccounting_period" $closeaccounting_period "scalar") (serialize-qp "national_id" $national_id "scalar") (serialize-qp "trade_directory_registration" $trade_directory_registration "scalar") (serialize-qp "vat_id" $vat_id "scalar") (serialize-qp "code_naf" $code_naf "scalar") (serialize-qp "number_of_employees" $number_of_employees "scalar") (serialize-qp "industry" $industry "scalar") (serialize-qp "slogan" $slogan "scalar") (serialize-qp "rcs" $rcs "scalar") (serialize-qp "greffe" $greffe "scalar") (serialize-qp "sap_number_registration" $sap_number_registration "scalar") (serialize-qp "sap_activities" $sap_activities "scalar") (serialize-qp "sap_date_registration" $sap_date_registration "scalar") (serialize-qp "capital" $capital "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/organization") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List organizations
#
# GET /apps/{appId}/organizations
# operationId: app.contacts.organizations.list
export def "apps-organizations list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/organizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organization
#
# POST /apps/{appId}/organizations
# operationId: app.contacts.organizations.create
export def "apps-organizations create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Company name visible on the app
  --billing-name: string # Company name for billing
  --logo: string
  --legal-form: string
  --country-iso2: string # format: ISO 3166-1 alpha-2
  --founding-date: string # format: date
  --founding-location: string
  --dissolution-date: string # format: date
  --vat-system: string
  --closeaccounting-period: string
  --national-id: string # Unique National Id, format by country. **In France : [0-9]{9} with last number as security key.**
  --vat-id: string # European VAT Id. **In France : FR [0-9]{2} [0-9]{9}** (nullable)
  --code-naf: string # French NAF Code (nullable)
  --number-of-employees: string
  --slogan: string
  --rcs: string # French. Registre du Commerce et des Sociétés
  --greffe: string # French. Tribunal de commerce
  --capital: int
  --metadata: list # nullable
]: nothing -> record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "billing_name" $billing_name "scalar") (serialize-qp "logo" $logo "scalar") (serialize-qp "legal_form" $legal_form "scalar") (serialize-qp "country_iso2" $country_iso2 "scalar") (serialize-qp "founding_date" $founding_date "scalar") (serialize-qp "founding_location" $founding_location "scalar") (serialize-qp "dissolution_date" $dissolution_date "scalar") (serialize-qp "vat_system" $vat_system "scalar") (serialize-qp "closeaccounting_period" $closeaccounting_period "scalar") (serialize-qp "national_id" $national_id "scalar") (serialize-qp "vat_id" $vat_id "scalar") (serialize-qp "code_naf" $code_naf "scalar") (serialize-qp "number_of_employees" $number_of_employees "scalar") (serialize-qp "slogan" $slogan "scalar") (serialize-qp "rcs" $rcs "scalar") (serialize-qp "greffe" $greffe "scalar") (serialize-qp "capital" $capital "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/organizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple organizations
#
# POST /apps/{appId}/organizations/batch
# operationId: app.contacts.organizations.batch
export def "apps-organizations-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of invoices. With ID for update, without for insert
]: nothing -> record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/organizations/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove an organization
#
# DELETE /apps/{appId}/organizations/{id}
# operationId: app.contacts.organizations.delete
export def "apps-organizations delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/organizations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an organization
#
# GET /apps/{appId}/organizations/{id}
# operationId: app.contacts.organizations.get
export def "apps-organizations get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/organizations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organization
#
# POST /apps/{appId}/organizations/{id}
# operationId: app.contacts.organizations.update
export def "apps-organizations update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Company name visible on the app
  --billing-name: string # Company name for billing
  --logo: string
  --legal-form: string
  --country-iso2: string # format: ISO 3166-1 alpha-2
  --founding-date: string # format: date
  --founding-location: string
  --dissolution-date: string # format: date
  --vat-system: string
  --closeaccounting-period: string
  --national-id: string # Unique National Id, format by country. **In France : [0-9]{9} with last number as security key.**
  --vat-id: string # European VAT Id. **In France : FR [0-9]{2} [0-9]{9}** (nullable)
  --code-naf: string # French NAF Code (nullable)
  --number-of-employees: string
  --slogan: string
  --rcs: string # French. Registre du Commerce et des Sociétés
  --greffe: string # French. Tribunal de commerce
  --capital: int
  --metadata: list # nullable
]: nothing -> record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "billing_name" $billing_name "scalar") (serialize-qp "logo" $logo "scalar") (serialize-qp "legal_form" $legal_form "scalar") (serialize-qp "country_iso2" $country_iso2 "scalar") (serialize-qp "founding_date" $founding_date "scalar") (serialize-qp "founding_location" $founding_location "scalar") (serialize-qp "dissolution_date" $dissolution_date "scalar") (serialize-qp "vat_system" $vat_system "scalar") (serialize-qp "closeaccounting_period" $closeaccounting_period "scalar") (serialize-qp "national_id" $national_id "scalar") (serialize-qp "vat_id" $vat_id "scalar") (serialize-qp "code_naf" $code_naf "scalar") (serialize-qp "number_of_employees" $number_of_employees "scalar") (serialize-qp "slogan" $slogan "scalar") (serialize-qp "rcs" $rcs "scalar") (serialize-qp "greffe" $greffe "scalar") (serialize-qp "capital" $capital "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/organizations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore an organization
#
# GET /apps/{appId}/organizations/{id}/restore
# operationId: app.contacts.organizations.restore
export def "apps-organizations-restore get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/organizations/{id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payments
#
# GET /apps/{appId}/payments
# operationId: app.payments.payments.list
export def "apps-payments list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record, cashflow_source: record, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list, method: int, received_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/payments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the recipe book
#
# GET /apps/{appId}/payments/recipe_book
# operationId: app.payments.payments.recipe_book
export def "apps-payments-recipe-book get" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/payments/recipe_book"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a payment
#
# DELETE /apps/{appId}/payments/{id}
# operationId: app.payments.payments.delete
export def "apps-payments delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/payments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a payment
#
# GET /apps/{appId}/payments/{id}
# operationId: app.payments.payments.get
export def "apps-payments get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/payments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List persons
#
# GET /apps/{appId}/persons
# operationId: app.contacts.persons.list
export def "apps-persons list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/persons") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a person
#
# POST /apps/{appId}/persons
# operationId: app.contacts.persons.create
export def "apps-persons create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --civility: string # Civility is the lastname prefix
  --lastname: string
  --firstname: string
  --picture: string
  --metadata: list # nullable
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "civility" $civility "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "picture" $picture "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/persons") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple persons
#
# POST /apps/{appId}/persons/batch
# operationId: app.contacts.persons.batch
export def "apps-persons-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of persons. With ID for update, without for insert
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/persons/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a person
#
# DELETE /apps/{appId}/persons/{id}
# operationId: app.contacts.persons.delete
export def "apps-persons delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/persons/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a person
#
# GET /apps/{appId}/persons/{id}
# operationId: app.contacts.persons.get
export def "apps-persons get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/persons/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a person
#
# POST /apps/{appId}/persons/{id}
# operationId: app.contacts.persons.update
export def "apps-persons update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --civility: string # Civility is the lastname prefix (nullable)
  --lastname: string
  --firstname: string
  --picture: string
  --metadata: list # nullable
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "civility" $civility "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "picture" $picture "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/persons/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore a person
#
# GET /apps/{appId}/persons/{id}/restore
# operationId: app.contacts.persons.restore
export def "apps-persons-restore get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/persons/{id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping app web hostname
#
# GET /apps/{appId}/ping
# operationId: app.ping
export def "apps-ping ping" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/ping"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List product categories
#
# GET /apps/{appId}/productcategory
# operationId: app.catalog.categories.list
export def "apps-productcategory list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list, name: string, quantity_name: string, reference: string, tags: list, unity: string, vat_percent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/productcategory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a product category
#
# POST /apps/{appId}/productcategory
# operationId: app.catalog.categories.create
export def "apps-productcategory create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --image: string
  --parent-category-id: int
]: nothing -> record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "parent_category_id" $parent_category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/productcategory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a product category
#
# DELETE /apps/{appId}/productcategory/{id}
# operationId: app.catalog.categories.delete
export def "apps-productcategory delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productcategory/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a product category
#
# GET /apps/{appId}/productcategory/{id}
# operationId: app.catalog.categories.get
export def "apps-productcategory get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productcategory/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a product category
#
# POST /apps/{appId}/productcategory/{id}
# operationId: app.catalog.categories.update
export def "apps-productcategory update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --image: string
  --parent-category-id: int
]: nothing -> record<id: int, image: any, name: string, parent: any, products: record<accounting_number: string, amount_accurately: int, category: any, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "parent_category_id" $parent_category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productcategory/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List products
#
# GET /apps/{appId}/products
# operationId: app.catalog.products.list
export def "apps-products list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a product
#
# POST /apps/{appId}/products
# operationId: app.catalog.products.create
export def "apps-products create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --amount: int # Price without taxes in cents
  --amount-accurately: int # Price without taxes in cents / 1000
  --vat-percent: int # Taxe rate in cents
  --image: string
  --lifetime: int # Product life time in seconds
  --description: string # Product description
  --type: string@type-completer-3 # Is a service or a product ?
  --quantity-name: string # Name of the quantity: days, liters, m2, m3...
  --reference: string
  --account-id: string
  --tags: list
  --category-id: int
  --metadata: list # nullable
]: nothing -> record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "amount_accurately" $amount_accurately "scalar") (serialize-qp "vat_percent" $vat_percent "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "lifetime" $lifetime "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "quantity_name" $quantity_name "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple products
#
# POST /apps/{appId}/products/batch
# operationId: app.catalog.products.batch
export def "apps-products-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of products. With ID for update, without for insert
]: nothing -> record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/products/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a product
#
# DELETE /apps/{appId}/products/{id}
# operationId: app.catalog.products.delete
export def "apps-products delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a product
#
# GET /apps/{appId}/products/{id}
# operationId: app.catalog.products.get
export def "apps-products get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a product
#
# POST /apps/{appId}/products/{id}
# operationId: app.catalog.products.update
export def "apps-products update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --amount: int # Price without taxes in cents
  --amount-accurately: int # Price without taxes in cents / 1000
  --vat-percent: int # Taxe rate in cents
  --image: string
  --lifetime: int # Product life time in seconds
  --description: string # Product description
  --type: string@type-completer-3 # Is a service or a product ?
  --quantity-name: string # Name of the quantity: days, liters, m2, m3...
  --reference: string
  --account-id: string
  --tags: list
  --category-id: int
  --metadata: list # nullable
]: nothing -> record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "amount_accurately" $amount_accurately "scalar") (serialize-qp "vat_percent" $vat_percent "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "lifetime" $lifetime "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "quantity_name" $quantity_name "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/products/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file
#
# DELETE /apps/{appId}/products/{id}/attach
# operationId: app.catalog.products.detach
export def "apps-products-attach delete-detach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File to detach
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/products/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file
#
# POST /apps/{appId}/products/{id}/attach
# operationId: app.catalog.products.attach
export def "apps-products-attach attach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/products/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List stocks
#
# GET /apps/{appId}/productstocks
# operationId: app.catalog.stocks.list
export def "apps-productstocks list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list, name: string, quantity_name: string, reference: string, tags: list, unity: string, vat_percent: int>, product_stocks_movements: list<record>, purchase: record<account: record, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record, supplier_name: string, tags: list, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: list<record>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/productstocks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a stocks
#
# POST /apps/{appId}/productstocks
# operationId: app.catalog.stocks.create
export def "apps-productstocks create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: int # Parent object
  --purchase-id: int # Purchase that generated the stock if exists
  --quantity: int # The initial quantity will no longer be modifiable. To change the quantity manually, use the `destruct` endpoint
  --bar-code: string
  --location: string
  --entered-at: string # format: date-time
  --expired-at: string # format: date-time
  --cost-amount: int
  --use-duration: int # Use duration in seconds
]: nothing -> record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "purchase_id" $purchase_id "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "bar_code" $bar_code "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "entered_at" $entered_at "scalar") (serialize-qp "expired_at" $expired_at "scalar") (serialize-qp "cost_amount" $cost_amount "scalar") (serialize-qp "use_duration" $use_duration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/productstocks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a stocks
#
# DELETE /apps/{appId}/productstocks/{id}
# operationId: app.catalog.stocks.delete
export def "apps-productstocks delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productstocks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a stocks
#
# GET /apps/{appId}/productstocks/{id}
# operationId: app.catalog.stocks.get
export def "apps-productstocks get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productstocks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a stocks
#
# POST /apps/{appId}/productstocks/{id}
# operationId: app.catalog.stocks.update
export def "apps-productstocks update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --purchase-id: int # Purchase that generated the stock if exists
  --bar-code: string
  --location: string
  --entered-at: string # format: date-time
  --expired-at: string # format: date-time
  --cost-amount: int
  --use-duration: int # Use duration in seconds
]: nothing -> record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purchase_id" $purchase_id "scalar") (serialize-qp "bar_code" $bar_code "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "entered_at" $entered_at "scalar") (serialize-qp "expired_at" $expired_at "scalar") (serialize-qp "cost_amount" $cost_amount "scalar") (serialize-qp "use_duration" $use_duration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productstocks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Destruct a quantity of stock (forgotten, destructed, expirated stock...)
#
# POST /apps/{appId}/productstocks/{id}/destruct
# operationId: app.catalog.stocks.destruct
export def "apps-productstocks-destruct create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quantity: int # Quantity to destruct
  --comment: string
]: nothing -> record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productstocks/{id}/destruct") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Consider part of the stock as back
#
# POST /apps/{appId}/productstocks/{id}/rental/back
# operationId: app.catalog.stocks.rental_back
export def "apps-productstocks-rental-back create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quantity: int # Quantity to return in stocks
  --current-return-date: string # format: date-time, default: now
  --use-duration: int # Usage duration in seconds (default: 0)
  --comment: string
]: nothing -> record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar") (serialize-qp "current_return_date" $current_return_date "scalar") (serialize-qp "use_duration" $use_duration "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productstocks/{id}/rental/back") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Consider part of the stock as rented
#
# POST /apps/{appId}/productstocks/{id}/rental/exit
# operationId: app.catalog.stocks.rental_exit
export def "apps-productstocks-rental-exit create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quantity: int # Quantity to rent
  --future-return-date: string # format: date-time
  --comment: string
]: nothing -> record<bar_code: int, cost_amount: int, entered_at: int, expired_at: int, id: int, initial_quantity: int, location: int, product: record<accounting_number: string, amount_accurately: int, category: record<id: int, image: any, name: string, parent: any, products: any>, currency: string, description: string, id: int, image: any, intangible: bool, lifetime: int, metadata: list<any>, name: string, quantity_name: string, reference: string, tags: list<string>, unity: string, vat_percent: int>, product_stocks_movements: table<description: string, future_return_date: string, id: int, invoice: record, moved_at: string, product_stock: any, quantity: int, type: string, use_duration: int>, purchase: record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string>, quantity_in: int, quantity_out: int, sales_lines: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: any, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, use_duration: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar") (serialize-qp "future_return_date" $future_return_date "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/productstocks/{id}/rental/exit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List purchases
#
# GET /apps/{appId}/purchases
# operationId: app.documents.purchases.purchases.list
export def "apps-purchases list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
  --expand: list<string>
]: nothing -> table<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/purchases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a purchase
#
# POST /apps/{appId}/purchases
# operationId: app.documents.purchases.purchases.create
export def "apps-purchases create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoice: string # Invoice or receipt file (pdf or image) (format: binary)
  --account-id: int
  --supplier-organization-id: int
  --title: string
  --supplier-name: string
  --amount: int
  --amount-tax: int
  --currency: string
  --vat-detail: record
  --billed-at: string # format: date
  --comment: int
  --tags: list
  --vat-repayment: string@vat-repayment-completer
  --payment-deadline-at: string # nullable, format: date
  --payment-account-number: string # nullable
  --payment-routing-number: string # nullable
  --payment-swift: string # nullable
  --payment-iban: string # nullable
]: nothing -> record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invoice" $invoice "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "supplier_organization_id" $supplier_organization_id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "supplier_name" $supplier_name "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "amount_tax" $amount_tax "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "vat_detail" $vat_detail "multi") (serialize-qp "billed_at" $billed_at "scalar") (serialize-qp "comment" $comment "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "vat_repayment" $vat_repayment "scalar") (serialize-qp "payment_deadline_at" $payment_deadline_at "scalar") (serialize-qp "payment_account_number" $payment_account_number "scalar") (serialize-qp "payment_routing_number" $payment_routing_number "scalar") (serialize-qp "payment_swift" $payment_swift "scalar") (serialize-qp "payment_iban" $payment_iban "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/purchases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete many purchases
#
# DELETE /apps/{appId}/purchases/batch
# operationId: app.documents.purchases.purchases.batch_delete
export def "apps-purchases-batch delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of purchases ID
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/purchases/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update many purchases
#
# POST /apps/{appId}/purchases/batch
# operationId: app.documents.purchases.purchases.batch
export def "apps-purchases-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of purchases. With ID for update, without for insert
]: nothing -> record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/purchases/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a list of purchases in pdf into a .zip file
#
# GET /apps/{appId}/purchases/download
# operationId: app.documents.purchases.purchases.download
export def "apps-purchases-download download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of purchases id
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/purchases/download") $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about purchases
#
# GET /apps/{appId}/purchases/statistics
# operationId: app.documents.purchases.purchases.statistics
export def "apps-purchases-statistics get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/purchases/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a purchase
#
# DELETE /apps/{appId}/purchases/{id}
# operationId: app.documents.purchases.purchases.delete
export def "apps-purchases delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a purchase
#
# GET /apps/{appId}/purchases/{id}
# operationId: app.documents.purchases.purchases.get
export def "apps-purchases get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a purchase
#
# POST /apps/{appId}/purchases/{id}
# operationId: app.documents.purchases.purchases.update
export def "apps-purchases update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # Auto-calculated by sales_lines total
  --supplier-organization-id: int
  --title: string
  --supplier-name: string
  --amount: int # Auto-calculated by sales_lines total
  --amount-tax: int
  --currency: string
  --vat-detail: record
  --billed-at: string # format: date
  --comment: int
  --tags: list
  --vat-repayment: string@vat-repayment-completer
  --payment-deadline-at: string # nullable, format: date
  --payment-account-number: string # nullable
  --payment-routing-number: string # nullable
  --payment-swift: string # nullable
  --payment-iban: string # nullable
  --purchase-lines: list
]: nothing -> record<account: record<accounting_number: string, description: string, editable: bool, id: int, is_associate: bool, is_cashflow: bool, is_purchase: bool, is_sales: bool, is_various: bool, journalcode: string, keywords: string, name: string, need_charge: bool, need_employee: bool, need_invoice: bool, technical_name: string>, accounted_at: string, amount: int, amount_net_foreign_currency: int, amount_tax: int, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, billed_at: string, comment: string, completed_at: string, foreign_currency: string, id: int, is_late: bool, md5: string, paid_at: string, payment_account_number: string, payment_deadline_at: string, payment_iban: string, payment_routing_number: string, payment_swift: string, picture: string, status: string, supplier: record<billing_name: string, capital: int, closeaccounting_period: string, code_naf: string, country_iso2: string, dissolution_date: string, establishments: list<record>, founding_date: string, founding_location: string, greffe: string, id: int, legal_form: string, logo: string, name: string, national_id: string, number_of_employees: string, rcs: string, slogan: string, tax_id: string, vat_id: string, vat_system: string>, supplier_name: string, tags: list<string>, title: string, vat_detail: record, vat_repayment: string, will_be_late_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "supplier_organization_id" $supplier_organization_id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "supplier_name" $supplier_name "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "amount_tax" $amount_tax "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "vat_detail" $vat_detail "multi") (serialize-qp "billed_at" $billed_at "scalar") (serialize-qp "comment" $comment "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "vat_repayment" $vat_repayment "scalar") (serialize-qp "payment_deadline_at" $payment_deadline_at "scalar") (serialize-qp "payment_account_number" $payment_account_number "scalar") (serialize-qp "payment_routing_number" $payment_routing_number "scalar") (serialize-qp "payment_swift" $payment_swift "scalar") (serialize-qp "payment_iban" $payment_iban "scalar") (serialize-qp "purchase_lines" $purchase_lines "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file at a purchase
#
# DELETE /apps/{appId}/purchases/{id}/attach
# operationId: app.documents.purchases.purchases.detach
export def "apps-purchases-attach delete-detach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File to detach
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file at a purchase
#
# POST /apps/{appId}/purchases/{id}/attach
# operationId: app.documents.purchases.purchases.attach
export def "apps-purchases-attach attach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the purchase as pdf
#
# GET /apps/{appId}/purchases/{id}/original
# operationId: app.documents.purchases.purchases.original
export def "apps-purchases-original get" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/original"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download purchase as jpeg
#
# GET /apps/{appId}/purchases/{id}/preview.jpg
# operationId: app.documents.purchases.purchases.preview
export def "apps-purchases-preview-jpg get" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/preview.jpg"))
  let accept_val = "application/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a tag on a purchase
#
# DELETE /apps/{appId}/purchases/{id}/tag
# operationId: app.documents.purchases.purchases.untag
export def "apps-purchases-tag untag" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/tag") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tag on a purchase
#
# POST /apps/{appId}/purchases/{id}/tag
# operationId: app.documents.purchases.purchases.tag
export def "apps-purchases-tag tag" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag to add
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/tag") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show purchase thumbnail as jpeg
#
# GET /apps/{appId}/purchases/{id}/thumbnail.jpg
# operationId: app.documents.purchases.purchases.thumbnail
export def "apps-purchases-thumbnail-jpg get" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/thumbnail.jpg"))
  let accept_val = "application/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of an invoice
#
# POST /apps/{appId}/purchases/{id}/updatestatus
# operationId: app.documents.purchases.purchases.updatestatus
export def "apps-purchases-updatestatus create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Status to update
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/purchases/{id}/updatestatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List quotes
#
# GET /apps/{appId}/quotes
# operationId: app.documents.sales.quotes.list
export def "apps-quotes list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a quote
#
# POST /apps/{appId}/quotes
# operationId: app.documents.sales.quotes.create
export def "apps-quotes create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list
  --metadata: list # nullable
  --downpayment-request: record
  --commercialvalidity-deadline: string # nullable, format: date-time
  --number-from-other-software: string # Invoices imported from another software are not counted in the numbering and are not locked
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_infos" $contact_infos "multi") (serialize-qp "third_account" $third_account "multi") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi") (serialize-qp "reference" $reference "scalar") (serialize-qp "discount" $discount "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "legal_notice" $legal_notice "scalar") (serialize-qp "bank_details_id" $bank_details_id "scalar") (serialize-qp "vat_exemption" $vat_exemption "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "downpayment_request" $downpayment_request "multi") (serialize-qp "commercialvalidity_deadline" $commercialvalidity_deadline "scalar") (serialize-qp "number_from_other_software" $number_from_other_software "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete many quotes
#
# DELETE /apps/{appId}/quotes/batch
# operationId: app.documents.sales.quotes.batch_delete
export def "apps-quotes-batch delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of quotes ID
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update many quotes
#
# POST /apps/{appId}/quotes/batch
# operationId: app.documents.sales.quotes.batch
export def "apps-quotes-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of quotes. With ID for update, without for insert
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a list of quotes in pdf into a .zip file
#
# GET /apps/{appId}/quotes/download
# operationId: app.documents.sales.quotes.download
export def "apps-quotes-download download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of quotes id
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "template" $template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/download") $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate pdf and recalcul amounts of quote
#
# POST /apps/{appId}/quotes/fresh
# operationId: app.documents.sales.quotes.fresh
export def "apps-quotes-fresh create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of quotes id
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/fresh") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update many quotes
#
# POST /apps/{appId}/quotes/invoice
# operationId: app.documents.sales.quotes.invoices
export def "apps-quotes-invoice create-by-appId" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # Array of quotes id
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/invoice") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the next quote number for preview
#
# GET /apps/{appId}/quotes/nextnumber
# operationId: app.documents.sales.quotes.nextnumber
export def "apps-quotes-nextnumber get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --written-at: string # Write date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "written_at" $written_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/nextnumber") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about quotes
#
# GET /apps/{appId}/quotes/statistics
# operationId: app.documents.sales.quotes.statistics
export def "apps-quotes-statistics get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/quotes/statistics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a quote
#
# DELETE /apps/{appId}/quotes/{id}
# operationId: app.documents.sales.quotes.delete
export def "apps-quotes delete" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a quote
#
# GET /apps/{appId}/quotes/{id}
# operationId: app.documents.sales.quotes.get
export def "apps-quotes get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a quote
#
# POST /apps/{appId}/quotes/{id}
# operationId: app.documents.sales.quotes.update
export def "apps-quotes update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --third-account: record # nullable
  --title: string
  --content: list
  --columns: record # List columns to display
  --reference: string # Free variable not display in document
  --discount: record
  --currency: string
  --legal-notice: string # Legal mentions
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list
  --metadata: list # nullable
  --downpayment-request: record
  --commercialvalidity-deadline: string # nullable, format: date-time
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_infos" $contact_infos "multi") (serialize-qp "third_account" $third_account "multi") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi") (serialize-qp "reference" $reference "scalar") (serialize-qp "discount" $discount "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "legal_notice" $legal_notice "scalar") (serialize-qp "bank_details_id" $bank_details_id "scalar") (serialize-qp "vat_exemption" $vat_exemption "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "downpayment_request" $downpayment_request "multi") (serialize-qp "commercialvalidity_deadline" $commercialvalidity_deadline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file at a quote
#
# DELETE /apps/{appId}/quotes/{id}/attach
# operationId: app.documents.sales.quotes.detach
export def "apps-quotes-attach delete-detach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File to detach
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file at a quote
#
# POST /apps/{appId}/quotes/{id}/attach
# operationId: app.documents.sales.quotes.attach
export def "apps-quotes-attach attach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transform the quote in a downpayment invoice
#
# POST /apps/{appId}/quotes/{id}/downpayment
# operationId: app.documents.sales.quotes.downpayment
export def "apps-quotes-downpayment create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --percent: int # Percentage of downpayment in cents (100 = 1%)
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "percent" $percent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/downpayment") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate a quote
#
# POST /apps/{appId}/quotes/{id}/duplicate
# operationId: app.documents.sales.quotes.duplicate
export def "apps-quotes-duplicate create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/duplicate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finalize a quote
#
# POST /apps/{appId}/quotes/{id}/finalize
# operationId: app.documents.sales.quotes.finalize
export def "apps-quotes-finalize finalize" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/finalize"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transform the quote in invoice
#
# POST /apps/{appId}/quotes/{id}/invoice
# operationId: app.documents.sales.quotes.invoice
export def "apps-quotes-invoice create-by-appId-id" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/invoice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the quote as pdf
#
# GET /apps/{appId}/quotes/{id}/pdf
# operationId: app.documents.sales.quotes.pdf
export def "apps-quotes-pdf get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template" $template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/pdf") $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download quote as jpeg
#
# GET /apps/{appId}/quotes/{id}/preview.jpg
# operationId: app.documents.sales.quotes.preview
export def "apps-quotes-preview-jpg get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template" $template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/preview.jpg") $qp)
  let accept_val = "application/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transform the quote into a situation invoice
#
# POST /apps/{appId}/quotes/{id}/situation_invoice
# operationId: app.documents.sales.quotes.situation_invoice
export def "apps-quotes-situation-invoice create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --progress: int # Percentage of progress in cents (100 = 1%)
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "progress" $progress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/situation_invoice") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a tag on a quote
#
# DELETE /apps/{appId}/quotes/{id}/tag
# operationId: app.documents.sales.quotes.untag
export def "apps-quotes-tag untag" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag to delete
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/tag") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a tag on an quote
#
# POST /apps/{appId}/quotes/{id}/tag
# operationId: app.documents.sales.quotes.tag
export def "apps-quotes-tag tag" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag to add
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/tag") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the status of a quote
#
# POST /apps/{appId}/quotes/{id}/updatestatus
# operationId: app.documents.sales.quotes.updatestatus
export def "apps-quotes-updatestatus create" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # Status to update
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/updatestatus") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download quote as jpeg
#
# GET /apps/{appId}/quotes/{id}/yousign/preview.jpg
# operationId: app.documents.sales.quotes.yousign_preview
export def "apps-quotes-yousign-preview-jpg get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --template: string@template-completer # Template name to generate document (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template" $template "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/quotes/{id}/yousign/preview.jpg") $qp)
  let accept_val = "application/jpeg"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove payments by an object
#
# DELETE /apps/{appId}/reconcile
# operationId: app.payments.reconciliation.unreconcile
export def "apps-reconcile delete-unreconcile" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-4 # Object to unpay with this payment
  --id: int # Transaction, sales invoice or purchase invoice id to unreconcile
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/reconcile") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reconcile a transaction or a document
#
# POST /apps/{appId}/reconcile
# operationId: app.payments.reconciliation.reconcile
export def "apps-reconcile create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replace-all: oneof<nothing, bool> # Remove all previous reconciliations (default: false)
  --type: string@type-completer-4 # Object to pay with these payments and categorizations
  --id: int # Transaction, sales invoice or purchase invoice id to reconcile
  --movements: record
  --paid-at: string # Payment date for cashdesk or waiting entries (format: date-time)
  --rule: record # Create an auto-reconciliation rule
]: nothing -> record<amount: int, date: string, document: any, document_type: string, id: int, source: string, transaction: record<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replace_all" $replace_all "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "movements" $movements "multi") (serialize-qp "paid_at" $paid_at "scalar") (serialize-qp "rule" $rule "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/reconcile") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reconcile several transactions
#
# POST /apps/{appId}/reconcile/batch
# operationId: app.payments.reconciliation.batch
export def "apps-reconcile-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # array of reconciliation params
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, commercialvalidity_deadline: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/reconcile/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List RecurringInvoice
#
# GET /apps/{appId}/recurringinvoices
# operationId: app.documents.sales.recurringinvoices.list
export def "apps-recurringinvoices list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list<record>, saving_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/recurringinvoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a RecurringInvoice
#
# POST /apps/{appId}/recurringinvoices
# operationId: app.documents.sales.recurringinvoices.create
export def "apps-recurringinvoices create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --title: string # nullable
  --content: list # nullable
  --columns: record # List columns to display
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --payment-period: int # Days count before considere this invoice as late (default: 30)
  --next-invoice-at: string # nullable, format: date-time
  --end-at: string # nullable, format: date-time
  --frequency-count: int
  --frequency-duration: string@frequency-duration-completer
  --discount: int
  --discount-mode: string@discount-mode-completer # nullable
  --discount-start-at: string # nullable, format: date-time
  --discount-end-at: string # nullable, format: date-time
  --details: string # nullable
  --orders-plan: list # nullable
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_infos" $contact_infos "multi") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "legal_notice" $legal_notice "scalar") (serialize-qp "bank_details_id" $bank_details_id "scalar") (serialize-qp "vat_exemption" $vat_exemption "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "payment_period" $payment_period "scalar") (serialize-qp "next_invoice_at" $next_invoice_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "frequency_count" $frequency_count "scalar") (serialize-qp "frequency_duration" $frequency_duration "scalar") (serialize-qp "discount" $discount "scalar") (serialize-qp "discount_mode" $discount_mode "scalar") (serialize-qp "discount_start_at" $discount_start_at "scalar") (serialize-qp "discount_end_at" $discount_end_at "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "orders_plan" $orders_plan "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/recurringinvoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete many RecurringInvoice
#
# DELETE /apps/{appId}/recurringinvoices/batch
# operationId: app.documents.sales.recurringinvoices.batch_delete
export def "apps-recurringinvoices-batch delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int> # List of RecurringInvoice ID
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/recurringinvoices/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update many RecurringInvoice
#
# POST /apps/{appId}/recurringinvoices/batch
# operationId: app.documents.sales.recurringinvoices.batch
export def "apps-recurringinvoices-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of RecurringInvoice. With ID for update, without for insert
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/recurringinvoices/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get json of periods_formats for a date.
#
# GET /apps/{appId}/recurringinvoices/periods
# operationId: app.documents.sales.recurringinvoices.getPeriods
export def "apps-recurringinvoices-periods get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # Date of the invoice (nullable, format: date-time)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/recurringinvoices/periods") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a RecurringInvoice
#
# DELETE /apps/{appId}/recurringinvoices/{id}
# operationId: app.documents.sales.recurringinvoices.delete
export def "apps-recurringinvoices delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/recurringinvoices/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a RecurringInvoice
#
# GET /apps/{appId}/recurringinvoices/{id}
# operationId: app.documents.sales.recurringinvoices.get
export def "apps-recurringinvoices get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/recurringinvoices/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a RecurringInvoice
#
# POST /apps/{appId}/recurringinvoices/{id}
# operationId: app.documents.sales.recurringinvoices.update
export def "apps-recurringinvoices update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-infos: record # nullable
  --title: string # nullable
  --content: list # nullable
  --columns: record # List columns to display
  --currency: string
  --legal-notice: string # Legal mentions (nullable)
  --bank-details-id: int # nullable
  --vat-exemption: record
  --tags: list # nullable
  --metadata: list # nullable
  --payment-period: int # Days count before considere this invoice as late (default: 30)
  --next-invoice-at: string # nullable, format: date-time
  --end-at: string # nullable, format: date-time
  --frequency-count: int
  --frequency-duration: string@frequency-duration-completer
  --discount: int
  --discount-mode: string@discount-mode-completer # nullable
  --discount-start-at: string # nullable, format: date-time
  --discount-end-at: string # nullable, format: date-time
  --details: string # nullable
  --orders-plan: list # nullable
]: nothing -> record<attachments: list<string>, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, currency: string, customer: any, discount: int, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record<by_account: list, by_vat: list, total: int>, taxes: record<total: int, vat: record>>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: table<end_at: string, model: int>, saving_status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_infos" $contact_infos "multi") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi") (serialize-qp "currency" $currency "scalar") (serialize-qp "legal_notice" $legal_notice "scalar") (serialize-qp "bank_details_id" $bank_details_id "scalar") (serialize-qp "vat_exemption" $vat_exemption "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "payment_period" $payment_period "scalar") (serialize-qp "next_invoice_at" $next_invoice_at "scalar") (serialize-qp "end_at" $end_at "scalar") (serialize-qp "frequency_count" $frequency_count "scalar") (serialize-qp "frequency_duration" $frequency_duration "scalar") (serialize-qp "discount" $discount "scalar") (serialize-qp "discount_mode" $discount_mode "scalar") (serialize-qp "discount_start_at" $discount_start_at "scalar") (serialize-qp "discount_end_at" $discount_end_at "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "orders_plan" $orders_plan "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/recurringinvoices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview next invoices generations
#
# GET /apps/{appId}/recurringinvoices/{id}/plan
# operationId: app.documents.sales.recurringinvoices.plan
export def "apps-recurringinvoices-plan get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --until: string # Until date to generate plan (format: date-time)
]: nothing -> table<attachments: list<string>, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, balance: record<completed: bool, due: int, meaning: string, paid: int, remaining: int>, bank_detail: record<bic: string, iban: string, id: int, name: string>, columns: record<amount: string, designation: string, discount: string, due: string, info_total_quantity: string, quantity: string, quantity_name: string, subtotal: string, vat_percent: string>, contact_infos: record<address: string, address2: string, details: string, id: int, location: string, name: string, type: string>, content: list<record>, currency: string, customer: any, discount: record<amount: int, name: string, percent: int, value: int>, downpayment_request: record<amount: int, percent: int>, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list<any>, note: string, number: string, reference: string, tags: list<any>, third_account: record<address: string, id: int, location: string, name: string, type: string>, title: string, totals: record<due: int, subtotal: record, taxes: record>, validated_at: string, vat_exemption: record<article: string, exempted: bool, reason: string>, written_at: string, avoid_of: any, delivered_at: string, downpayments: list<any>, invoice_of: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: record, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, commercialvalidity_deadline: string, status: string>, paid_at: string, payment_methods: string, payment_period: int, related_recurring_invoice: record<attachments: list, author: record, balance: record, bank_detail: record, columns: record, contact_infos: record, content: list, currency: string, customer: any, discount: int, downpayment_request: record, email_sent_at: string, id: int, imported_at: string, legal_notice: string, metadata: list, note: string, number: string, reference: string, tags: list, third_account: record, title: string, totals: record, validated_at: string, vat_exemption: record, written_at: string, discount_end_at: string, discount_mode: string, discount_start_at: string, end_at: string, frequency_count: int, frequency_duration: string, next_invoice_at: string, orders_plan: list, saving_status: string>, sepa_direct_debit_exported_at: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/recurringinvoices/{id}/plan") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List relationships
#
# GET /apps/{appId}/relationships
# operationId: app.contacts.relationships.list
export def "apps-relationships list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/relationships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a relationship
#
# GET /apps/{appId}/relationships/{id}
# operationId: app.contacts.relationships.get
export def "apps-relationships get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/relationships/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a relationship
#
# POST /apps/{appId}/relationships/{id}
# operationId: app.contacts.relationships.update
export def "apps-relationships update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-customer: oneof<nothing, bool>
  --is-supplier: oneof<nothing, bool>
  --is-prospect: oneof<nothing, bool>
  --importance-level: int
  --rating: int
  --balance-initial-amount: int
  --is-notifying: oneof<nothing, bool>
  --note: string
  --reference: string # Accounting number if it's specific (nullable)
  --tags: string # nullable
  --discount: string # nullable
  --details: string # nullable
  --metadata: list # nullable
]: nothing -> record<accounting_infos: record<balance_initial_amount: int, customer_id: string, reference: string, supplier_id: string>, id: int, importance_level: int, is_customer: bool, is_notifying: bool, is_prospect: bool, is_supplier: bool, metadata: list<any>, note: string, rating: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_customer" $is_customer "scalar") (serialize-qp "is_supplier" $is_supplier "scalar") (serialize-qp "is_prospect" $is_prospect "scalar") (serialize-qp "importance_level" $importance_level "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "balance_initial_amount" $balance_initial_amount "scalar") (serialize-qp "is_notifying" $is_notifying "scalar") (serialize-qp "note" $note "scalar") (serialize-qp "reference" $reference "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "discount" $discount "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/relationships/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file
#
# DELETE /apps/{appId}/relationships/{id}/attach
# operationId: app.contacts.relationships.detach
export def "apps-relationships-attach delete-detach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File to detach
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/relationships/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file
#
# POST /apps/{appId}/relationships/{id}/attach
# operationId: app.contacts.relationships.attach
export def "apps-relationships-attach attach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/relationships/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset all data
#
# POST /apps/{appId}/reset
# operationId: app.reset
export def "apps-reset reset" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/reset"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List rules
#
# GET /apps/{appId}/rules/
# operationId: app.rules.list
export def "apps-rules list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<conditions: list<list>, id: int, on_event: string, parameter: string, priority: int, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/rules/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a rule
#
# POST /apps/{appId}/rules/
# operationId: app.rules.create
export def "apps-rules create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: list
  --on-event: string # Event like model.event, event in [saved, created, updated, deleted] (e.g. transaction.created)
  --parameter: string # e.g. account
  --value: string # e.g. 64
  --priority: int
]: nothing -> record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conditions" $conditions "multi") (serialize-qp "on_event" $on_event "scalar") (serialize-qp "parameter" $parameter "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/rules/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Execute all rules
#
# POST /apps/{appId}/rules/execute_on
# operationId: app.rules.execute_on
export def "apps-rules-execute-on create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string # e.g. transaction
]: nothing -> record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/rules/execute_on") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a rule
#
# DELETE /apps/{appId}/rules/{id}
# operationId: app.rules.delete
export def "apps-rules delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/rules/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a rule
#
# GET /apps/{appId}/rules/{id}
# operationId: app.rules.get
export def "apps-rules get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/rules/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a rule
#
# POST /apps/{appId}/rules/{id}
# operationId: app.rules.update
export def "apps-rules update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conditions: list
  --on-event: string # e.g. transaction.creating
  --parameter: string # e.g. account
  --value: string # e.g. 64
  --priority: int
]: nothing -> record<conditions: list<list<string>>, id: int, on_event: string, parameter: string, priority: int, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conditions" $conditions "multi") (serialize-qp "on_event" $on_event "scalar") (serialize-qp "parameter" $parameter "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/rules/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sales documents models
#
# GET /apps/{appId}/salesdocumentmodels
# operationId: app.documents.sales.models.list
export def "apps-salesdocumentmodels list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<id: int, json: list<record>, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/salesdocumentmodels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a sales document model
#
# POST /apps/{appId}/salesdocumentmodels
# operationId: app.documents.sales.models.create
export def "apps-salesdocumentmodels create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --title: string
  --content: list
  --columns: record # List columns to display
]: nothing -> record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/salesdocumentmodels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a sales document model
#
# DELETE /apps/{appId}/salesdocumentmodels/{id}
# operationId: app.documents.sales.models.delete
export def "apps-salesdocumentmodels delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/salesdocumentmodels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sales document model
#
# GET /apps/{appId}/salesdocumentmodels/{id}
# operationId: app.documents.sales.models.get
export def "apps-salesdocumentmodels get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/salesdocumentmodels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a sales document model
#
# POST /apps/{appId}/salesdocumentmodels/{id}
# operationId: app.documents.sales.models.update
export def "apps-salesdocumentmodels update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --title: string
  --content: list
  --columns: record # List columns to display
]: nothing -> record<id: int, json: table<account: record, action: string, amount: int, amount_accurately: int, amount_with_taxes: bool, detail: string, discount: record, document: any, id: int, metadata: list, product: record, quantity: float, stock: record, style: record, total_quantity: string, totals: record, unity: string, vat_percent: int>, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "content" $content "multi") (serialize-qp "columns" $columns "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/salesdocumentmodels/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List SEPAMandate
#
# GET /apps/{appId}/sepamandates/
# operationId: app.payments.sepamandates.list
export def "apps-sepamandates list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/sepamandates/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a SEPAMandate
#
# POST /apps/{appId}/sepamandates/
# operationId: app.payments.sepamandates.create
export def "apps-sepamandates create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-organization-id: int
  --customer-person-id: int
  --old-mandate-id: int
  --mandate-id: string
  --signed-at: string # format: date-time
  --electronic-signature: string
  --customer-name: string
  --iban: string
  --bic: string
  --is-first: oneof<nothing, bool>
]: nothing -> record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_organization_id" $customer_organization_id "scalar") (serialize-qp "customer_person_id" $customer_person_id "scalar") (serialize-qp "old_mandate_id" $old_mandate_id "scalar") (serialize-qp "mandate_id" $mandate_id "scalar") (serialize-qp "signed_at" $signed_at "scalar") (serialize-qp "electronic_signature" $electronic_signature "scalar") (serialize-qp "customer_name" $customer_name "scalar") (serialize-qp "iban" $iban "scalar") (serialize-qp "bic" $bic "scalar") (serialize-qp "is_first" $is_first "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/sepamandates/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview sepa credit transfer file
#
# GET /apps/{appId}/sepamandates/credittransfer
# operationId: app.payments.sepacredittransfer.preview
export def "apps-sepamandates-credittransfer get-preview" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/sepamandates/credittransfer") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview sepa credit transfer file
#
# POST /apps/{appId}/sepamandates/credittransfer
# operationId: app.payments.sepacredittransfer.download
export def "apps-sepamandates-credittransfer download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
  --amounts: list<int> # Optional array with amounts (keys must to correspond to ids)
  --debtor-name: string
  --debtor-iban: string
  --debtor-bic: string
  --btch-bookg: int
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "amounts" $amounts "multi") (serialize-qp "debtor_name" $debtor_name "scalar") (serialize-qp "debtor_iban" $debtor_iban "scalar") (serialize-qp "debtor_bic" $debtor_bic "scalar") (serialize-qp "btchBookg" $btch_bookg "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/sepamandates/credittransfer") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview sepa direct debit file
#
# GET /apps/{appId}/sepamandates/directdebit
# operationId: app.payments.sepadirectdebit.preview
export def "apps-sepamandates-directdebit get-preview" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoices-ids: list<int>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invoices_ids" $invoices_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/sepamandates/directdebit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download sepa direct debit file
#
# POST /apps/{appId}/sepamandates/directdebit
# operationId: app.payments.sepadirectdebit.download
export def "apps-sepamandates-directdebit download" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoices-ids: list<int>
  --amounts: list<int> # Optional array with amounts (keys must to correspond to invoices_ids)
  --creditor-name: string
  --creditor-iban: string
  --creditor-bic: string
  --creditor-ics: string
  --date: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invoices_ids" $invoices_ids "multi") (serialize-qp "amounts" $amounts "multi") (serialize-qp "creditor_name" $creditor_name "scalar") (serialize-qp "creditor_iban" $creditor_iban "scalar") (serialize-qp "creditor_bic" $creditor_bic "scalar") (serialize-qp "creditor_ics" $creditor_ics "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/sepamandates/directdebit") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a SEPAMandate
#
# DELETE /apps/{appId}/sepamandates/{id}
# operationId: app.payments.sepamandates.delete
export def "apps-sepamandates delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/sepamandates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a SEPAMandate
#
# GET /apps/{appId}/sepamandates/{id}
# operationId: app.payments.sepamandates.get
export def "apps-sepamandates get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/sepamandates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a SEPAMandate
#
# POST /apps/{appId}/sepamandates/{id}
# operationId: app.payments.sepamandates.update
export def "apps-sepamandates update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-organization-id: int
  --customer-person-id: int
  --old-mandate-id: int
  --mandate-id: string
  --signed-at: string # format: date-time
  --electronic-signature: string
  --customer-name: string
  --iban: string
  --bic: string
  --is-first: oneof<nothing, bool>
]: nothing -> record<author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, bic: string, created_at: string, customer: any, customer_name: string, electronic_signature: string, iban: string, id: int, is_first: int, last_debit_amount: int, last_debit_at: string, last_debit_id: int, logs_sepa_direct_debits: string, mandate_id: int, old_mandate_id: int, signed_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customer_organization_id" $customer_organization_id "scalar") (serialize-qp "customer_person_id" $customer_person_id "scalar") (serialize-qp "old_mandate_id" $old_mandate_id "scalar") (serialize-qp "mandate_id" $mandate_id "scalar") (serialize-qp "signed_at" $signed_at "scalar") (serialize-qp "electronic_signature" $electronic_signature "scalar") (serialize-qp "customer_name" $customer_name "scalar") (serialize-qp "iban" $iban "scalar") (serialize-qp "bic" $bic "scalar") (serialize-qp "is_first" $is_first "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/sepamandates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping Stripe webhook endpoint
#
# GET /apps/{appId}/services/stripe/webhook
# operationId: app.services.stripe.webhook.ping
export def "apps-services-stripe-webhook ping" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/services/stripe/webhook"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Webhook for Stripe
#
# POST /apps/{appId}/services/stripe/webhook
# operationId: app.services.stripe.webhook.handle
export def "apps-services-stripe-webhook create-handle" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/services/stripe/webhook"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Webhook for Yousign
#
# POST /apps/{appId}/services/yousign/webhook
# operationId: app.services.yousign.webhook.handle
export def "apps-services-yousign-webhook create-handle" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/services/yousign/webhook"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get app config
#
# GET /apps/{appId}/settings
# operationId: app.settings.get
export def "apps-settings get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/settings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update app config
#
# POST /apps/{appId}/settings
# operationId: app.settings.update
export def "apps-settings update" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # e.g. {accounting.export.journals.VE: VE, accounting.template.color-primary: #003B51}
  --key: string
  --value: string # Value can be a primitive or a file
]: nothing -> record<code: int, message: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "settings" $settings "multi") (serialize-qp "key" $key "scalar") (serialize-qp "value" $value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/settings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a signature
#
# POST /apps/{appId}/signature
# operationId: app.documents.sales.signature.create
export def "apps-signature create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: int
  --email: string
  --firstname: string
  --lastname: string
  --phone: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentId" $document_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "phone" $phone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/signature") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about sales
#
# GET /apps/{appId}/statistics/charts/{type}
# operationId: app.statistics.charts.get
export def "apps-statistics-charts get" [
  app_id: int
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int
  --period: string@period-completer
  --start-at: string # format: date-time
  --object: string@object-completer
  --object-property: string
  --calcul: string@calcul-completer
  --methods: list # Array of [object_property, calcul]
  --object-date-property: string
  --group-by: list<string>
  --group-by-object-name: string
  --exclude-keys: list<int>
  --search: string
  --filters: record
  --show-details: oneof<nothing, bool> # Recovers the details of the calculations
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "object_property" $object_property "scalar") (serialize-qp "calcul" $calcul "scalar") (serialize-qp "methods" $methods "multi") (serialize-qp "object_date_property" $object_date_property "scalar") (serialize-qp "group_by" $group_by "multi") (serialize-qp "group_by_object_name" $group_by_object_name "scalar") (serialize-qp "exclude_keys" $exclude_keys "multi") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "show_details" $show_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), type: (encode-path-segment $type)} | format pattern "/apps/{app_id}/statistics/charts/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about timetable purchases
#
# GET /apps/{appId}/statistics/timetable/purchases
# operationId: app.statistics.timetable.purchases
export def "apps-statistics-timetable-purchases get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # default: false
  --groups: list # default: [ [-730, -30], [-30, -1], [-1, 7], [7, 15], [15, 30], [30, 730] ]
]: nothing -> table<balance: int, count: int, data: list<record>, interval: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar") (serialize-qp "groups" $groups "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/statistics/timetable/purchases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about sales
#
# GET /apps/{appId}/statistics/timetable/sales
# operationId: app.statistics.timetable.sales
export def "apps-statistics-timetable-sales get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # default: false
  --groups: list # default: [ [-730, -30], [-30, -1], [-1, 7], [7, 15], [15, 30], [30, 730] ]
]: nothing -> table<balance: int, count: int, data: list<record>, interval: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar") (serialize-qp "groups" $groups "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/statistics/timetable/sales") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain statistics about vat
#
# GET /apps/{appId}/statistics/vat
# operationId: app.statistics.vat.get
export def "apps-statistics-vat get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # default: false
  --start-at: string # format: date-time, default: now
  --period: string@period-completer-1
  --end-at: string # format: date-time
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar") (serialize-qp "start_at" $start_at "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/statistics/vat") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update anchor date
#
# POST /apps/{appId}/subscription/anchordate
# operationId: app.subscription.anchordate
export def "apps-subscription-anchordate create" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/anchordate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payment link to Stripe Checkout
#
# GET /apps/{appId}/subscription/checkout_add_source
# operationId: app.subscription.checkout_add_source
export def "apps-subscription-checkout-add-source create" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/checkout_add_source"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add coupon
#
# POST /apps/{appId}/subscription/coupon
# operationId: app.subscription.coupon
export def "apps-subscription-coupon create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/coupon") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Extend trial period
#
# POST /apps/{appId}/subscription/extend_trial
# operationId: app.subscription.extend_trial
export def "apps-subscription-extend-trial create" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/extend_trial"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable plan
#
# POST /apps/{appId}/subscription/extra/{stripe_plan}
# operationId: app.subscription.extra_enable
export def "apps-subscription-extra enable" [
  app_id: int
  stripe_plan: string
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), stripe_plan: (encode-path-segment $stripe_plan)} | format pattern "/apps/{app_id}/subscription/extra/{stripe_plan}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pay all due invoices
#
# POST /apps/{appId}/subscription/pay_all
# operationId: app.subscription.pay_all
export def "apps-subscription-pay-all list" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/pay_all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# End current plan
#
# DELETE /apps/{appId}/subscription/plan
# operationId: app.subscription.end
export def "apps-subscription-plan delete-end" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/plan"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current plan
#
# GET /apps/{appId}/subscription/plan
# operationId: app.subscription.get
export def "apps-subscription-plan get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<extras: list<string>, plans: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/plan"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plans
#
# GET /apps/{appId}/subscription/plans
# operationId: app.subscription.list
export def "apps-subscription-plans list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<extras: list<string>, plans: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/plans"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Simulate a plan
#
# GET /apps/{appId}/subscription/plans/{stripe_plan}
# operationId: app.subscription.upcoming
export def "apps-subscription-plans get-upcoming" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-coupon: string # Stripe coupon id to simulate invoice (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripe_coupon" $stripe_coupon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), stripe_plan: (encode-path-segment $stripe_plan)} | format pattern "/apps/{app_id}/subscription/plans/{stripe_plan}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change plan
#
# POST /apps/{appId}/subscription/plans/{stripe_plan}
# operationId: app.subscription.pay
export def "apps-subscription-plans create-pay" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to pay (nullable)
  --stripe-coupon: string # Stripe coupon id to apply (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripe_source" $stripe_source "scalar") (serialize-qp "stripe_coupon" $stripe_coupon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), stripe_plan: (encode-path-segment $stripe_plan)} | format pattern "/apps/{app_id}/subscription/plans/{stripe_plan}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payment link to Stripe Checkout
#
# GET /apps/{appId}/subscription/plans/{stripe_plan}/checkout
# operationId: app.subscription.checkout
export def "apps-subscription-plans-checkout get" [
  app_id: int
  stripe_plan: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-coupon: string # Stripe coupon id to simulate invoice (nullable)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripe_coupon" $stripe_coupon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), stripe_plan: (encode-path-segment $stripe_plan)} | format pattern "/apps/{app_id}/subscription/plans/{stripe_plan}/checkout") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove creditcard or sepadebit
#
# DELETE /apps/{appId}/subscription/source
# operationId: app.subscription.remove_source
export def "apps-subscription-source delete" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to pay
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripe_source" $stripe_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/source") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add creditcard or sepadebit
#
# POST /apps/{appId}/subscription/source
# operationId: app.subscription.add_source
export def "apps-subscription-source create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to pay
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripe_source" $stripe_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/source") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change default source
#
# POST /apps/{appId}/subscription/source/default
# operationId: app.subscription.set_default
export def "apps-subscription-source-default update" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stripe-source: string # Stripe source to set as default source
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripe_source" $stripe_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/subscription/source/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all existants tags
#
# GET /apps/{appId}/tags
# operationId: app.statistics.tags.get
export def "apps-tags get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --object: string@object-completer-1
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "object" $object "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/tags") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get templates
#
# GET /apps/{appId}/templates
# operationId: app.settings.templates.list
export def "apps-templates list" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/templates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a template
#
# POST /apps/{appId}/templates
# operationId: app.settings.templates.create
export def "apps-templates create" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/templates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple templates
#
# POST /apps/{appId}/templates/batch
# operationId: app.settings.templates.batch
export def "apps-templates-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of templates. With ID for update, without for insert
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/templates/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default template
#
# GET /apps/{appId}/templates/default
# operationId: app.settings.templates.default_template
export def "apps-templates-default get" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/templates/default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a template
#
# GET /apps/{appId}/templates/{id}
# operationId: app.settings.templates.get
export def "apps-templates get" [
  app_id: int
  id: string
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/templates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a template
#
# POST /apps/{appId}/templates/{id}
# operationId: app.settings.templates.update
export def "apps-templates update" [
  app_id: int
  id: string
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/templates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Transaction
#
# GET /apps/{appId}/transactions/
# operationId: app.cashflow.transactions.list
export def "apps-transactions list" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items to skip before starting to collect the result set.
  --limit: int # The numbers of items to return. (default: 10)
  --search: string # A string to search for in objects.
  --filters: list # List of filters to apply to the query.
  --order: list # List in order of priority of the variables by which to order the result.
]: nothing -> table<amount: int, author: record<civility: string, establishments: list, firstname: string, id: int, image: string, lastname: string, metadata: list, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "filters" $filters "multi") (serialize-qp "order" $order "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/transactions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Transaction
#
# POST /apps/{appId}/transactions/
# operationId: app.cashflow.transactions.create
export def "apps-transactions create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-organization-id: int
  --contact-person-id: int
  --account-id: int
  --cashflow-source-id: int
  --contact-name: string
  --amount: int
  --method: string@method-completer
  --received-at: string # format: date-time
  --label: string
  --details: string
]: nothing -> record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_organization_id" $contact_organization_id "scalar") (serialize-qp "contact_person_id" $contact_person_id "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "cashflow_source_id" $cashflow_source_id "scalar") (serialize-qp "contact_name" $contact_name "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "received_at" $received_at "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/transactions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple transactions
#
# POST /apps/{appId}/transactions/batch
# operationId: app.cashflow.transactions.batch
export def "apps-transactions-batch create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: list # List of transactions. With ID for update, without for insert
]: nothing -> record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "data" $data "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/transactions/batch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a Transaction
#
# DELETE /apps/{appId}/transactions/{id}
# operationId: app.cashflow.transactions.delete
export def "apps-transactions delete" [
  app_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/transactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Transaction
#
# GET /apps/{appId}/transactions/{id}
# operationId: app.cashflow.transactions.get
export def "apps-transactions get" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/transactions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Transaction
#
# POST /apps/{appId}/transactions/{id}
# operationId: app.cashflow.transactions.update
export def "apps-transactions update" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-organization-id: int
  --contact-person-id: int
  --account-id: int
  --cashflow-source-id: int
  --contact-name: string
  --amount: int
  --method: string@method-completer
  --received-at: string # format: date-time
  --label: string
  --details: string
]: nothing -> record<amount: int, author: record<civility: string, establishments: list<record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string>, cashflow_source: record<account_type: string, balance_amount: int, created_at: string, disabled: int, id: int, identifiant: string, name: string, parent_cashflow_source: any, status: string, type: string, updated_at: string>, contact: any, created_at: string, deleted_at: string, details: int, id: int, label: int, lettered_at: string, metadata: list<any>, method: int, received_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_organization_id" $contact_organization_id "scalar") (serialize-qp "contact_person_id" $contact_person_id "scalar") (serialize-qp "account_id" $account_id "scalar") (serialize-qp "cashflow_source_id" $cashflow_source_id "scalar") (serialize-qp "contact_name" $contact_name "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "method" $method "scalar") (serialize-qp "received_at" $received_at "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/transactions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detach a file
#
# DELETE /apps/{appId}/transactions/{id}/attach
# operationId: app.cashflow.transactions.detach
export def "apps-transactions-attach delete-detach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: int # File to detach
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/transactions/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Attach a file
#
# POST /apps/{appId}/transactions/{id}/attach
# operationId: app.cashflow.transactions.attach
export def "apps-transactions-attach attach" [
  app_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # File to attach (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), id: (encode-path-segment $id)} | format pattern "/apps/{app_id}/transactions/{id}/attach") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login URSSAF
#
# POST /apps/{appId}/urssaf/auth
# operationId: app.payments.urssaftiers.auth
export def "apps-urssaf-auth create" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/urssaf/auth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status of a payment
#
# GET /apps/{appId}/urssaf/payment
# operationId: app.payments.urssaftiers.get_status
export def "apps-urssaf-payment get-status" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoices-ids: list<int>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invoices_ids" $invoices_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/urssaf/payment") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send URSSAF request payment
#
# POST /apps/{appId}/urssaf/payment
# operationId: app.payments.urssaftiers.send_payments
export def "apps-urssaf-payment send" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/urssaf/payment"))
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview URSSAF request payment
#
# GET /apps/{appId}/urssaf/preview
# operationId: app.payments.urssaftiers.preview
export def "apps-urssaf-preview get" [
  app_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-5
  --ids: list<int>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/urssaf/preview") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a person to URSSAF and create him a mandate
#
# POST /apps/{appId}/urssaf/register_customer
# operationId: app.payments.urssaftiers.register_customer
export def "apps-urssaf-register-customer create" [
  app_id: int
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/urssaf/register_customer"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change password
#
# POST /changepassword
# operationId: auth.changepassword
export def "changepassword create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forgotten-password-token: string
  --password: string # Password for account
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forgotten_password_token" $forgotten_password_token "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changepassword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login
#
# POST /login
# operationId: auth.login
export def "login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email for login (format: email)
  --password: string # Password for login in clear text
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logout
#
# POST /logout
# operationId: auth.logout
export def "logout create" [
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
  let full_url = (build-url $base "/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current user
#
# GET /me
# operationId: account.get
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update current user
#
# POST /me
# operationId: account.update
export def "me update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --civility: string
  --firstname: string
  --lastname: string
  --password: string
  --email: string # format: email
  --image: string # format: binary
  --metadata: list # nullable
]: nothing -> record<civility: string, establishments: table<emails: list, id: int, name: string, nic: string, phones: list, place: record>, firstname: string, id: int, image: string, lastname: string, metadata: list<any>, created_at: string, email: string, last_access_at: string, password: string, password_is_undefined: bool, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "civility" $civility "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/me" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping server
#
# GET /ping
# operationId: auth.ping
export def "ping get" [
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
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh a token
#
# GET /refresh
# operationId: auth.refresh
export def "refresh get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_token: string, expires_in: int, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an User
#
# POST /register
# operationId: account.create
export def "register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email is the user's login, it must not have been registered (format: email)
  --password: string
  --cgu: oneof<nothing, bool> # The user must have validated the T&Cs
  --firstname: string
  --lastname: string
  --metadata: list # nullable
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "cgu" $cgu "scalar") (serialize-qp "firstname" $firstname "scalar") (serialize-qp "lastname" $lastname "scalar") (serialize-qp "metadata" $metadata "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/register" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Password recover by email
#
# POST /sendpassword
# operationId: auth.sendpassword
export def "sendpassword create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email for login (format: email)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sendpassword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push to purchase collector
#
# POST /services/collector
# operationId: admin.purchaseCollector.push
export def "services-collector push" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-identifiant: string
  --collector-key: string
  --invoice: string # Invoice or receipt file (pdf or image) (format: binary)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_identifiant" $app_identifiant "scalar") (serialize-qp "collector_key" $collector_key "scalar") (serialize-qp "invoice" $invoice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/collector" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get VIES database informations from SIREN
#
# GET /services/vies/{siren}
# operationId: services.vies.get
export def "services-vies get" [
  siren: string
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
  let full_url = (build-url $base ({siren: (encode-path-segment $siren)} | format pattern "/services/vies/{siren}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
