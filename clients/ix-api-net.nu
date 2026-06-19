# Auto-generated client for IX-API v2.1.0
# Source: https://api.apis.guru/v2/specs/ix-api.net/2.1.0/openapi.json
# Auth: --token flag or $env.IX_API_TOKEN

const BASE_URL = "http://localhost/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IX_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://localhost/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["route_server"] }
def type-completer-1 [] { ["cloud_vc" "exchange_lan" "mp2mp_vc" "p2mp_vc" "p2p_vc"] }
def downgrade-allowed-completer [] { ["true" "true"] }
def upgrade-allowed-completer [] { ["false" "true"] }
def delivery-method-completer [] { ["dedicated" "shared"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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

# Retrieve a list of `Account`s. This includes all accounts the currently authorized account is managing and the current account itself.
#
# GET /accounts
# operationId: accounts_list
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --billable: int # Filter by billable
  --external-ref: string # Filter by external_ref
  --name: string # Filter by name
]: nothing -> table<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "scalar") (serialize-qp "state__is_not" $state_is_not "scalar") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "billable" $billable "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "state__is_not": $state_is_not, "managing_account": $managing_account, "billable": $billable, "external_ref": $external_ref, "name": $name} | compact), body: null}
}

# Create a new account.
#
# POST /accounts
# operationId: accounts_create
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: any
  --billing-information: any
  --discoverable: oneof<nothing, bool> # The account will be included for all members of the ix in the list of accounts. Only `id`, `name` and `present_in_metro_area_networks` are provided to other members. (default: false)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --legal-name: string # Legal name of the organisation. Only required when it's different from the account name. (nullable, e.g. Moon Network Services LLS.)
  --managing-account: string # The `id` of a managing account. Can be used for creating a customer hierachy. (nullable, e.g. IX:Account:231)
  --metro-area-network-presence: list<string> # Informal list of `MetroAreaNetwork` ids, indicating the presence to other accounts. The list is maintained by the account and can be empty. (default: [], e.g. [14021, 12939])
  name: string # Name of the account, how it gets represented in e.g. a "customers list". (e.g. Moonpeer Inc.)
]: any -> record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let req_body = {"address": $address, "billing_information": $billing_information, "discoverable": $discoverable, "external_ref": $external_ref, "legal_name": $legal_name, "managing_account": $managing_account, "metro_area_network_presence": $metro_area_network_presence, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Accounts can be deleted, when all services and configs are decommissioned or the account is not longer referenced e.g. as a `managing_account` or `billing_account`. Deleting an account will cascade to `contacts` and `role-assignments`. The request will immediately fail, if the above preconditions are not met.
#
# DELETE /accounts/{id}
# operationId: accounts_destroy
export def "accounts delete" [
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
]: nothing -> record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single account.
#
# GET /accounts/{id}
# operationId: accounts_read
export def "accounts get" [
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
]: nothing -> record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update parts of an account.
#
# PATCH /accounts/{id}
# operationId: accounts_partial_update
export def "accounts update-by-id" [
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
  --body: any
]: any -> record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update the entire account.
#
# PUT /accounts/{id}
# operationId: accounts_update
export def "accounts update-by-id-1" [
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
  address: any
  --billing-information: any
  --discoverable: oneof<nothing, bool> # The account will be included for all members of the ix in the list of accounts. Only `id`, `name` and `present_in_metro_area_networks` are provided to other members. (default: false)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --legal-name: string # Legal name of the organisation. Only required when it's different from the account name. (nullable, e.g. Moon Network Services LLS.)
  --managing-account: string # The `id` of a managing account. Can be used for creating a customer hierachy. (nullable, e.g. IX:Account:231)
  metro_area_network_presence: list<string> # Informal list of `MetroAreaNetwork` ids, indicating the presence to other accounts. The list is maintained by the account and can be empty. (e.g. [14021, 12939])
  name: string # Name of the account, how it gets represented in e.g. a "customers list". (e.g. Moonpeer Inc.)
]: any -> record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, billing_information: record<address: record<country: string, locality: string, post_office_box_number: string, postal_code: string, region: string, street_address: string>, name: string, vat_number: string>, discoverable: bool, external_ref: string, id: string, legal_name: string, managing_account: string, metro_area_network_presence: list<string>, name: string, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let req_body = {"address": $address, "billing_information": $billing_information, "discoverable": $discoverable, "external_ref": $external_ref, "legal_name": $legal_name, "managing_account": $managing_account, "metro_area_network_presence": $metro_area_network_presence, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reauthenticate the API user, issue a new `access_token` and `refresh_token` pair by providing the `refresh_token` in the request body.
#
# POST /auth/refresh
# operationId: auth_token_refresh
export def "auth-refresh refresh-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh_token: string
]: any -> record<access_token: string, refresh_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/refresh")
  let req_body = {"refresh_token": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authenticate an API user identified by `api_key` and `api_secret`.
#
# POST /auth/token
# operationId: auth_token_create
export def "auth-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  api_secret: string
]: any -> record<access_token: string, refresh_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let req_body = {"api_key": $api_key, "api_secret": $api_secret} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all `connection`s.
#
# GET /connections
# operationId: connections_list
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --mode: string # Filter by mode
  --mode-is-not: string # Filter by mode__is_not
  --name: string # Filter by name
  --metro-area-network: string # Filter by metro_area_network
  --pop: string # Filter by pop
  --facility: string # Filter by facility
  --external-ref: string # Filter by external_ref
]: nothing -> table<billing_account: string, consuming_account: string, contract_ref: string, external_ref: string, id: string, lacp_timeout: string, managing_account: string, mode: string, name: string, outer_vlan_ethertypes: list<string>, ports: list<string>, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: list<record>, vlan_types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "scalar") (serialize-qp "state__is_not" $state_is_not "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "mode__is_not" $mode_is_not "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "metro_area_network" $metro_area_network "scalar") (serialize-qp "pop" $pop "scalar") (serialize-qp "facility" $facility "scalar") (serialize-qp "external_ref" $external_ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "state__is_not": $state_is_not, "mode": $mode, "mode__is_not": $mode_is_not, "name": $name, "metro_area_network": $metro_area_network, "pop": $pop, "facility": $facility, "external_ref": $external_ref} | compact), body: null}
}

# Read a `connection`.
#
# GET /connections/{id}
# operationId: connections_read
export def "connections get" [
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
]: nothing -> record<billing_account: string, consuming_account: string, contract_ref: string, external_ref: string, id: string, lacp_timeout: string, managing_account: string, mode: string, name: string, outer_vlan_ethertypes: list<string>, ports: list<string>, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>, vlan_types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List available contacts managed by the authorized account.
#
# GET /contacts
# operationId: contacts_list
export def "contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
]: nothing -> table<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "consuming_account" $consuming_account "scalar") (serialize-qp "external_ref" $external_ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "managing_account": $managing_account, "consuming_account": $consuming_account, "external_ref": $external_ref} | compact), body: null}
}

# Create a new contact.
#
# POST /contacts
# operationId: contacts_create
export def "contacts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --email: string # The email of the legal company entity. (nullable, e.g. info@moon-peer.net)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --name: string # A name of a person or an organisation (nullable, e.g. Some A. Name)
  --telephone: string # The telephone number in E.164 Phone Number Formatting (nullable, e.g. +442071838750)
]: any -> record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts")
  let req_body = {"consuming_account": $consuming_account, "email": $email, "external_ref": $external_ref, "managing_account": $managing_account, "name": $name, "telephone": $telephone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a contact. Please note, that a contact can only be removed if it is not longer in use in a network service or config through a role assignment.
#
# DELETE /contacts/{id}
# operationId: contacts_destroy
export def "contacts delete" [
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
]: nothing -> record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a contact by it's id
#
# GET /contacts/{id}
# operationId: contacts_read
export def "contacts get" [
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
]: nothing -> record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update parts of a contact
#
# PATCH /contacts/{id}
# operationId: contacts_partial_update
export def "contacts update-by-id" [
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
  --body: any
]: any -> record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update a contact
#
# PUT /contacts/{id}
# operationId: contacts_update
export def "contacts update-by-id-1" [
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
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --email: string # The email of the legal company entity. (nullable, e.g. info@moon-peer.net)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --name: string # A name of a person or an organisation (nullable, e.g. Some A. Name)
  --telephone: string # The telephone number in E.164 Phone Number Formatting (nullable, e.g. +442071838750)
]: any -> record<consuming_account: string, email: string, external_ref: string, id: string, managing_account: string, name: string, telephone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/contacts/{id}"))
  let req_body = {"consuming_account": $consuming_account, "email": $email, "external_ref": $external_ref, "managing_account": $managing_account, "name": $name, "telephone": $telephone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List available devices
#
# GET /devices
# operationId: devices_list
export def "devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
  --capability-media-type: string # Filter by capability_media_type
  --capability-speed: int # Filter by capability_speed
  --capability-speed-lt: int # Filter by capability_speed__lt
  --capability-speed-lte: int # Filter by capability_speed__lte
  --capability-speed-gt: int # Filter by capability_speed__gt
  --capability-speed-gte: int # Filter by capability_speed__gte
  --facility: string # Filter by facility
  --pop: string # Filter by pop
  --metro-area-network: string # Filter by metro_area_network
]: nothing -> table<capabilities: list<record>, facility: string, id: string, name: string, pop: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "name" $name "scalar") (serialize-qp "capability_media_type" $capability_media_type "scalar") (serialize-qp "capability_speed" $capability_speed "scalar") (serialize-qp "capability_speed__lt" $capability_speed_lt "scalar") (serialize-qp "capability_speed__lte" $capability_speed_lte "scalar") (serialize-qp "capability_speed__gt" $capability_speed_gt "scalar") (serialize-qp "capability_speed__gte" $capability_speed_gte "scalar") (serialize-qp "facility" $facility "scalar") (serialize-qp "pop" $pop "scalar") (serialize-qp "metro_area_network" $metro_area_network "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "name": $name, "capability_media_type": $capability_media_type, "capability_speed": $capability_speed, "capability_speed__lt": $capability_speed_lt, "capability_speed__lte": $capability_speed_lte, "capability_speed__gt": $capability_speed_gt, "capability_speed__gte": $capability_speed_gte, "facility": $facility, "pop": $pop, "metro_area_network": $metro_area_network} | compact), body: null}
}

# Get a specific device identified by id
#
# GET /devices/{id}
# operationId: devices_read
export def "devices get" [
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
]: nothing -> record<capabilities: table<availability: int, max_lag: int, media_type: string, speed: int>, facility: string, id: string, name: string, pop: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/devices/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a (filtered) list of `facilities`.
#
# GET /facilities
# operationId: facilities_list
export def "facilities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --capability-media-type: string # Filter by capability_media_type
  --capability-speed: int # Filter by capability_speed
  --capability-speed-lt: int # Filter by capability_speed__lt
  --capability-speed-lte: int # Filter by capability_speed__lte
  --capability-speed-gt: int # Filter by capability_speed__gt
  --capability-speed-gte: int # Filter by capability_speed__gte
  --organisation-name: string # Filter by organisation_name
  --metro-area: string # Filter by metro_area
  --metro-area-network: string # Filter by metro_area_network
  --address-country: string # Filter by address_country
  --address-locality: string # Filter by address_locality
  --postal-code: string # Filter by postal_code
]: nothing -> table<address_country: string, address_locality: string, address_region: string, id: string, metro_area: string, name: string, organisation_name: string, peeringdb_facility_id: int, pops: list<string>, postal_code: string, street_address: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "capability_media_type" $capability_media_type "scalar") (serialize-qp "capability_speed" $capability_speed "scalar") (serialize-qp "capability_speed__lt" $capability_speed_lt "scalar") (serialize-qp "capability_speed__lte" $capability_speed_lte "scalar") (serialize-qp "capability_speed__gt" $capability_speed_gt "scalar") (serialize-qp "capability_speed__gte" $capability_speed_gte "scalar") (serialize-qp "organisation_name" $organisation_name "scalar") (serialize-qp "metro_area" $metro_area "scalar") (serialize-qp "metro_area_network" $metro_area_network "scalar") (serialize-qp "address_country" $address_country "scalar") (serialize-qp "address_locality" $address_locality "scalar") (serialize-qp "postal_code" $postal_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/facilities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "capability_media_type": $capability_media_type, "capability_speed": $capability_speed, "capability_speed__lt": $capability_speed_lt, "capability_speed__lte": $capability_speed_lte, "capability_speed__gt": $capability_speed_gt, "capability_speed__gte": $capability_speed_gte, "organisation_name": $organisation_name, "metro_area": $metro_area, "metro_area_network": $metro_area_network, "address_country": $address_country, "address_locality": $address_locality, "postal_code": $postal_code} | compact), body: null}
}

# Retrieve a facility by id
#
# GET /facilities/{id}
# operationId: facilities_read
export def "facilities get" [
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
]: nothing -> table<address_country: string, address_locality: string, address_region: string, id: string, metro_area: string, name: string, organisation_name: string, peeringdb_facility_id: int, pops: list<string>, postal_code: string, street_address: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/facilities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the IX-API service health status.
#
# GET /health
# operationId: api_health_read
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<checks: record, description: string, links: record, notes: list<string>, output: string, releaseId: string, serviceId: string, status: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the API implementation details.
#
# GET /implementation
# operationId: api_implementation_read
export def "implementation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schema_version: string, service_version: string, supported_network_feature_config_types: list<string>, supported_network_feature_types: list<string>, supported_network_service_config_types: list<string>, supported_network_service_types: list<string>, supported_operations: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/implementation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all ip addresses (and prefixes).
#
# GET /ips
# operationId: ips_list
export def "ips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --network-service: string # Filter by network_service
  --network-service-config: string # Filter by network_service_config
  --network-feature: string # Filter by network_feature
  --network-feature-config: string # Filter by network_feature_config
  --version: int # Filter by version
  --fqdn: string # Filter by fqdn
  --prefix-length: int # Filter by prefix_length
  --valid-not-before: string # Filter by valid_not_before
  --valid-not-after: string # Filter by valid_not_after
]: nothing -> table<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "consuming_account" $consuming_account "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "network_service" $network_service "scalar") (serialize-qp "network_service_config" $network_service_config "scalar") (serialize-qp "network_feature" $network_feature "scalar") (serialize-qp "network_feature_config" $network_feature_config "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "fqdn" $fqdn "scalar") (serialize-qp "prefix_length" $prefix_length "scalar") (serialize-qp "valid_not_before" $valid_not_before "scalar") (serialize-qp "valid_not_after" $valid_not_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "managing_account": $managing_account, "consuming_account": $consuming_account, "external_ref": $external_ref, "network_service": $network_service, "network_service_config": $network_service_config, "network_feature": $network_feature, "network_feature_config": $network_feature_config, "version": $version, "fqdn": $fqdn, "prefix_length": $prefix_length, "valid_not_before": $valid_not_before, "valid_not_after": $valid_not_after} | compact), body: null}
}

# Add an ip host address or network prefix.
#
# POST /ips
# operationId: ips_create
export def "ips create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # IPv4 or IPv6 Address in the following format: - IPv4: [dot-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation) - IPv6: hexadecimal colon separated notation (e.g. 23.142.52.0)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --fqdn: string # nullable
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  prefix_length: int # The CIDR ip prefix length (format: int32, e.g. 23)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
  version: int # The version of the internet protocol. (e.g. 4)
]: any -> record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips")
  let req_body = {"address": $address, "consuming_account": $consuming_account, "external_ref": $external_ref, "fqdn": $fqdn, "managing_account": $managing_account, "prefix_length": $prefix_length, "valid_not_after": $valid_not_after, "valid_not_before": $valid_not_before, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a single ip addresses by it's id.
#
# GET /ips/{id}
# operationId: ips_read
export def "ips get" [
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
]: nothing -> record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ips/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update parts of an ip address. As with the `PUT` opertaion, IP addresses, where you don't have update rights, will yield a `resource access denied` error when attempting an update. If the ip address was allocated for you, you might not be able to change anything but the `fqdn`.
#
# PATCH /ips/{id}
# operationId: ips_partial_update
export def "ips update-by-id" [
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
  --body: any
]: any -> record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ips/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update an ip address object. You can only update IP addresses within your current scope. Not all addresses you can read you can update. If the ip address was allocated for you, you might not be able to change anything but the `fqdn`.
#
# PUT /ips/{id}
# operationId: ips_update
export def "ips update-by-id-1" [
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
  address: string # IPv4 or IPv6 Address in the following format: - IPv4: [dot-decimal notation](https://en.wikipedia.org/wiki/Dot-decimal_notation) - IPv6: hexadecimal colon separated notation (e.g. 23.142.52.0)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  --fqdn: string # nullable
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  prefix_length: int # The CIDR ip prefix length (format: int32, e.g. 23)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
  version: int # The version of the internet protocol. (e.g. 4)
]: any -> record<address: string, consuming_account: string, external_ref: string, fqdn: string, id: string, managing_account: string, prefix_length: int, valid_not_after: string, valid_not_before: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ips/{id}"))
  let req_body = {"address": $address, "consuming_account": $consuming_account, "external_ref": $external_ref, "fqdn": $fqdn, "managing_account": $managing_account, "prefix_length": $prefix_length, "valid_not_after": $valid_not_after, "valid_not_before": $valid_not_before, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all mac addresses managed by the authorized customer.
#
# GET /macs
# operationId: macs_list
export def "macs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --network-service-config: string # Filter by network_service_config
  --address: string # Filter by address
  --assigned-at: string # Filter by assigned_at
  --valid-not-before: string # Filter by valid_not_before
  --valid-not-after: string # Filter by valid_not_after
]: nothing -> table<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "consuming_account" $consuming_account "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "network_service_config" $network_service_config "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "assigned_at" $assigned_at "scalar") (serialize-qp "valid_not_before" $valid_not_before "scalar") (serialize-qp "valid_not_after" $valid_not_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/macs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "managing_account": $managing_account, "consuming_account": $consuming_account, "external_ref": $external_ref, "network_service_config": $network_service_config, "address": $address, "assigned_at": $assigned_at, "valid_not_before": $valid_not_before, "valid_not_after": $valid_not_after} | compact), body: null}
}

# Register a mac address.
#
# POST /macs
# operationId: macs_create
export def "macs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Unicast MAC address, formatted hexadecimal values with colons. (e.g. 42:23:bc:8e:b8:b0)
  consuming_account: string # The `id` of the account consuming a service. Used to be `owning_customer`. (e.g. 2381982)
  --external-ref: string # Reference field, free to use for the API user. (nullable, e.g. IX:Service:23042)
  managing_account: string # The `id` of the account responsible for managing the service via the API. A manager can read and update the state of entities. (e.g. 238189294)
  --valid-not-after: string # nullable, format: date-time
  --valid-not-before: string # nullable, format: date-time
]: any -> record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/macs")
  let req_body = {"address": $address, "consuming_account": $consuming_account, "external_ref": $external_ref, "managing_account": $managing_account, "valid_not_after": $valid_not_after, "valid_not_before": $valid_not_before} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a mac address.
#
# DELETE /macs/{id}
# operationId: macs_destroy
export def "macs delete" [
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
]: nothing -> record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/macs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single mac address by it's id.
#
# GET /macs/{id}
# operationId: macs_read
export def "macs get" [
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
]: nothing -> record<address: string, consuming_account: string, external_ref: string, id: string, managing_account: string, valid_not_after: string, valid_not_before: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/macs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of joining rules
#
# GET /member-joining-rules
# operationId: member_joining_rules_list
export def "member-joining-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --network-service: string # Filter by network_service
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "network_service" $network_service "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/member-joining-rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "network_service": $network_service} | compact), body: null}
}

# Create a member joining rule
#
# POST /member-joining-rules
# Discriminator (request): type = allow, deny
# operationId: member_joining_rules_create
export def "member-joining-rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/member-joining-rules")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a joining rule
#
# DELETE /member-joining-rules/{id}
# Discriminator (response): type = allow, deny
# operationId: member_joining_rules_destroy
export def "member-joining-rules delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/member-joining-rules/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single rule
#
# GET /member-joining-rules/{id}
# Discriminator (response): type = allow, deny
# operationId: member_joining_rules_read
export def "member-joining-rules get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/member-joining-rules/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Partially update a joining rule
#
# PATCH /member-joining-rules/{id}
# Discriminator (request): type = allow, deny
# operationId: member_joining_rules_partial_update
export def "member-joining-rules update-by-id" [
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
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/member-joining-rules/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update a joining rule
#
# PUT /member-joining-rules/{id}
# Discriminator (request): type = allow, deny
# operationId: member_joining_rules_update
export def "member-joining-rules update-by-id-1" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/member-joining-rules/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all MetroAreaNetworks
#
# GET /metro-area-networks
# operationId: metro_area_networks_list
export def "metro-area-networks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
  --metro-area: string # Filter by metro_area
  --service-provider: string # Filter by service_provider
]: nothing -> table<id: string, metro_area: string, name: string, pops: list<string>, service_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "name" $name "scalar") (serialize-qp "metro_area" $metro_area "scalar") (serialize-qp "service_provider" $service_provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metro-area-networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "name": $name, "metro_area": $metro_area, "service_provider": $service_provider} | compact), body: null}
}

# Retrieve a MetroAreaNetwork
#
# GET /metro-area-networks/{id}
# operationId: metro_area_networks_read
export def "metro-area-networks get" [
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
]: nothing -> record<id: string, metro_area: string, name: string, pops: list<string>, service_provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/metro-area-networks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all MetroAreas
#
# GET /metro-areas
# operationId: metro_areas_list
export def "metro-areas list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
]: nothing -> table<display_name: string, facilities: list<string>, iata_code: string, id: string, metro_area_networks: list<string>, un_locode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/metro-areas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Get a single MetroArea
#
# GET /metro-areas/{id}
# operationId: metro_areas_read
export def "metro-areas get" [
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
]: nothing -> table<display_name: string, facilities: list<string>, iata_code: string, id: string, metro_area_networks: list<string>, un_locode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/metro-areas/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all network feature configs.
#
# GET /network-feature-configs
# operationId: network_feature_configs_list
export def "network-feature-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --type: string@type-completer # Filter by type
  --service-config: string # Filter by service_config
  --network-feature: string # Filter by network_feature
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "scalar") (serialize-qp "state__is_not" $state_is_not "scalar") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "consuming_account" $consuming_account "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "service_config" $service_config "scalar") (serialize-qp "network_feature" $network_feature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network-feature-configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "state__is_not": $state_is_not, "managing_account": $managing_account, "consuming_account": $consuming_account, "external_ref": $external_ref, "type": $type, "service_config": $service_config, "network_feature": $network_feature} | compact), body: null}
}

# Create a configuration for a `NetworkFeature` defined in the `NetworkFeature`s collection.
#
# POST /network-feature-configs
# Discriminator (request): type = route_server
# operationId: network_feature_configs_create
export def "network-feature-configs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network-feature-configs")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a network feature config. The network feature config will be marked as `decommission_requested`. Decommissioning a network feature config will not cascade to related services or service configs.
#
# DELETE /network-feature-configs/{id}
# Discriminator (response): type = route_server
# operationId: network_feature_configs_destroy
export def "network-feature-configs delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-feature-configs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single network feature config.
#
# GET /network-feature-configs/{id}
# Discriminator (response): type = route_server
# operationId: network_feature_configs_read
export def "network-feature-configs get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-feature-configs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update parts of a network feature configuration
#
# PATCH /network-feature-configs/{id}
# Discriminator (request): type = route_server
# operationId: network_feature_configs_partial_update
export def "network-feature-configs update-by-id" [
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
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-feature-configs/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update a network feature configuration
#
# PUT /network-feature-configs/{id}
# Discriminator (request): type = route_server
# operationId: network_feature_configs_update
export def "network-feature-configs update-by-id-1" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-feature-configs/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List available network features.
#
# GET /network-features
# operationId: network_features_list
export def "network-features list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --type: string@type-completer # Filter by type
  --required: string # Filter by required
  --network-service: string # Filter by network_service
  --name: string # Filter by name
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "type" $type "scalar") (serialize-qp "required" $required "scalar") (serialize-qp "network_service" $network_service "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network-features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "type": $type, "required": $required, "network_service": $network_service, "name": $name} | compact), body: null}
}

# Get a single network feature by it's id.
#
# GET /network-features/{id}
# Discriminator (response): type = route_server
# operationId: network_features_read
export def "network-features get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-features/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all `network-service-config`s.
#
# GET /network-service-configs
# operationId: network_service_configs_list
export def "network-service-configs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --type: string@type-completer-1 # Filter by type
  --inner-vlan: int # Filter by inner_vlan
  --outer-vlan: int # Filter by outer_vlan
  --capacity: int # Filter by capacity
  --network-service: string # Filter by network_service
  --connection: string # Filter by connection
  --product-offering: string # Filter by product_offering
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "scalar") (serialize-qp "state__is_not" $state_is_not "scalar") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "consuming_account" $consuming_account "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "inner_vlan" $inner_vlan "scalar") (serialize-qp "outer_vlan" $outer_vlan "scalar") (serialize-qp "capacity" $capacity "scalar") (serialize-qp "network_service" $network_service "scalar") (serialize-qp "connection" $connection "scalar") (serialize-qp "product_offering" $product_offering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network-service-configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "state__is_not": $state_is_not, "managing_account": $managing_account, "consuming_account": $consuming_account, "external_ref": $external_ref, "type": $type, "inner_vlan": $inner_vlan, "outer_vlan": $outer_vlan, "capacity": $capacity, "network_service": $network_service, "connection": $connection, "product_offering": $product_offering} | compact), body: null}
}

# Create a `network-service-config`.
#
# POST /network-service-configs
# Discriminator (request): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_create
export def "network-service-configs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network-service-configs")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request decommissioning the network service configuration. The network service config will assume the state `decommission_requested`. This will cascade to related resources like `network-feature-configs`.
#
# DELETE /network-service-configs/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_destroy
export def "network-service-configs delete" [
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
  --decommission-at: string # An optional date for scheduling the cancellation and service decommissioning. (format: date)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-service-configs/{id}"))
  let req_body = {"decommission_at": $decommission_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a `network-service-config`
#
# GET /network-service-configs/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_read
export def "network-service-configs get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-service-configs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update parts of an exisiting `network-service-config`.
#
# PATCH /network-service-configs/{id}
# Discriminator (request): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_partial_update
export def "network-service-configs update-by-id" [
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
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-service-configs/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update an exisiting `network-service-config`
#
# PUT /network-service-configs/{id}
# Discriminator (request): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_service_configs_update
export def "network-service-configs update-by-id-1" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-service-configs/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The cancellation-policy can be queried to answer the questions: If I cancel my subscription, *when will it be technically decommissioned*? If I cancel my subscription, *until what date will I be charged*? When the query parameter `decommision_at` is not provided it will provide the first possible cancellation date and charge period if cancelled at above date. The granularity of the date field is a day, the start and end of which are to be interpreted by the IXP (some may use UTC, some may use their local time zone).
#
# GET /network-service-configs/{id}/cancellation-policy
# operationId: network_service_config_cancellation_policy_read
export def "network-service-configs-cancellation-policy get" [
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
  --decommission-at: string # By providing a date in the format `YYYY-MM-DD` you can query the policy what would happen if you request a decommissioning on this date.
]: nothing -> record<charged_until: string, decommission_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "decommission_at" $decommission_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-service-configs/{id}/cancellation-policy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"decommission_at": $decommission_at} | compact), body: null}
}

# List available `NetworkService`s.
#
# GET /network-services
# operationId: network_services_list
export def "network-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --managing-account: string # Filter by managing_account
  --consuming-account: string # Filter by consuming_account
  --external-ref: string # Filter by external_ref
  --type: string@type-completer-1 # Filter by type
  --pop: string # Filter by pop
  --product-offering: string # Filter by product_offering
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "scalar") (serialize-qp "state__is_not" $state_is_not "scalar") (serialize-qp "managing_account" $managing_account "scalar") (serialize-qp "consuming_account" $consuming_account "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pop" $pop "scalar") (serialize-qp "product_offering" $product_offering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network-services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "state__is_not": $state_is_not, "managing_account": $managing_account, "consuming_account": $consuming_account, "external_ref": $external_ref, "type": $type, "pop": $pop, "product_offering": $product_offering} | compact), body: null}
}

# Create a new network service
#
# POST /network-services
# Discriminator (request): type = cloud_vc, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_create
export def "network-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network-services")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request decomissioning of the network service. The network service will enter the state of `decommission_requested`. The request will cascade to related network service and feature configs. An *optional request body* can be provided to request a specific service termination date. If no date is given in the request body, it is assumed to be the earliest possible date. Possible values for `decommission_at` can be queried through the `network_service_cancellation_policy_read` operation. The response will contain the dates on which the changes will be effected.
#
# DELETE /network-services/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_destroy
export def "network-services delete" [
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
  --decommission-at: string # An optional date for scheduling the cancellation and service decommissioning. (format: date)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}"))
  let req_body = {"decommission_at": $decommission_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a specific `network-service` by id.
#
# GET /network-services/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_read
export def "network-services get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Partially update a network service
#
# PATCH /network-services/{id}
# Discriminator (request): type = cloud_vc, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_partial_update
export def "network-services update-by-id" [
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
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/merge-patch+json" $req_body {query: {}, body: $req_body}
}

# Update a network service
#
# PUT /network-services/{id}
# Discriminator (request): type = cloud_vc, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: network_services_update
export def "network-services update-by-id-1" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The cancellation-policy can be queried to answer the questions: If I cancel my service, *when will it be technically decommissioned*? If I cancel my service, *until what date will I be charged*? When the query parameter `decommision_at` is not provided it will provide the first possible cancellation date and charge period if cancelled at above date. The granularity of the date field is a day, the start and end of which are to be interpreted by the IXP (some may use UTC, some may use their local time zone).
#
# GET /network-services/{id}/cancellation-policy
# operationId: network_service_cancellation_policy_read
export def "network-services-cancellation-policy get" [
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
  --decommission-at: string # By providing a date in the format `YYYY-MM-DD` you can query the policy what would happen if you request a decommissioning on this date.
]: nothing -> record<charged_until: string, decommission_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "decommission_at" $decommission_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}/cancellation-policy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"decommission_at": $decommission_at} | compact), body: null}
}

# Retract or reject a change to the network service.
#
# DELETE /network-services/{id}/change-request
# operationId: network_service_change_request_destroy
export def "network-services-change-request delete" [
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
]: nothing -> record<capacity: int, product_offering: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}/change-request"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the change request.
#
# GET /network-services/{id}/change-request
# operationId: network_service_change_request_read
export def "network-services-change-request get" [
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
]: nothing -> record<capacity: int, product_offering: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}/change-request"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request a change to the network service. A participant in a network service of type `p2p_vc` can issue a change request, expressing a desired change in the capacity. The change is accepted when all sides have configured the network service configs with the new bandwidth. These changes can sometimes require a change of the product offering. The product offering may only differ in regards to bandwidth. The network service will change it's state from `production` into `production_change_pending`. Only one change request may be issued at a time.
#
# POST /network-services/{id}/change-request
# operationId: network-service-change-request_create
export def "network-services-change-request create" [
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
  --capacity: int # The desired capacity of the service in Mbps. Must be within the range of `bandwidth_min` and `bandwidth_max` of the `ProductOffering`. When `null` the maximum capacity wil be used. (nullable)
  product_offering: string # Migrate to a diffrent product offering. Please note, that the offering only may differ in bandwidth.
]: any -> record<capacity: int, product_offering: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/network-services/{id}/change-request"))
  let req_body = {"capacity": $capacity, "product_offering": $product_offering} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all PoPs
#
# GET /pops
# operationId: pops_list
export def "pops list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --facility: string # Filter by facility
  --metro-area-network: string # Filter by metro_area_network
  --capability-media-type: string # Filter by capability_media_type
  --capability-speed: int # Filter by capability_speed
  --capability-speed-lt: int # Filter by capability_speed__lt
  --capability-speed-lte: int # Filter by capability_speed__lte
  --capability-speed-gt: int # Filter by capability_speed__gt
  --capability-speed-gte: int # Filter by capability_speed__gte
]: nothing -> table<devices: list<string>, facility: string, id: string, metro_area_network: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "facility" $facility "scalar") (serialize-qp "metro_area_network" $metro_area_network "scalar") (serialize-qp "capability_media_type" $capability_media_type "scalar") (serialize-qp "capability_speed" $capability_speed "scalar") (serialize-qp "capability_speed__lt" $capability_speed_lt "scalar") (serialize-qp "capability_speed__lte" $capability_speed_lte "scalar") (serialize-qp "capability_speed__gt" $capability_speed_gt "scalar") (serialize-qp "capability_speed__gte" $capability_speed_gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pops" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "facility": $facility, "metro_area_network": $metro_area_network, "capability_media_type": $capability_media_type, "capability_speed": $capability_speed, "capability_speed__lt": $capability_speed_lt, "capability_speed__lte": $capability_speed_lte, "capability_speed__gt": $capability_speed_gt, "capability_speed__gte": $capability_speed_gte} | compact), body: null}
}

# Get a single point of presence
#
# GET /pops/{id}
# operationId: pops_read
export def "pops get" [
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
]: nothing -> record<devices: list<string>, facility: string, id: string, metro_area_network: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/pops/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all ports.
#
# GET /ports
# operationId: ports_list
export def "ports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --state: string # Filter by state
  --state-is-not: string # Filter by state__is_not
  --media-type: string # Filter by media_type
  --pop: string # Filter by pop
  --name: string # Filter by name
  --external-ref: string # Filter by external_ref
  --device: string # Filter by device
  --speed: string # Filter by speed
  --connection: string # Filter by connection
]: nothing -> table<billing_account: string, connection: string, consuming_account: string, contract_ref: string, device: string, external_ref: string, id: string, managing_account: string, media_type: string, name: string, pop: string, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "state" $state "scalar") (serialize-qp "state__is_not" $state_is_not "scalar") (serialize-qp "media_type" $media_type "scalar") (serialize-qp "pop" $pop "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "external_ref" $external_ref "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "speed" $speed "scalar") (serialize-qp "connection" $connection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "state__is_not": $state_is_not, "media_type": $media_type, "pop": $pop, "name": $name, "external_ref": $external_ref, "device": $device, "speed": $speed, "connection": $connection} | compact), body: null}
}

# Retrieve a port.
#
# GET /ports/{id}
# operationId: ports_read
export def "ports get" [
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
]: nothing -> record<billing_account: string, connection: string, consuming_account: string, contract_ref: string, device: string, external_ref: string, id: string, managing_account: string, media_type: string, name: string, pop: string, purchase_order: string, role_assignments: list<string>, speed: int, state: string, status: table<attrs: record, message: string, severity: int, tag: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all (filtered) products-offerings available on the platform
#
# GET /product-offerings
# operationId: product_offerings_list
export def "product-offerings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --type: string@type-completer-1 # Filter by type
  --name: string # Filter by name
  --handover-metro-area: string # Filter by handover_metro_area
  --handover-metro-area-network: string # Filter by handover_metro_area_network
  --service-metro-area: string # Filter by service_metro_area
  --service-metro-area-network: string # Filter by service_metro_area_network
  --service-provider: string # Filter by service_provider
  --downgrade-allowed: string@downgrade-allowed-completer # Filter by downgrade_allowed
  --upgrade-allowed: string@upgrade-allowed-completer # Filter by upgrade_allowed
  --bandwidth: int # Find product offerings where bandwidth is within the range of `bandwidth_min` and `bandwidth_max`.
  --physical-port-speed: int # Filter by physical_port_speed
  --service-provider-region: string # Filter by service_provider_region
  --service-provider-pop: string # Filter by service_provider_pop
  --delivery-method: string@delivery-method-completer # Filter by delivery_method
  --cloud-key: string # For product offerings of type `cloud_vc`, if the `service_provider_workflow` is `provider_first` the `cloud_key` will be used for filtering the relevant offerings.
  --fields: string # Returned objects only have properties which are present in the list of fields. The required `type` property is *implicitly* included. The results are *deduplicated*. (e.g. handover_metro_area,service_provider)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "handover_metro_area" $handover_metro_area "scalar") (serialize-qp "handover_metro_area_network" $handover_metro_area_network "scalar") (serialize-qp "service_metro_area" $service_metro_area "scalar") (serialize-qp "service_metro_area_network" $service_metro_area_network "scalar") (serialize-qp "service_provider" $service_provider "scalar") (serialize-qp "downgrade_allowed" $downgrade_allowed "scalar") (serialize-qp "upgrade_allowed" $upgrade_allowed "scalar") (serialize-qp "bandwidth" $bandwidth "scalar") (serialize-qp "physical_port_speed" $physical_port_speed "scalar") (serialize-qp "service_provider_region" $service_provider_region "scalar") (serialize-qp "service_provider_pop" $service_provider_pop "scalar") (serialize-qp "delivery_method" $delivery_method "scalar") (serialize-qp "cloud_key" $cloud_key "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product-offerings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "type": $type, "name": $name, "handover_metro_area": $handover_metro_area, "handover_metro_area_network": $handover_metro_area_network, "service_metro_area": $service_metro_area, "service_metro_area_network": $service_metro_area_network, "service_provider": $service_provider, "downgrade_allowed": $downgrade_allowed, "upgrade_allowed": $upgrade_allowed, "bandwidth": $bandwidth, "physical_port_speed": $physical_port_speed, "service_provider_region": $service_provider_region, "service_provider_pop": $service_provider_pop, "delivery_method": $delivery_method, "cloud_key": $cloud_key, "fields": $fields} | compact), body: null}
}

# Get a single products-offering by id.
#
# GET /product-offerings/{id}
# Discriminator (response): type = cloud_vc, exchange_lan, mp2mp_vc, p2mp_vc, p2p_vc
# operationId: product_offerings_read
export def "product-offerings get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/product-offerings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all role assignments for a contact.
#
# GET /role-assignments
# operationId: role_assignments_list
export def "role-assignments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --contact: string # Filter by contact
  --role: string # Filter by role
]: nothing -> table<contact: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "contact" $contact "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/role-assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "contact": $contact, "role": $role} | compact), body: null}
}

# Assign a `Role` to a `Contact`. The contact needs to have all fields filled, which the role requires. If this is not the case a `400` `UnableToFulfill` will be returned.
#
# POST /role-assignments
# operationId: role_assignments_create
export def "role-assignments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  contact: string # The `id` of a contact the role is assigned to. (e.g. contact:42b)
  role: string # The `id` of a role the contact is assigned to. (e.g. role:23)
]: any -> record<contact: string, id: string, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/role-assignments")
  let req_body = {"contact": $contact, "role": $role} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a role assignment from a contact. If the contact is still in use with a given role required, this will yield an `UnableToFulfill` error.
#
# DELETE /role-assignments/{assignment_id}
# operationId: role_assignments_destroy
export def "role-assignments delete" [
  assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contact: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($assignment_id | is-empty) { error make --unspanned { msg: "path parameter 'assignment_id' must be non-empty" } }
  let full_url = (build-url $base ({assignment_id: (encode-path-segment $assignment_id)} | format pattern "/role-assignments/{assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a role assignment for a contact.
#
# GET /role-assignments/{assignment_id}
# operationId: role_assignments_read
export def "role-assignments get" [
  assignment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contact: string, id: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($assignment_id | is-empty) { error make --unspanned { msg: "path parameter 'assignment_id' must be non-empty" } }
  let full_url = (build-url $base ({assignment_id: (encode-path-segment $assignment_id)} | format pattern "/role-assignments/{assignment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all roles available.
#
# GET /roles
# operationId: roles_list
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
  --contact: string # Filter by contact
]: nothing -> table<id: string, name: string, required_fields: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "name" $name "scalar") (serialize-qp "contact" $contact "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "name": $name, "contact": $contact} | compact), body: null}
}

# Get a single `Role`.
#
# GET /roles/{id}
# operationId: roles_read
export def "roles get" [
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
  --id: list<string> # Filter by id (e.g. id1,id2,id3)
  --name: string # Filter by name
]: nothing -> record<id: string, name: string, required_fields: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/roles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "name": $name} | compact), body: null}
}
