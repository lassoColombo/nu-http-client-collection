# Auto-generated client for Data2CRM.API v1
# Source: https://api.apis.guru/v2/specs/data2crm.com/1/swagger.json
# Auth: --token flag or $env.DATA2CRM_API_TOKEN

const BASE_URL = "https://api-2445581398133.apicast.io:443/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATA2CRM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api-2445581398133.apicast.io:443/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["Act" "ActPremiumWeb" "AgileCRM" "AmoCRM" "BaseCRM" "Bitrix24" "CapsuleCRM" "CloseIO" "FreshSales" "GSuite" "Highrise" "HubSpot" "Infusionsoft" "Insightly" "Marketo" "MicrosoftDynamics" "Odoo" "Pipedrive" "PipelineDeals" "ProsperWorks" "Salesforce" "SalesforceSandbox" "Solve360" "SugarCRM" "SuiteCRM" "Vtiger" "ZohoCRM"] }
def x-api2crm-native-enable-completer [] { ["false" "true"] }
def x-api2crm-data-enable-completer [] { ["false" "true"] }
def x-api2crm-data-build-completer [] { ["false"] }
def x-api2crm-data-is-final-completer [] { ["false" "true"] }
def x-api2crm-data-strategy-completer [] { ["simple"] }
def x-api2crm-data-always-actual-completer [] { ["true"] }
def unique-completer [] { ["false" "true"] }
def entity-completer [] { ["account" "attachment" "call" "campaign" "case" "comment" "contact" "email" "event" "invoice" "invoiceItem" "lead" "meeting" "note" "opportunity" "opportunityProduct" "post" "priceBook" "priceBookItem" "product" "project" "quote" "quoteItem" "tag" "task" "ticket" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application create-entity" } } | get name | first)
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

# POST for application
#
# POST /application
# operationId: createApplicationEntity
export def "application create-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # API2CRM user key
  --authorization: string # Application authorization
  --credential: record
  --description: string # Application description
  --type: string@type-completer # Application platform type
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application")
  let req_body = {"authorization": $authorization, "credential": $credential, "description": $description, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for application
#
# GET /application/count
# operationId: getApplicationCountCollection
export def "application-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # API2CRM user key
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# POST for account
#
# POST /application/entity/account
# operationId: createAccountEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --annual-revenue: string # Annual Revenue (e.g. 23244.43552)
  --category: string # Category (e.g. General)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Some long description)
  --email: list # Email — item shape: {address?: string, type?: string}
  --employees: string # Employees (e.g. 230)
  --id: string # Account Identifier (e.g. 21312411)
  --industry: list<string> # Industry
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --name: string # Name (e.g. Bill Wall)
  --ownership: string # Ownership (e.g. Public)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --rating: string # Rating (e.g. Active)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sic-code: string # SIC Code (e.g. 2895-1)
  --ticker-symbol: string # Ticker Symbol (e.g. %)
  --type: string # Type (e.g. Company)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/account")
  let req_body = {"address": $address, "annual_revenue": $annual_revenue, "category": $category, "created_at": $created_at, "description": $description, "email": $email, "employees": $employees, "id": $id, "industry": $industry, "messenger": $messenger, "name": $name, "ownership": $ownership, "phone": $phone, "rating": $rating, "relation": $relation, "sic_code": $sic_code, "ticker_symbol": $ticker_symbol, "type": $type, "updated_at": $updated_at, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for account
#
# GET /application/entity/account/aggregate
# operationId: getAccountAggregate
export def "application-entity-account-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/account/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for account
#
# DELETE /application/entity/account/bulk
# operationId: deleteAccountCollectionBulk
export def "application-entity-account-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/account/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for account
#
# POST /application/entity/account/bulk
# operationId: createAccountEntityBulk
export def "application-entity-account-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/account/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for account
#
# PUT /application/entity/account/bulk
# operationId: updateAccountEntityBulk
export def "application-entity-account-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/account/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for account
#
# GET /application/entity/account/count
# operationId: getAccountCountCollection
export def "application-entity-account-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/account/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for account
#
# GET /application/entity/account/describe
# operationId: getAccountDescribe
export def "application-entity-account-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/account/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for account
#
# GET /application/entity/account/list
# operationId: getAccountCollection
export def "application-entity-account-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<address: list<record>, annual_revenue: string, category: string, created_at: string, description: string, email: list<record>, employees: string, id: string, industry: list<string>, messenger: list<record>, name: string, ownership: string, phone: list<record>, rating: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, sic_code: string, ticker_symbol: string, type: string, updated_at: string, website: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/account/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for account
#
# DELETE /application/entity/account/{account_id}
# operationId: deleteAccountEntity
export def "application-entity-account delete" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/application/entity/account/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for account
#
# GET /application/entity/account/{account_id}
# operationId: getAccountEntity
export def "application-entity-account get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<address: table<city: string, country: string, state: string, street: string, type: string, zip: string>, annual_revenue: string, category: string, created_at: string, description: string, email: table<address: string, type: string>, employees: string, id: string, industry: list<string>, messenger: table<location: string, type: string>, name: string, ownership: string, phone: table<number: string, type: string>, rating: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, sic_code: string, ticker_symbol: string, type: string, updated_at: string, website: table<address: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/application/entity/account/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for account
#
# PUT /application/entity/account/{account_id}
# operationId: updateAccountEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-account update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --annual-revenue: string # Annual Revenue (e.g. 23244.43552)
  --category: string # Category (e.g. General)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Some long description)
  --email: list # Email — item shape: {address?: string, type?: string}
  --employees: string # Employees (e.g. 230)
  --id: string # Account Identifier (e.g. 21312411)
  --industry: list<string> # Industry
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --name: string # Name (e.g. Bill Wall)
  --ownership: string # Ownership (e.g. Public)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --rating: string # Rating (e.g. Active)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sic-code: string # SIC Code (e.g. 2895-1)
  --ticker-symbol: string # Ticker Symbol (e.g. %)
  --type: string # Type (e.g. Company)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/application/entity/account/{account_id}"))
  let req_body = {"address": $address, "annual_revenue": $annual_revenue, "category": $category, "created_at": $created_at, "description": $description, "email": $email, "employees": $employees, "id": $id, "industry": $industry, "messenger": $messenger, "name": $name, "ownership": $ownership, "phone": $phone, "rating": $rating, "relation": $relation, "sic_code": $sic_code, "ticker_symbol": $ticker_symbol, "type": $type, "updated_at": $updated_at, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for attachment
#
# POST /application/entity/attachment
# operationId: createAttachmentEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-attachment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of attachment)
  --link: string # Link (e.g. http://s-10.server.host.com/f/2015/01/01/a/file.json)
  --mime-type: string # Mime Type (e.g. application/json)
  --name: string # Name (e.g. file.json)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --size: int # Size (in bytes) (format: int32, e.g. 34345)
  --title: string # Title (e.g. Employees List File (json))
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/attachment")
  let req_body = {"created_at": $created_at, "description": $description, "link": $link, "mime_type": $mime_type, "name": $name, "relation": $relation, "size": $size, "title": $title, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for attachment
#
# GET /application/entity/attachment/aggregate
# operationId: getAttachmentAggregate
export def "application-entity-attachment-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/attachment/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for attachment
#
# DELETE /application/entity/attachment/bulk
# operationId: deleteAttachmentCollectionBulk
export def "application-entity-attachment-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/attachment/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for attachment
#
# POST /application/entity/attachment/bulk
# operationId: createAttachmentEntityBulk
export def "application-entity-attachment-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/attachment/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for attachment
#
# PUT /application/entity/attachment/bulk
# operationId: updateAttachmentEntityBulk
export def "application-entity-attachment-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/attachment/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for attachment
#
# GET /application/entity/attachment/count
# operationId: getAttachmentCountCollection
export def "application-entity-attachment-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/attachment/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for attachment
#
# GET /application/entity/attachment/describe
# operationId: getAttachmentDescribe
export def "application-entity-attachment-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/attachment/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for attachment
#
# GET /application/entity/attachment/list
# operationId: getAttachmentCollection
export def "application-entity-attachment-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, id: string, link: string, mime_type: string, name: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, size: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/attachment/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for attachment
#
# DELETE /application/entity/attachment/{attachment_id}
# operationId: deleteAttachmentEntity
export def "application-entity-attachment delete" [
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({attachment_id: (encode-path-segment $attachment_id)} | format pattern "/application/entity/attachment/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for attachment
#
# GET /application/entity/attachment/{attachment_id}
# operationId: getAttachmentEntity
export def "application-entity-attachment get" [
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, id: string, link: string, mime_type: string, name: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, size: int, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attachment_id: (encode-path-segment $attachment_id)} | format pattern "/application/entity/attachment/{attachment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for attachment
#
# PUT /application/entity/attachment/{attachment_id}
# operationId: updateAttachmentEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-attachment update" [
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of attachment)
  --link: string # Link (e.g. http://s-10.server.host.com/f/2015/01/01/a/file.json)
  --mime-type: string # Mime Type (e.g. application/json)
  --name: string # Name (e.g. file.json)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --size: int # Size (in bytes) (format: int32, e.g. 34345)
  --title: string # Title (e.g. Employees List File (json))
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let full_url = (build-url $base ({attachment_id: (encode-path-segment $attachment_id)} | format pattern "/application/entity/attachment/{attachment_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "link": $link, "mime_type": $mime_type, "name": $name, "relation": $relation, "size": $size, "title": $title, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for call
#
# POST /application/entity/call
# operationId: createCallEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-call create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of the call)
  --direction: string # Direction (e.g. Inbound)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Call Identifier (e.g. 21312411)
  --purpose: string # Purpose (e.g. Negotiation)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --result: string # Result (e.g. Confirmed)
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. Planned)
  --subject: string # Subject (e.g. Subject of the call)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/call")
  let req_body = {"created_at": $created_at, "description": $description, "direction": $direction, "ended_at": $ended_at, "id": $id, "purpose": $purpose, "relation": $relation, "result": $result, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for call
#
# GET /application/entity/call/aggregate
# operationId: getCallAggregate
export def "application-entity-call-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/call/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for call
#
# DELETE /application/entity/call/bulk
# operationId: deleteCallCollectionBulk
export def "application-entity-call-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/call/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for call
#
# POST /application/entity/call/bulk
# operationId: createCallEntityBulk
export def "application-entity-call-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/call/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for call
#
# PUT /application/entity/call/bulk
# operationId: updateCallEntityBulk
export def "application-entity-call-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/call/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for call
#
# GET /application/entity/call/count
# operationId: getCallCountCollection
export def "application-entity-call-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/call/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for call
#
# GET /application/entity/call/describe
# operationId: getCallDescribe
export def "application-entity-call-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/call/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for call
#
# GET /application/entity/call/list
# operationId: getCallCollection
export def "application-entity-call-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, direction: string, ended_at: string, id: string, purpose: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, result: string, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/call/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for call
#
# DELETE /application/entity/call/{call_id}
# operationId: deleteCallEntity
export def "application-entity-call delete" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_id | is-empty) { error make --unspanned { msg: "path parameter 'call_id' must be non-empty" } }
  let full_url = (build-url $base ({call_id: (encode-path-segment $call_id)} | format pattern "/application/entity/call/{call_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for call
#
# GET /application/entity/call/{call_id}
# operationId: getCallEntity
export def "application-entity-call get" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, direction: string, ended_at: string, id: string, purpose: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, result: string, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_id | is-empty) { error make --unspanned { msg: "path parameter 'call_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({call_id: (encode-path-segment $call_id)} | format pattern "/application/entity/call/{call_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for call
#
# PUT /application/entity/call/{call_id}
# operationId: updateCallEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-call update" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of the call)
  --direction: string # Direction (e.g. Inbound)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Call Identifier (e.g. 21312411)
  --purpose: string # Purpose (e.g. Negotiation)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --result: string # Result (e.g. Confirmed)
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. Planned)
  --subject: string # Subject (e.g. Subject of the call)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_id | is-empty) { error make --unspanned { msg: "path parameter 'call_id' must be non-empty" } }
  let full_url = (build-url $base ({call_id: (encode-path-segment $call_id)} | format pattern "/application/entity/call/{call_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "direction": $direction, "ended_at": $ended_at, "id": $id, "purpose": $purpose, "relation": $relation, "result": $result, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for campaign
#
# POST /application/entity/campaign
# operationId: createCampaignEntity
# --currency shape: {code?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-campaign create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --actual-cost: float # Actual Cost (format: float, e.g. 4235.91)
  --budgeted-cost: float # Budgeted Cost (format: float, e.g. 4235.91)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description of the campaign)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --expected-end-at: string # Expected End At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --expected-response: float # Expected Response (format: float, e.g. 4235.91)
  --expected-revenue: float # Expected Revenue (format: float, e.g. 4235.91)
  --expected-start-at: string # Expected Start At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Campaign Identifier (e.g. 21312411)
  --is-active: oneof<nothing, bool> # Is Active (e.g. true)
  --name: string # Name (e.g. Name of the campaign)
  --numbers-sent: int # Numbers Sent (format: int32, e.g. 571)
  --objective: string # Objective (e.g. Objective of the campaign)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. active)
  --type: string # Type (e.g. Telemarketing)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/campaign")
  let req_body = {"actual_cost": $actual_cost, "budgeted_cost": $budgeted_cost, "created_at": $created_at, "currency": $currency, "description": $description, "ended_at": $ended_at, "expected_end_at": $expected_end_at, "expected_response": $expected_response, "expected_revenue": $expected_revenue, "expected_start_at": $expected_start_at, "id": $id, "is_active": $is_active, "name": $name, "numbers_sent": $numbers_sent, "objective": $objective, "relation": $relation, "started_at": $started_at, "status": $status, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for campaign
#
# GET /application/entity/campaign/aggregate
# operationId: getCampaignAggregate
export def "application-entity-campaign-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/campaign/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for campaign
#
# DELETE /application/entity/campaign/bulk
# operationId: deleteCampaignCollectionBulk
export def "application-entity-campaign-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/campaign/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for campaign
#
# POST /application/entity/campaign/bulk
# operationId: createCampaignEntityBulk
export def "application-entity-campaign-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/campaign/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for campaign
#
# PUT /application/entity/campaign/bulk
# operationId: updateCampaignEntityBulk
export def "application-entity-campaign-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/campaign/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for campaign
#
# GET /application/entity/campaign/count
# operationId: getCampaignCountCollection
export def "application-entity-campaign-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/campaign/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for campaign
#
# GET /application/entity/campaign/describe
# operationId: getCampaignDescribe
export def "application-entity-campaign-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/campaign/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for campaign
#
# GET /application/entity/campaign/list
# operationId: getCampaignCollection
export def "application-entity-campaign-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<actual_cost: float, budgeted_cost: float, created_at: string, currency: record<code: string>, description: string, ended_at: string, expected_end_at: string, expected_response: float, expected_revenue: float, expected_start_at: string, id: string, is_active: bool, name: string, numbers_sent: int, objective: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, started_at: string, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/campaign/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for campaign
#
# DELETE /application/entity/campaign/{campaign_id}
# operationId: deleteCampaignEntity
export def "application-entity-campaign delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/application/entity/campaign/{campaign_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for campaign
#
# GET /application/entity/campaign/{campaign_id}
# operationId: getCampaignEntity
export def "application-entity-campaign get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<actual_cost: float, budgeted_cost: float, created_at: string, currency: record<code: string>, description: string, ended_at: string, expected_end_at: string, expected_response: float, expected_revenue: float, expected_start_at: string, id: string, is_active: bool, name: string, numbers_sent: int, objective: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, started_at: string, status: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/application/entity/campaign/{campaign_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for campaign
#
# PUT /application/entity/campaign/{campaign_id}
# operationId: updateCampaignEntity
# --currency shape: {code?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-campaign update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --actual-cost: float # Actual Cost (format: float, e.g. 4235.91)
  --budgeted-cost: float # Budgeted Cost (format: float, e.g. 4235.91)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description of the campaign)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --expected-end-at: string # Expected End At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --expected-response: float # Expected Response (format: float, e.g. 4235.91)
  --expected-revenue: float # Expected Revenue (format: float, e.g. 4235.91)
  --expected-start-at: string # Expected Start At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Campaign Identifier (e.g. 21312411)
  --is-active: oneof<nothing, bool> # Is Active (e.g. true)
  --name: string # Name (e.g. Name of the campaign)
  --numbers-sent: int # Numbers Sent (format: int32, e.g. 571)
  --objective: string # Objective (e.g. Objective of the campaign)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. active)
  --type: string # Type (e.g. Telemarketing)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/application/entity/campaign/{campaign_id}"))
  let req_body = {"actual_cost": $actual_cost, "budgeted_cost": $budgeted_cost, "created_at": $created_at, "currency": $currency, "description": $description, "ended_at": $ended_at, "expected_end_at": $expected_end_at, "expected_response": $expected_response, "expected_revenue": $expected_revenue, "expected_start_at": $expected_start_at, "id": $id, "is_active": $is_active, "name": $name, "numbers_sent": $numbers_sent, "objective": $objective, "relation": $relation, "started_at": $started_at, "status": $status, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for case
#
# POST /application/entity/case
# operationId: createCaseEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-case create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --expected-end-at: string # Expected End At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Case Identifier (e.g. 21312411)
  --internal-comments: string # Internal Comments (e.g. Internal Comments)
  --is-closed: oneof<nothing, bool> # Is Closed (e.g. true)
  --is-escalated: oneof<nothing, bool> # Is Escalated (e.g. true)
  --number: string # Number (e.g. 21312411)
  --origin: string # Origin (e.g. phone)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --priority: string # Priority (e.g. high)
  --reason: string # Reason (e.g. performance)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --resolution: string # Resolution (e.g. fixed)
  --resolution-comments: string # Resolution Comments (e.g. fixed)
  --satisfaction: string # Satisfaction (e.g. very happy)
  --status: string # Status (e.g. active)
  --subject: string # Subject (e.g. Bill Wall)
  --type: string # Type (e.g. Sales)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/case")
  let req_body = {"created_at": $created_at, "description": $description, "ended_at": $ended_at, "expected_end_at": $expected_end_at, "id": $id, "internal_comments": $internal_comments, "is_closed": $is_closed, "is_escalated": $is_escalated, "number": $number, "origin": $origin, "pipeline_with_stage": $pipeline_with_stage, "priority": $priority, "reason": $reason, "relation": $relation, "resolution": $resolution, "resolution_comments": $resolution_comments, "satisfaction": $satisfaction, "status": $status, "subject": $subject, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for case
#
# GET /application/entity/case/aggregate
# operationId: getCaseAggregate
export def "application-entity-case-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/case/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for case
#
# DELETE /application/entity/case/bulk
# operationId: deleteCaseCollectionBulk
export def "application-entity-case-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/case/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for case
#
# POST /application/entity/case/bulk
# operationId: createCaseEntityBulk
export def "application-entity-case-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/case/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for case
#
# PUT /application/entity/case/bulk
# operationId: updateCaseEntityBulk
export def "application-entity-case-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/case/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for case
#
# GET /application/entity/case/count
# operationId: getCaseCountCollection
export def "application-entity-case-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/case/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for case
#
# GET /application/entity/case/describe
# operationId: getCaseDescribe
export def "application-entity-case-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/case/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for case
#
# GET /application/entity/case/list
# operationId: getCaseCollection
export def "application-entity-case-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, ended_at: string, expected_end_at: string, id: string, internal_comments: string, is_closed: bool, is_escalated: bool, number: string, origin: string, pipeline_with_stage: string, priority: string, reason: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, resolution: string, resolution_comments: string, satisfaction: string, status: string, subject: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/case/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for case
#
# DELETE /application/entity/case/{case_id}
# operationId: deleteCaseEntity
export def "application-entity-case delete" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'case_id' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/application/entity/case/{case_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for case
#
# GET /application/entity/case/{case_id}
# operationId: getCaseEntity
export def "application-entity-case get" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, ended_at: string, expected_end_at: string, id: string, internal_comments: string, is_closed: bool, is_escalated: bool, number: string, origin: string, pipeline_with_stage: string, priority: string, reason: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, resolution: string, resolution_comments: string, satisfaction: string, status: string, subject: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'case_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/application/entity/case/{case_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for case
#
# PUT /application/entity/case/{case_id}
# operationId: updateCaseEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-case update" [
  case_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --expected-end-at: string # Expected End At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Case Identifier (e.g. 21312411)
  --internal-comments: string # Internal Comments (e.g. Internal Comments)
  --is-closed: oneof<nothing, bool> # Is Closed (e.g. true)
  --is-escalated: oneof<nothing, bool> # Is Escalated (e.g. true)
  --number: string # Number (e.g. 21312411)
  --origin: string # Origin (e.g. phone)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --priority: string # Priority (e.g. high)
  --reason: string # Reason (e.g. performance)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --resolution: string # Resolution (e.g. fixed)
  --resolution-comments: string # Resolution Comments (e.g. fixed)
  --satisfaction: string # Satisfaction (e.g. very happy)
  --status: string # Status (e.g. active)
  --subject: string # Subject (e.g. Bill Wall)
  --type: string # Type (e.g. Sales)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($case_id | is-empty) { error make --unspanned { msg: "path parameter 'case_id' must be non-empty" } }
  let full_url = (build-url $base ({case_id: (encode-path-segment $case_id)} | format pattern "/application/entity/case/{case_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "ended_at": $ended_at, "expected_end_at": $expected_end_at, "id": $id, "internal_comments": $internal_comments, "is_closed": $is_closed, "is_escalated": $is_escalated, "number": $number, "origin": $origin, "pipeline_with_stage": $pipeline_with_stage, "priority": $priority, "reason": $reason, "relation": $relation, "resolution": $resolution, "resolution_comments": $resolution_comments, "satisfaction": $satisfaction, "status": $status, "subject": $subject, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for comment
#
# POST /application/entity/comment
# operationId: createCommentEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-comment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --body: string # Body (e.g. My first comment)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Comment Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/comment")
  let req_body = {"body": $body, "created_at": $created_at, "id": $id, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for comment
#
# GET /application/entity/comment/aggregate
# operationId: getCommentAggregate
export def "application-entity-comment-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/comment/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for comment
#
# DELETE /application/entity/comment/bulk
# operationId: deleteCommentCollectionBulk
export def "application-entity-comment-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/comment/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for comment
#
# POST /application/entity/comment/bulk
# operationId: createCommentEntityBulk
export def "application-entity-comment-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/comment/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for comment
#
# PUT /application/entity/comment/bulk
# operationId: updateCommentEntityBulk
export def "application-entity-comment-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/comment/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for comment
#
# GET /application/entity/comment/count
# operationId: getCommentCountCollection
export def "application-entity-comment-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/comment/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for comment
#
# GET /application/entity/comment/describe
# operationId: getCommentDescribe
export def "application-entity-comment-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/comment/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for comment
#
# GET /application/entity/comment/list
# operationId: getCommentCollection
export def "application-entity-comment-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<body: string, created_at: string, id: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/comment/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for comment
#
# DELETE /application/entity/comment/{comment_id}
# operationId: deleteCommentEntity
export def "application-entity-comment delete" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/application/entity/comment/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for comment
#
# GET /application/entity/comment/{comment_id}
# operationId: getCommentEntity
export def "application-entity-comment get" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<body: string, created_at: string, id: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/application/entity/comment/{comment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for comment
#
# PUT /application/entity/comment/{comment_id}
# operationId: updateCommentEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-comment update" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --body: string # Body (e.g. My first comment)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Comment Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/application/entity/comment/{comment_id}"))
  let req_body = {"body": $body, "created_at": $created_at, "id": $id, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for contact
#
# POST /application/entity/contact
# operationId: createContactEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-contact create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --birth-date: string # Birth Date (format: date, e.g. 1982-11-28)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --department: string # Department (e.g. D2C)
  --description: string # Description (e.g. Description of the contact)
  --do-not-call: oneof<nothing, bool> # Do Not Call
  --email: list # Email — item shape: {address?: string, type?: string}
  --first-name: string # First Name (e.g. Bill)
  --id: string # Contact Identifier (e.g. 21312411)
  --last-name: string # Last Name (e.g. Wall)
  --lead-source: string # Lead Source (e.g. Campaign)
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --middle-name: string # Middle Name (e.g. van)
  --name-suffix: string # Name Suffix (e.g. Jr.)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --position: string # Position (job) (e.g. Director of Vendor Relations)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --salutation: string # Salutation (e.g. Mr.)
  --sync-to-outlook: oneof<nothing, bool> # Sync To Outlook
  --type: string # Type (e.g. Bill Wall)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/contact")
  let req_body = {"address": $address, "birth_date": $birth_date, "created_at": $created_at, "department": $department, "description": $description, "do_not_call": $do_not_call, "email": $email, "first_name": $first_name, "id": $id, "last_name": $last_name, "lead_source": $lead_source, "messenger": $messenger, "middle_name": $middle_name, "name_suffix": $name_suffix, "phone": $phone, "position": $position, "relation": $relation, "salutation": $salutation, "sync_to_outlook": $sync_to_outlook, "type": $type, "updated_at": $updated_at, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for contact
#
# GET /application/entity/contact/aggregate
# operationId: getContactAggregate
export def "application-entity-contact-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/contact/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for contact
#
# DELETE /application/entity/contact/bulk
# operationId: deleteContactCollectionBulk
export def "application-entity-contact-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/contact/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for contact
#
# POST /application/entity/contact/bulk
# operationId: createContactEntityBulk
export def "application-entity-contact-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/contact/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for contact
#
# PUT /application/entity/contact/bulk
# operationId: updateContactEntityBulk
export def "application-entity-contact-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/contact/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for contact
#
# GET /application/entity/contact/count
# operationId: getContactCountCollection
export def "application-entity-contact-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/contact/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for contact
#
# GET /application/entity/contact/describe
# operationId: getContactDescribe
export def "application-entity-contact-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/contact/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for contact
#
# GET /application/entity/contact/list
# operationId: getContactCollection
export def "application-entity-contact-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<address: list<record>, birth_date: string, created_at: string, department: string, description: string, do_not_call: bool, email: list<record>, first_name: string, id: string, last_name: string, lead_source: string, messenger: list<record>, middle_name: string, name_suffix: string, phone: list<record>, position: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, salutation: string, sync_to_outlook: bool, type: string, updated_at: string, website: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/contact/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for contact
#
# DELETE /application/entity/contact/{contact_id}
# operationId: deleteContactEntity
export def "application-entity-contact delete" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/application/entity/contact/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for contact
#
# GET /application/entity/contact/{contact_id}
# operationId: getContactEntity
export def "application-entity-contact get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<address: table<city: string, country: string, state: string, street: string, type: string, zip: string>, birth_date: string, created_at: string, department: string, description: string, do_not_call: bool, email: table<address: string, type: string>, first_name: string, id: string, last_name: string, lead_source: string, messenger: table<location: string, type: string>, middle_name: string, name_suffix: string, phone: table<number: string, type: string>, position: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, salutation: string, sync_to_outlook: bool, type: string, updated_at: string, website: table<address: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/application/entity/contact/{contact_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for contact
#
# PUT /application/entity/contact/{contact_id}
# operationId: updateContactEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-contact update" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --birth-date: string # Birth Date (format: date, e.g. 1982-11-28)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --department: string # Department (e.g. D2C)
  --description: string # Description (e.g. Description of the contact)
  --do-not-call: oneof<nothing, bool> # Do Not Call
  --email: list # Email — item shape: {address?: string, type?: string}
  --first-name: string # First Name (e.g. Bill)
  --id: string # Contact Identifier (e.g. 21312411)
  --last-name: string # Last Name (e.g. Wall)
  --lead-source: string # Lead Source (e.g. Campaign)
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --middle-name: string # Middle Name (e.g. van)
  --name-suffix: string # Name Suffix (e.g. Jr.)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --position: string # Position (job) (e.g. Director of Vendor Relations)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --salutation: string # Salutation (e.g. Mr.)
  --sync-to-outlook: oneof<nothing, bool> # Sync To Outlook
  --type: string # Type (e.g. Bill Wall)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/application/entity/contact/{contact_id}"))
  let req_body = {"address": $address, "birth_date": $birth_date, "created_at": $created_at, "department": $department, "description": $description, "do_not_call": $do_not_call, "email": $email, "first_name": $first_name, "id": $id, "last_name": $last_name, "lead_source": $lead_source, "messenger": $messenger, "middle_name": $middle_name, "name_suffix": $name_suffix, "phone": $phone, "position": $position, "relation": $relation, "salutation": $salutation, "sync_to_outlook": $sync_to_outlook, "type": $type, "updated_at": $updated_at, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for entity
#
# GET /application/entity/count
# operationId: getEntityCountCollection
export def "application-entity-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST for email
#
# POST /application/entity/email
# operationId: createEmailEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --bcc: list<string> # BCC
  --body: string # Body (e.g. Body of the email)
  --cc: list<string> # CC
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --direction: string # Direction (e.g. Outbound)
  --body-from: string # From (e.g. bill.wall@mail.com)
  --id: string # Email Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sent-at: string # Sent At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --status: string # Status (e.g. Sent)
  --subject: string # Subject (e.g. Subject of the email)
  --body-to: list<string> # To
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/email")
  let req_body = {"bcc": $bcc, "body": $body, "cc": $cc, "created_at": $created_at, "direction": $direction, "from": $body_from, "id": $id, "relation": $relation, "sent_at": $sent_at, "status": $status, "subject": $subject, "to": $body_to, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for email
#
# GET /application/entity/email/aggregate
# operationId: getEmailAggregate
export def "application-entity-email-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/email/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for email
#
# DELETE /application/entity/email/bulk
# operationId: deleteEmailCollectionBulk
export def "application-entity-email-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/email/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for email
#
# POST /application/entity/email/bulk
# operationId: createEmailEntityBulk
export def "application-entity-email-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/email/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for email
#
# PUT /application/entity/email/bulk
# operationId: updateEmailEntityBulk
export def "application-entity-email-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/email/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for email
#
# GET /application/entity/email/count
# operationId: getEmailCountCollection
export def "application-entity-email-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/email/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for email
#
# GET /application/entity/email/describe
# operationId: getEmailDescribe
export def "application-entity-email-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/email/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for email
#
# GET /application/entity/email/list
# operationId: getEmailCollection
export def "application-entity-email-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<bcc: list<string>, body: string, cc: list<string>, created_at: string, direction: string, from: string, id: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, sent_at: string, status: string, subject: string, to: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/email/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for email
#
# DELETE /application/entity/email/{email_id}
# operationId: deleteEmailEntity
export def "application-entity-email delete" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({email_id: (encode-path-segment $email_id)} | format pattern "/application/entity/email/{email_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for email
#
# GET /application/entity/email/{email_id}
# operationId: getEmailEntity
export def "application-entity-email get" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<bcc: list<string>, body: string, cc: list<string>, created_at: string, direction: string, from: string, id: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, sent_at: string, status: string, subject: string, to: list<string>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({email_id: (encode-path-segment $email_id)} | format pattern "/application/entity/email/{email_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for email
#
# PUT /application/entity/email/{email_id}
# operationId: updateEmailEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-email update" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --bcc: list<string> # BCC
  --body: string # Body (e.g. Body of the email)
  --cc: list<string> # CC
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --direction: string # Direction (e.g. Outbound)
  --body-from: string # From (e.g. bill.wall@mail.com)
  --id: string # Email Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sent-at: string # Sent At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --status: string # Status (e.g. Sent)
  --subject: string # Subject (e.g. Subject of the email)
  --body-to: list<string> # To
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({email_id: (encode-path-segment $email_id)} | format pattern "/application/entity/email/{email_id}"))
  let req_body = {"bcc": $bcc, "body": $body, "cc": $cc, "created_at": $created_at, "direction": $direction, "from": $body_from, "id": $id, "relation": $relation, "sent_at": $sent_at, "status": $status, "subject": $subject, "to": $body_to, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for event
#
# POST /application/entity/event
# operationId: createEventEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-event create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of the event)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Event Identifier (e.g. 21312411)
  --is-all-day: oneof<nothing, bool> # Is All Day
  --location: string # Location (e.g. London)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. Held)
  --subject: string # Subject (e.g. Subject of the event)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/event")
  let req_body = {"created_at": $created_at, "description": $description, "ended_at": $ended_at, "id": $id, "is_all_day": $is_all_day, "location": $location, "relation": $relation, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for event
#
# GET /application/entity/event/aggregate
# operationId: getEventAggregate
export def "application-entity-event-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/event/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for event
#
# DELETE /application/entity/event/bulk
# operationId: deleteEventCollectionBulk
export def "application-entity-event-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/event/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for event
#
# POST /application/entity/event/bulk
# operationId: createEventEntityBulk
export def "application-entity-event-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/event/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for event
#
# PUT /application/entity/event/bulk
# operationId: updateEventEntityBulk
export def "application-entity-event-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/event/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for event
#
# GET /application/entity/event/count
# operationId: getEventCountCollection
export def "application-entity-event-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/event/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for event
#
# GET /application/entity/event/describe
# operationId: getEventDescribe
export def "application-entity-event-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/event/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for event
#
# GET /application/entity/event/list
# operationId: getEventCollection
export def "application-entity-event-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, ended_at: string, id: string, is_all_day: bool, location: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/event/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for event
#
# DELETE /application/entity/event/{event_id}
# operationId: deleteEventEntity
export def "application-entity-event delete" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/application/entity/event/{event_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for event
#
# GET /application/entity/event/{event_id}
# operationId: getEventEntity
export def "application-entity-event get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, ended_at: string, id: string, is_all_day: bool, location: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/application/entity/event/{event_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for event
#
# PUT /application/entity/event/{event_id}
# operationId: updateEventEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-event update" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of the event)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Event Identifier (e.g. 21312411)
  --is-all-day: oneof<nothing, bool> # Is All Day
  --location: string # Location (e.g. London)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. Held)
  --subject: string # Subject (e.g. Subject of the event)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/application/entity/event/{event_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "ended_at": $ended_at, "id": $id, "is_all_day": $is_all_day, "location": $location, "relation": $relation, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for invoice
#
# POST /application/entity/invoice
# operationId: createInvoiceEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --currency shape: {code?: string}
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-invoice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --adjustment: float # Adjustment (format: float, e.g. 4235.91)
  --balance: float # Balance (format: float, e.g. 4235.91)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --due-date: string # Due Date (format: date, e.g. 1982-11-28)
  --excise-duty: float # Excise Duty (format: float, e.g. 4235.91)
  --grand-total: float # Grand Total (format: float, e.g. 4235.91)
  --id: string # Invoice Identifier (e.g. 21312411)
  --invoice-date: string # Invoice Date (format: date, e.g. 1982-11-28)
  --number: string # Number (e.g. 21312411)
  --purchase-order: string # Purchase Order (e.g. Order for notebook)
  --received: float # Received (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-commission: float # Sales Commission (format: float, e.g. 4235.91)
  --shipping-and-handling: float # Shipping And Handling (format: float, e.g. 4235.91)
  --status: string # Status (e.g. active)
  --subject: string # Subject (e.g. Sales)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --terms-and-conditions: string # Terms And Conditions (e.g. Conditions)
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoice")
  let req_body = {"address": $address, "adjustment": $adjustment, "balance": $balance, "created_at": $created_at, "currency": $currency, "description": $description, "discount": $discount, "due_date": $due_date, "excise_duty": $excise_duty, "grand_total": $grand_total, "id": $id, "invoice_date": $invoice_date, "number": $number, "purchase_order": $purchase_order, "received": $received, "relation": $relation, "sales_commission": $sales_commission, "shipping_and_handling": $shipping_and_handling, "status": $status, "subject": $subject, "subtotal": $subtotal, "tax": $tax, "terms_and_conditions": $terms_and_conditions, "total_price": $total_price, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for invoice
#
# GET /application/entity/invoice/aggregate
# operationId: getInvoiceAggregate
export def "application-entity-invoice-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/invoice/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for invoice
#
# DELETE /application/entity/invoice/bulk
# operationId: deleteInvoiceCollectionBulk
export def "application-entity-invoice-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoice/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for invoice
#
# POST /application/entity/invoice/bulk
# operationId: createInvoiceEntityBulk
export def "application-entity-invoice-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoice/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for invoice
#
# PUT /application/entity/invoice/bulk
# operationId: updateInvoiceEntityBulk
export def "application-entity-invoice-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoice/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for invoice
#
# GET /application/entity/invoice/count
# operationId: getInvoiceCountCollection
export def "application-entity-invoice-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/invoice/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for invoice
#
# GET /application/entity/invoice/describe
# operationId: getInvoiceDescribe
export def "application-entity-invoice-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoice/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for invoice
#
# GET /application/entity/invoice/list
# operationId: getInvoiceCollection
export def "application-entity-invoice-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<address: list<record>, adjustment: float, balance: float, created_at: string, currency: record<code: string>, description: string, discount: list<record>, due_date: string, excise_duty: float, grand_total: float, id: string, invoice_date: string, number: string, purchase_order: string, received: float, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, sales_commission: float, shipping_and_handling: float, status: string, subject: string, subtotal: float, tax: list<record>, terms_and_conditions: string, total_price: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/invoice/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for invoice
#
# DELETE /application/entity/invoice/{invoice_id}
# operationId: deleteInvoiceEntity
export def "application-entity-invoice delete" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/application/entity/invoice/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for invoice
#
# GET /application/entity/invoice/{invoice_id}
# operationId: getInvoiceEntity
export def "application-entity-invoice get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<address: table<city: string, country: string, state: string, street: string, type: string, zip: string>, adjustment: float, balance: float, created_at: string, currency: record<code: string>, description: string, discount: table<percent_value: float, type: string, value: float>, due_date: string, excise_duty: float, grand_total: float, id: string, invoice_date: string, number: string, purchase_order: string, received: float, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, sales_commission: float, shipping_and_handling: float, status: string, subject: string, subtotal: float, tax: table<percent_value: float, type: string, value: float>, terms_and_conditions: string, total_price: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/application/entity/invoice/{invoice_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for invoice
#
# PUT /application/entity/invoice/{invoice_id}
# operationId: updateInvoiceEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --currency shape: {code?: string}
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-invoice update" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --adjustment: float # Adjustment (format: float, e.g. 4235.91)
  --balance: float # Balance (format: float, e.g. 4235.91)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --due-date: string # Due Date (format: date, e.g. 1982-11-28)
  --excise-duty: float # Excise Duty (format: float, e.g. 4235.91)
  --grand-total: float # Grand Total (format: float, e.g. 4235.91)
  --id: string # Invoice Identifier (e.g. 21312411)
  --invoice-date: string # Invoice Date (format: date, e.g. 1982-11-28)
  --number: string # Number (e.g. 21312411)
  --purchase-order: string # Purchase Order (e.g. Order for notebook)
  --received: float # Received (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-commission: float # Sales Commission (format: float, e.g. 4235.91)
  --shipping-and-handling: float # Shipping And Handling (format: float, e.g. 4235.91)
  --status: string # Status (e.g. active)
  --subject: string # Subject (e.g. Sales)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --terms-and-conditions: string # Terms And Conditions (e.g. Conditions)
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/application/entity/invoice/{invoice_id}"))
  let req_body = {"address": $address, "adjustment": $adjustment, "balance": $balance, "created_at": $created_at, "currency": $currency, "description": $description, "discount": $discount, "due_date": $due_date, "excise_duty": $excise_duty, "grand_total": $grand_total, "id": $id, "invoice_date": $invoice_date, "number": $number, "purchase_order": $purchase_order, "received": $received, "relation": $relation, "sales_commission": $sales_commission, "shipping_and_handling": $shipping_and_handling, "status": $status, "subject": $subject, "subtotal": $subtotal, "tax": $tax, "terms_and_conditions": $terms_and_conditions, "total_price": $total_price, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for invoiceItem
#
# POST /application/entity/invoiceItem
# operationId: createInvoiceItemEntity
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-invoice-item create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --id: string # InvoiceItem Identifier (e.g. 21312411)
  --list-price: float # List Price (format: float, e.g. 4235.91)
  --number: string # Number (e.g. 21312411)
  --quantity: float # Quantity (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-price: float # Sales Price (format: float, e.g. 4235.91)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoiceItem")
  let req_body = {"created_at": $created_at, "description": $description, "discount": $discount, "id": $id, "list_price": $list_price, "number": $number, "quantity": $quantity, "relation": $relation, "sales_price": $sales_price, "subtotal": $subtotal, "tax": $tax, "total_price": $total_price, "unit": $unit, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for invoiceItem
#
# GET /application/entity/invoiceItem/aggregate
# operationId: getInvoiceItemAggregate
export def "application-entity-invoice-item-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/invoiceItem/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for invoiceItem
#
# DELETE /application/entity/invoiceItem/bulk
# operationId: deleteInvoiceItemCollectionBulk
export def "application-entity-invoice-item-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoiceItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for invoiceItem
#
# POST /application/entity/invoiceItem/bulk
# operationId: createInvoiceItemEntityBulk
export def "application-entity-invoice-item-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoiceItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for invoiceItem
#
# PUT /application/entity/invoiceItem/bulk
# operationId: updateInvoiceItemEntityBulk
export def "application-entity-invoice-item-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoiceItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for invoiceItem
#
# GET /application/entity/invoiceItem/count
# operationId: getInvoiceItemCountCollection
export def "application-entity-invoice-item-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/invoiceItem/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for invoiceItem
#
# GET /application/entity/invoiceItem/describe
# operationId: getInvoiceItemDescribe
export def "application-entity-invoice-item-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/invoiceItem/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for invoiceItem
#
# GET /application/entity/invoiceItem/list
# operationId: getInvoiceItemCollection
export def "application-entity-invoice-item-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, discount: list<record>, id: string, list_price: float, number: string, quantity: float, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, sales_price: float, subtotal: float, tax: list<record>, total_price: float, unit: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/invoiceItem/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for invoiceItem
#
# DELETE /application/entity/invoiceItem/{invoiceItem_id}
# operationId: deleteInvoiceItemEntity
export def "application-entity-invoice-item delete" [
  invoice_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_item_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceItem_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_item_id: (encode-path-segment $invoice_item_id)} | format pattern "/application/entity/invoiceItem/{invoice_item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for invoiceItem
#
# GET /application/entity/invoiceItem/{invoiceItem_id}
# operationId: getInvoiceItemEntity
export def "application-entity-invoice-item get" [
  invoice_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, discount: table<percent_value: float, type: string, value: float>, id: string, list_price: float, number: string, quantity: float, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, sales_price: float, subtotal: float, tax: table<percent_value: float, type: string, value: float>, total_price: float, unit: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_item_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceItem_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_item_id: (encode-path-segment $invoice_item_id)} | format pattern "/application/entity/invoiceItem/{invoice_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for invoiceItem
#
# PUT /application/entity/invoiceItem/{invoiceItem_id}
# operationId: updateInvoiceItemEntity
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-invoice-item update" [
  invoice_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --id: string # InvoiceItem Identifier (e.g. 21312411)
  --list-price: float # List Price (format: float, e.g. 4235.91)
  --number: string # Number (e.g. 21312411)
  --quantity: float # Quantity (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-price: float # Sales Price (format: float, e.g. 4235.91)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_item_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceItem_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_item_id: (encode-path-segment $invoice_item_id)} | format pattern "/application/entity/invoiceItem/{invoice_item_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "discount": $discount, "id": $id, "list_price": $list_price, "number": $number, "quantity": $quantity, "relation": $relation, "sales_price": $sales_price, "subtotal": $subtotal, "tax": $tax, "total_price": $total_price, "unit": $unit, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for lead
#
# POST /application/entity/lead
# operationId: createLeadEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-lead create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --annual-revenue: string # Annual Revenue (e.g. 100000)
  --birth-date: string # Birth Date (format: date, e.g. 1982-11-28)
  --company: string # Company (e.g. M&M)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --department: string # Department (e.g. D2C)
  --description: string # Description (e.g. Description of the contact)
  --do-not-call: oneof<nothing, bool> # Do Not Call
  --email: list # Email — item shape: {address?: string, type?: string}
  --first-name: string # First Name (e.g. Bill)
  --id: string # Lead Identifier (e.g. 21312411)
  --industry: list<string> # Industry
  --last-name: string # Last Name (e.g. Wall)
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --middle-name: string # Middle Name (e.g. van)
  --name-suffix: string # Name Suffix (e.g. Jr.)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --position: string # Position (job) (e.g. Director of Vendor Relations)
  --rating: string # Rating (e.g. Hot)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --salutation: string # Salutation (e.g. Mr.)
  --body-source: string # Lead Source
  --source-description: string # Lead Source Description (e.g. Website Application)
  --status: string # Status (e.g. Waiting for details)
  --status-description: string # Status Description (e.g. Description)
  --type: string # Type (e.g. Bill Wall)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/lead")
  let req_body = {"address": $address, "annual_revenue": $annual_revenue, "birth_date": $birth_date, "company": $company, "created_at": $created_at, "department": $department, "description": $description, "do_not_call": $do_not_call, "email": $email, "first_name": $first_name, "id": $id, "industry": $industry, "last_name": $last_name, "messenger": $messenger, "middle_name": $middle_name, "name_suffix": $name_suffix, "phone": $phone, "position": $position, "rating": $rating, "relation": $relation, "salutation": $salutation, "source": $body_source, "source_description": $source_description, "status": $status, "status_description": $status_description, "type": $type, "updated_at": $updated_at, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for lead
#
# GET /application/entity/lead/aggregate
# operationId: getLeadAggregate
export def "application-entity-lead-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/lead/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for lead
#
# DELETE /application/entity/lead/bulk
# operationId: deleteLeadCollectionBulk
export def "application-entity-lead-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/lead/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for lead
#
# POST /application/entity/lead/bulk
# operationId: createLeadEntityBulk
export def "application-entity-lead-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/lead/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for lead
#
# PUT /application/entity/lead/bulk
# operationId: updateLeadEntityBulk
export def "application-entity-lead-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/lead/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for lead
#
# GET /application/entity/lead/count
# operationId: getLeadCountCollection
export def "application-entity-lead-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/lead/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for lead
#
# GET /application/entity/lead/describe
# operationId: getLeadDescribe
export def "application-entity-lead-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/lead/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for lead
#
# GET /application/entity/lead/list
# operationId: getLeadCollection
export def "application-entity-lead-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<address: list<record>, annual_revenue: string, birth_date: string, company: string, created_at: string, department: string, description: string, do_not_call: bool, email: list<record>, first_name: string, id: string, industry: list<string>, last_name: string, messenger: list<record>, middle_name: string, name_suffix: string, phone: list<record>, position: string, rating: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, salutation: string, source: string, source_description: string, status: string, status_description: string, type: string, updated_at: string, website: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/lead/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for lead
#
# DELETE /application/entity/lead/{lead_id}
# operationId: deleteLeadEntity
export def "application-entity-lead delete" [
  lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lead_id | is-empty) { error make --unspanned { msg: "path parameter 'lead_id' must be non-empty" } }
  let full_url = (build-url $base ({lead_id: (encode-path-segment $lead_id)} | format pattern "/application/entity/lead/{lead_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for lead
#
# GET /application/entity/lead/{lead_id}
# operationId: getLeadEntity
export def "application-entity-lead get" [
  lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<address: table<city: string, country: string, state: string, street: string, type: string, zip: string>, annual_revenue: string, birth_date: string, company: string, created_at: string, department: string, description: string, do_not_call: bool, email: table<address: string, type: string>, first_name: string, id: string, industry: list<string>, last_name: string, messenger: table<location: string, type: string>, middle_name: string, name_suffix: string, phone: table<number: string, type: string>, position: string, rating: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, salutation: string, source: string, source_description: string, status: string, status_description: string, type: string, updated_at: string, website: table<address: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lead_id | is-empty) { error make --unspanned { msg: "path parameter 'lead_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({lead_id: (encode-path-segment $lead_id)} | format pattern "/application/entity/lead/{lead_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for lead
#
# PUT /application/entity/lead/{lead_id}
# operationId: updateLeadEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-lead update" [
  lead_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --annual-revenue: string # Annual Revenue (e.g. 100000)
  --birth-date: string # Birth Date (format: date, e.g. 1982-11-28)
  --company: string # Company (e.g. M&M)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --department: string # Department (e.g. D2C)
  --description: string # Description (e.g. Description of the contact)
  --do-not-call: oneof<nothing, bool> # Do Not Call
  --email: list # Email — item shape: {address?: string, type?: string}
  --first-name: string # First Name (e.g. Bill)
  --id: string # Lead Identifier (e.g. 21312411)
  --industry: list<string> # Industry
  --last-name: string # Last Name (e.g. Wall)
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --middle-name: string # Middle Name (e.g. van)
  --name-suffix: string # Name Suffix (e.g. Jr.)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --position: string # Position (job) (e.g. Director of Vendor Relations)
  --rating: string # Rating (e.g. Hot)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --salutation: string # Salutation (e.g. Mr.)
  --body-source: string # Lead Source
  --source-description: string # Lead Source Description (e.g. Website Application)
  --status: string # Status (e.g. Waiting for details)
  --status-description: string # Status Description (e.g. Description)
  --type: string # Type (e.g. Bill Wall)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lead_id | is-empty) { error make --unspanned { msg: "path parameter 'lead_id' must be non-empty" } }
  let full_url = (build-url $base ({lead_id: (encode-path-segment $lead_id)} | format pattern "/application/entity/lead/{lead_id}"))
  let req_body = {"address": $address, "annual_revenue": $annual_revenue, "birth_date": $birth_date, "company": $company, "created_at": $created_at, "department": $department, "description": $description, "do_not_call": $do_not_call, "email": $email, "first_name": $first_name, "id": $id, "industry": $industry, "last_name": $last_name, "messenger": $messenger, "middle_name": $middle_name, "name_suffix": $name_suffix, "phone": $phone, "position": $position, "rating": $rating, "relation": $relation, "salutation": $salutation, "source": $body_source, "source_description": $source_description, "status": $status, "status_description": $status_description, "type": $type, "updated_at": $updated_at, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET for entity
#
# GET /application/entity/list
# operationId: getEntityCollection
export def "application-entity-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<category: string, collection: string, customField: record, dataCache: record, entity: string, id: string, internalType: string, limit: int, methods: record, name: string, similarTo: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "fields": $fields} | compact), body: null}
}

# POST for meeting
#
# POST /application/entity/meeting
# operationId: createMeetingEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-meeting create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of the meeting)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Meeting Identifier (e.g. 21312411)
  --location: string # Location (e.g. Location)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --result: string # Result (e.g. Confirmed)
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. Held)
  --subject: string # Subject (e.g. My first note)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/meeting")
  let req_body = {"created_at": $created_at, "description": $description, "ended_at": $ended_at, "id": $id, "location": $location, "relation": $relation, "result": $result, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for meeting
#
# GET /application/entity/meeting/aggregate
# operationId: getMeetingAggregate
export def "application-entity-meeting-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/meeting/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for meeting
#
# DELETE /application/entity/meeting/bulk
# operationId: deleteMeetingCollectionBulk
export def "application-entity-meeting-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/meeting/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for meeting
#
# POST /application/entity/meeting/bulk
# operationId: createMeetingEntityBulk
export def "application-entity-meeting-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/meeting/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for meeting
#
# PUT /application/entity/meeting/bulk
# operationId: updateMeetingEntityBulk
export def "application-entity-meeting-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/meeting/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for meeting
#
# GET /application/entity/meeting/count
# operationId: getMeetingCountCollection
export def "application-entity-meeting-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/meeting/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for meeting
#
# GET /application/entity/meeting/describe
# operationId: getMeetingDescribe
export def "application-entity-meeting-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/meeting/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for meeting
#
# GET /application/entity/meeting/list
# operationId: getMeetingCollection
export def "application-entity-meeting-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, ended_at: string, id: string, location: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, result: string, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/meeting/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for meeting
#
# DELETE /application/entity/meeting/{meeting_id}
# operationId: deleteMeetingEntity
export def "application-entity-meeting delete" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meeting_id' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/application/entity/meeting/{meeting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for meeting
#
# GET /application/entity/meeting/{meeting_id}
# operationId: getMeetingEntity
export def "application-entity-meeting get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, ended_at: string, id: string, location: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, result: string, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meeting_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/application/entity/meeting/{meeting_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for meeting
#
# PUT /application/entity/meeting/{meeting_id}
# operationId: updateMeetingEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-meeting update" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description of the meeting)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Meeting Identifier (e.g. 21312411)
  --location: string # Location (e.g. Location)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --result: string # Result (e.g. Confirmed)
  --started-at: string # Started At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --status: string # Status (e.g. Held)
  --subject: string # Subject (e.g. My first note)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($meeting_id | is-empty) { error make --unspanned { msg: "path parameter 'meeting_id' must be non-empty" } }
  let full_url = (build-url $base ({meeting_id: (encode-path-segment $meeting_id)} | format pattern "/application/entity/meeting/{meeting_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "ended_at": $ended_at, "id": $id, "location": $location, "relation": $relation, "result": $result, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for note
#
# POST /application/entity/note
# operationId: createNoteEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-note create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --body: string # Body (e.g. Body of the note)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Note Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --subject: string # Subject (e.g. My first note)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/note")
  let req_body = {"body": $body, "created_at": $created_at, "id": $id, "relation": $relation, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for note
#
# GET /application/entity/note/aggregate
# operationId: getNoteAggregate
export def "application-entity-note-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/note/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for note
#
# DELETE /application/entity/note/bulk
# operationId: deleteNoteCollectionBulk
export def "application-entity-note-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/note/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for note
#
# POST /application/entity/note/bulk
# operationId: createNoteEntityBulk
export def "application-entity-note-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/note/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for note
#
# PUT /application/entity/note/bulk
# operationId: updateNoteEntityBulk
export def "application-entity-note-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/note/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for note
#
# GET /application/entity/note/count
# operationId: getNoteCountCollection
export def "application-entity-note-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/note/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for note
#
# GET /application/entity/note/describe
# operationId: getNoteDescribe
export def "application-entity-note-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/note/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for note
#
# GET /application/entity/note/list
# operationId: getNoteCollection
export def "application-entity-note-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<body: string, created_at: string, id: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/note/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for note
#
# DELETE /application/entity/note/{note_id}
# operationId: deleteNoteEntity
export def "application-entity-note delete" [
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($note_id | is-empty) { error make --unspanned { msg: "path parameter 'note_id' must be non-empty" } }
  let full_url = (build-url $base ({note_id: (encode-path-segment $note_id)} | format pattern "/application/entity/note/{note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for note
#
# GET /application/entity/note/{note_id}
# operationId: getNoteEntity
export def "application-entity-note get" [
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<body: string, created_at: string, id: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($note_id | is-empty) { error make --unspanned { msg: "path parameter 'note_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({note_id: (encode-path-segment $note_id)} | format pattern "/application/entity/note/{note_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for note
#
# PUT /application/entity/note/{note_id}
# operationId: updateNoteEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-note update" [
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --body: string # Body (e.g. Body of the note)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Note Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --subject: string # Subject (e.g. My first note)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($note_id | is-empty) { error make --unspanned { msg: "path parameter 'note_id' must be non-empty" } }
  let full_url = (build-url $base ({note_id: (encode-path-segment $note_id)} | format pattern "/application/entity/note/{note_id}"))
  let req_body = {"body": $body, "created_at": $created_at, "id": $id, "relation": $relation, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for opportunity
#
# POST /application/entity/opportunity
# operationId: createOpportunityEntity
# --currency shape: {code?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-opportunity create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --amount: float # Amount (format: float, e.g. 4235.91)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --ended-at: string # Closed At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --expected-amount: float # Expected Amount (format: float, e.g. 4235.91)
  --expected-end-at: string # Expected End At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Opportunity Identifier (e.g. 21312411)
  --lead-source: string # Lead Source (e.g. Web Site)
  --name: string # Name (e.g. Bill Wall)
  --next-step: string # Next Step (e.g. Contact)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --probability: int # Probability (format: int32, e.g. 80)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --state: string # State (e.g. Open)
  --type: string # Type (e.g. Sales)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunity")
  let req_body = {"amount": $amount, "created_at": $created_at, "currency": $currency, "description": $description, "ended_at": $ended_at, "expected_amount": $expected_amount, "expected_end_at": $expected_end_at, "id": $id, "lead_source": $lead_source, "name": $name, "next_step": $next_step, "pipeline_with_stage": $pipeline_with_stage, "probability": $probability, "relation": $relation, "state": $state, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for opportunity
#
# GET /application/entity/opportunity/aggregate
# operationId: getOpportunityAggregate
export def "application-entity-opportunity-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/opportunity/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for opportunity
#
# DELETE /application/entity/opportunity/bulk
# operationId: deleteOpportunityCollectionBulk
export def "application-entity-opportunity-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunity/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for opportunity
#
# POST /application/entity/opportunity/bulk
# operationId: createOpportunityEntityBulk
export def "application-entity-opportunity-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunity/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for opportunity
#
# PUT /application/entity/opportunity/bulk
# operationId: updateOpportunityEntityBulk
export def "application-entity-opportunity-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunity/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for opportunity
#
# GET /application/entity/opportunity/count
# operationId: getOpportunityCountCollection
export def "application-entity-opportunity-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/opportunity/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for opportunity
#
# GET /application/entity/opportunity/describe
# operationId: getOpportunityDescribe
export def "application-entity-opportunity-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunity/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for opportunity
#
# GET /application/entity/opportunity/list
# operationId: getOpportunityCollection
export def "application-entity-opportunity-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<amount: float, created_at: string, currency: record<code: string>, description: string, ended_at: string, expected_amount: float, expected_end_at: string, id: string, lead_source: string, name: string, next_step: string, pipeline_with_stage: string, probability: int, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, state: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/opportunity/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for opportunity
#
# DELETE /application/entity/opportunity/{opportunity_id}
# operationId: deleteOpportunityEntity
export def "application-entity-opportunity delete" [
  opportunity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($opportunity_id | is-empty) { error make --unspanned { msg: "path parameter 'opportunity_id' must be non-empty" } }
  let full_url = (build-url $base ({opportunity_id: (encode-path-segment $opportunity_id)} | format pattern "/application/entity/opportunity/{opportunity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for opportunity
#
# GET /application/entity/opportunity/{opportunity_id}
# operationId: getOpportunityEntity
export def "application-entity-opportunity get" [
  opportunity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<amount: float, created_at: string, currency: record<code: string>, description: string, ended_at: string, expected_amount: float, expected_end_at: string, id: string, lead_source: string, name: string, next_step: string, pipeline_with_stage: string, probability: int, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, state: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($opportunity_id | is-empty) { error make --unspanned { msg: "path parameter 'opportunity_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({opportunity_id: (encode-path-segment $opportunity_id)} | format pattern "/application/entity/opportunity/{opportunity_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for opportunity
#
# PUT /application/entity/opportunity/{opportunity_id}
# operationId: updateOpportunityEntity
# --currency shape: {code?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-opportunity update" [
  opportunity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --amount: float # Amount (format: float, e.g. 4235.91)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --ended-at: string # Closed At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --expected-amount: float # Expected Amount (format: float, e.g. 4235.91)
  --expected-end-at: string # Expected End At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Opportunity Identifier (e.g. 21312411)
  --lead-source: string # Lead Source (e.g. Web Site)
  --name: string # Name (e.g. Bill Wall)
  --next-step: string # Next Step (e.g. Contact)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --probability: int # Probability (format: int32, e.g. 80)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --state: string # State (e.g. Open)
  --type: string # Type (e.g. Sales)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($opportunity_id | is-empty) { error make --unspanned { msg: "path parameter 'opportunity_id' must be non-empty" } }
  let full_url = (build-url $base ({opportunity_id: (encode-path-segment $opportunity_id)} | format pattern "/application/entity/opportunity/{opportunity_id}"))
  let req_body = {"amount": $amount, "created_at": $created_at, "currency": $currency, "description": $description, "ended_at": $ended_at, "expected_amount": $expected_amount, "expected_end_at": $expected_end_at, "id": $id, "lead_source": $lead_source, "name": $name, "next_step": $next_step, "pipeline_with_stage": $pipeline_with_stage, "probability": $probability, "relation": $relation, "state": $state, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for opportunityProduct
#
# POST /application/entity/opportunityProduct
# operationId: createOpportunityProductEntity
# --currency shape: {code?: string}
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-opportunity-product create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --id: string # OpportunityProduct Identifier (e.g. 21312411)
  --list-price: float # List Price (format: float, e.g. 4235.91)
  --name: string # Name (e.g. Bill Wall)
  --number: string # Number (e.g. 21312411)
  --quantity: float # Quantity (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-price: float # Sales Price (format: float, e.g. 4235.91)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunityProduct")
  let req_body = {"created_at": $created_at, "currency": $currency, "description": $description, "discount": $discount, "id": $id, "list_price": $list_price, "name": $name, "number": $number, "quantity": $quantity, "relation": $relation, "sales_price": $sales_price, "subtotal": $subtotal, "tax": $tax, "total_price": $total_price, "unit": $unit, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for opportunityProduct
#
# GET /application/entity/opportunityProduct/aggregate
# operationId: getOpportunityProductAggregate
export def "application-entity-opportunity-product-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/opportunityProduct/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for opportunityProduct
#
# DELETE /application/entity/opportunityProduct/bulk
# operationId: deleteOpportunityProductCollectionBulk
export def "application-entity-opportunity-product-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunityProduct/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for opportunityProduct
#
# POST /application/entity/opportunityProduct/bulk
# operationId: createOpportunityProductEntityBulk
export def "application-entity-opportunity-product-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunityProduct/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for opportunityProduct
#
# PUT /application/entity/opportunityProduct/bulk
# operationId: updateOpportunityProductEntityBulk
export def "application-entity-opportunity-product-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunityProduct/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for opportunityProduct
#
# GET /application/entity/opportunityProduct/count
# operationId: getOpportunityProductCountCollection
export def "application-entity-opportunity-product-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/opportunityProduct/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for opportunityProduct
#
# GET /application/entity/opportunityProduct/describe
# operationId: getOpportunityProductDescribe
export def "application-entity-opportunity-product-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/opportunityProduct/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for opportunityProduct
#
# GET /application/entity/opportunityProduct/list
# operationId: getOpportunityProductCollection
export def "application-entity-opportunity-product-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, currency: record<code: string>, description: string, discount: list<record>, id: string, list_price: float, name: string, number: string, quantity: float, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, sales_price: float, subtotal: float, tax: list<record>, total_price: float, unit: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/opportunityProduct/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for opportunityProduct
#
# DELETE /application/entity/opportunityProduct/{opportunityProduct_id}
# operationId: deleteOpportunityProductEntity
export def "application-entity-opportunity-product delete" [
  opportunity_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($opportunity_product_id | is-empty) { error make --unspanned { msg: "path parameter 'opportunityProduct_id' must be non-empty" } }
  let full_url = (build-url $base ({opportunity_product_id: (encode-path-segment $opportunity_product_id)} | format pattern "/application/entity/opportunityProduct/{opportunity_product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for opportunityProduct
#
# GET /application/entity/opportunityProduct/{opportunityProduct_id}
# operationId: getOpportunityProductEntity
export def "application-entity-opportunity-product get" [
  opportunity_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, currency: record<code: string>, description: string, discount: table<percent_value: float, type: string, value: float>, id: string, list_price: float, name: string, number: string, quantity: float, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, sales_price: float, subtotal: float, tax: table<percent_value: float, type: string, value: float>, total_price: float, unit: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($opportunity_product_id | is-empty) { error make --unspanned { msg: "path parameter 'opportunityProduct_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({opportunity_product_id: (encode-path-segment $opportunity_product_id)} | format pattern "/application/entity/opportunityProduct/{opportunity_product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for opportunityProduct
#
# PUT /application/entity/opportunityProduct/{opportunityProduct_id}
# operationId: updateOpportunityProductEntity
# --currency shape: {code?: string}
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-opportunity-product update" [
  opportunity_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --id: string # OpportunityProduct Identifier (e.g. 21312411)
  --list-price: float # List Price (format: float, e.g. 4235.91)
  --name: string # Name (e.g. Bill Wall)
  --number: string # Number (e.g. 21312411)
  --quantity: float # Quantity (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-price: float # Sales Price (format: float, e.g. 4235.91)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($opportunity_product_id | is-empty) { error make --unspanned { msg: "path parameter 'opportunityProduct_id' must be non-empty" } }
  let full_url = (build-url $base ({opportunity_product_id: (encode-path-segment $opportunity_product_id)} | format pattern "/application/entity/opportunityProduct/{opportunity_product_id}"))
  let req_body = {"created_at": $created_at, "currency": $currency, "description": $description, "discount": $discount, "id": $id, "list_price": $list_price, "name": $name, "number": $number, "quantity": $quantity, "relation": $relation, "sales_price": $sales_price, "subtotal": $subtotal, "tax": $tax, "total_price": $total_price, "unit": $unit, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for post
#
# POST /application/entity/post
# operationId: createPostEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-post create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --body: string # Body (e.g. My first post)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Post Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/post")
  let req_body = {"body": $body, "created_at": $created_at, "id": $id, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for post
#
# GET /application/entity/post/aggregate
# operationId: getPostAggregate
export def "application-entity-post-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/post/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for post
#
# DELETE /application/entity/post/bulk
# operationId: deletePostCollectionBulk
export def "application-entity-post-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/post/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for post
#
# POST /application/entity/post/bulk
# operationId: createPostEntityBulk
export def "application-entity-post-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/post/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for post
#
# PUT /application/entity/post/bulk
# operationId: updatePostEntityBulk
export def "application-entity-post-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/post/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for post
#
# GET /application/entity/post/count
# operationId: getPostCountCollection
export def "application-entity-post-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/post/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for post
#
# GET /application/entity/post/describe
# operationId: getPostDescribe
export def "application-entity-post-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/post/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for post
#
# GET /application/entity/post/list
# operationId: getPostCollection
export def "application-entity-post-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<body: string, created_at: string, id: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/post/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for post
#
# DELETE /application/entity/post/{post_id}
# operationId: deletePostEntity
export def "application-entity-post delete" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/application/entity/post/{post_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for post
#
# GET /application/entity/post/{post_id}
# operationId: getPostEntity
export def "application-entity-post get" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<body: string, created_at: string, id: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/application/entity/post/{post_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for post
#
# PUT /application/entity/post/{post_id}
# operationId: updatePostEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-post update" [
  post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --body: string # Body (e.g. My first post)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Post Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($post_id | is-empty) { error make --unspanned { msg: "path parameter 'post_id' must be non-empty" } }
  let full_url = (build-url $base ({post_id: (encode-path-segment $post_id)} | format pattern "/application/entity/post/{post_id}"))
  let req_body = {"body": $body, "created_at": $created_at, "id": $id, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for priceBook
#
# POST /application/entity/priceBook
# operationId: createPriceBookEntity
# --currency shape: {code?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-price-book create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --id: string # PriceBook Identifier (e.g. 21312411)
  --is-active: oneof<nothing, bool> # Is Active (e.g. true)
  --is-standard: oneof<nothing, bool> # Is Standard (e.g. true)
  --name: string # Name (e.g. Bill Wall)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --type: string # Number (e.g. 21312411)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBook")
  let req_body = {"created_at": $created_at, "currency": $currency, "description": $description, "id": $id, "is_active": $is_active, "is_standard": $is_standard, "name": $name, "relation": $relation, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for priceBook
#
# GET /application/entity/priceBook/aggregate
# operationId: getPriceBookAggregate
export def "application-entity-price-book-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/priceBook/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for priceBook
#
# DELETE /application/entity/priceBook/bulk
# operationId: deletePriceBookCollectionBulk
export def "application-entity-price-book-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBook/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for priceBook
#
# POST /application/entity/priceBook/bulk
# operationId: createPriceBookEntityBulk
export def "application-entity-price-book-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBook/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for priceBook
#
# PUT /application/entity/priceBook/bulk
# operationId: updatePriceBookEntityBulk
export def "application-entity-price-book-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBook/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for priceBook
#
# GET /application/entity/priceBook/count
# operationId: getPriceBookCountCollection
export def "application-entity-price-book-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/priceBook/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for priceBook
#
# GET /application/entity/priceBook/describe
# operationId: getPriceBookDescribe
export def "application-entity-price-book-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBook/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for priceBook
#
# GET /application/entity/priceBook/list
# operationId: getPriceBookCollection
export def "application-entity-price-book-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, currency: record<code: string>, description: string, id: string, is_active: bool, is_standard: bool, name: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/priceBook/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for priceBook
#
# DELETE /application/entity/priceBook/{priceBook_id}
# operationId: deletePriceBookEntity
export def "application-entity-price-book delete" [
  price_book_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($price_book_id | is-empty) { error make --unspanned { msg: "path parameter 'priceBook_id' must be non-empty" } }
  let full_url = (build-url $base ({price_book_id: (encode-path-segment $price_book_id)} | format pattern "/application/entity/priceBook/{price_book_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for priceBook
#
# GET /application/entity/priceBook/{priceBook_id}
# operationId: getPriceBookEntity
export def "application-entity-price-book get" [
  price_book_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, currency: record<code: string>, description: string, id: string, is_active: bool, is_standard: bool, name: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($price_book_id | is-empty) { error make --unspanned { msg: "path parameter 'priceBook_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({price_book_id: (encode-path-segment $price_book_id)} | format pattern "/application/entity/priceBook/{price_book_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for priceBook
#
# PUT /application/entity/priceBook/{priceBook_id}
# operationId: updatePriceBookEntity
# --currency shape: {code?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-price-book update" [
  price_book_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --id: string # PriceBook Identifier (e.g. 21312411)
  --is-active: oneof<nothing, bool> # Is Active (e.g. true)
  --is-standard: oneof<nothing, bool> # Is Standard (e.g. true)
  --name: string # Name (e.g. Bill Wall)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --type: string # Number (e.g. 21312411)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($price_book_id | is-empty) { error make --unspanned { msg: "path parameter 'priceBook_id' must be non-empty" } }
  let full_url = (build-url $base ({price_book_id: (encode-path-segment $price_book_id)} | format pattern "/application/entity/priceBook/{price_book_id}"))
  let req_body = {"created_at": $created_at, "currency": $currency, "description": $description, "id": $id, "is_active": $is_active, "is_standard": $is_standard, "name": $name, "relation": $relation, "type": $type, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for priceBookItem
#
# POST /application/entity/priceBookItem
# operationId: createPriceBookItemEntity
# --price item shape: {currency?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-price-book-item create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --code: string # Code (e.g. 21312411)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # PriceBookItem Identifier (e.g. 21312411)
  --is-active: oneof<nothing, bool> # Is Active (e.g. true)
  --name: string # Name (e.g. Bill Wall)
  --price: list # Price — item shape: {currency?: string, value?: float}
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --use-standard-price: oneof<nothing, bool> # Is Standard (e.g. true)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBookItem")
  let req_body = {"code": $code, "created_at": $created_at, "id": $id, "is_active": $is_active, "name": $name, "price": $price, "relation": $relation, "updated_at": $updated_at, "use_standard_price": $use_standard_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for priceBookItem
#
# GET /application/entity/priceBookItem/aggregate
# operationId: getPriceBookItemAggregate
export def "application-entity-price-book-item-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/priceBookItem/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for priceBookItem
#
# DELETE /application/entity/priceBookItem/bulk
# operationId: deletePriceBookItemCollectionBulk
export def "application-entity-price-book-item-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBookItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for priceBookItem
#
# POST /application/entity/priceBookItem/bulk
# operationId: createPriceBookItemEntityBulk
export def "application-entity-price-book-item-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBookItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for priceBookItem
#
# PUT /application/entity/priceBookItem/bulk
# operationId: updatePriceBookItemEntityBulk
export def "application-entity-price-book-item-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBookItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for priceBookItem
#
# GET /application/entity/priceBookItem/count
# operationId: getPriceBookItemCountCollection
export def "application-entity-price-book-item-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/priceBookItem/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for priceBookItem
#
# GET /application/entity/priceBookItem/describe
# operationId: getPriceBookItemDescribe
export def "application-entity-price-book-item-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/priceBookItem/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for priceBookItem
#
# GET /application/entity/priceBookItem/list
# operationId: getPriceBookItemCollection
export def "application-entity-price-book-item-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<code: string, created_at: string, id: string, is_active: bool, name: string, price: list<record>, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, updated_at: string, use_standard_price: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/priceBookItem/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for priceBookItem
#
# DELETE /application/entity/priceBookItem/{priceBookItem_id}
# operationId: deletePriceBookItemEntity
export def "application-entity-price-book-item delete" [
  price_book_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($price_book_item_id | is-empty) { error make --unspanned { msg: "path parameter 'priceBookItem_id' must be non-empty" } }
  let full_url = (build-url $base ({price_book_item_id: (encode-path-segment $price_book_item_id)} | format pattern "/application/entity/priceBookItem/{price_book_item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for priceBookItem
#
# GET /application/entity/priceBookItem/{priceBookItem_id}
# operationId: getPriceBookItemEntity
export def "application-entity-price-book-item get" [
  price_book_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<code: string, created_at: string, id: string, is_active: bool, name: string, price: table<currency: string, value: float>, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, updated_at: string, use_standard_price: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($price_book_item_id | is-empty) { error make --unspanned { msg: "path parameter 'priceBookItem_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({price_book_item_id: (encode-path-segment $price_book_item_id)} | format pattern "/application/entity/priceBookItem/{price_book_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for priceBookItem
#
# PUT /application/entity/priceBookItem/{priceBookItem_id}
# operationId: updatePriceBookItemEntity
# --price item shape: {currency?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-price-book-item update" [
  price_book_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --code: string # Code (e.g. 21312411)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # PriceBookItem Identifier (e.g. 21312411)
  --is-active: oneof<nothing, bool> # Is Active (e.g. true)
  --name: string # Name (e.g. Bill Wall)
  --price: list # Price — item shape: {currency?: string, value?: float}
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --use-standard-price: oneof<nothing, bool> # Is Standard (e.g. true)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($price_book_item_id | is-empty) { error make --unspanned { msg: "path parameter 'priceBookItem_id' must be non-empty" } }
  let full_url = (build-url $base ({price_book_item_id: (encode-path-segment $price_book_item_id)} | format pattern "/application/entity/priceBookItem/{price_book_item_id}"))
  let req_body = {"code": $code, "created_at": $created_at, "id": $id, "is_active": $is_active, "name": $name, "price": $price, "relation": $relation, "updated_at": $updated_at, "use_standard_price": $use_standard_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for product
#
# POST /application/entity/product
# operationId: createProductEntity
# --cost item shape: {currency?: string, value?: float}
# --image item shape: {type?: string, url?: string}
# --price item shape: {currency?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-product create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --category: list<string> # Category
  --code: string # Code (e.g. CM01-R)
  --cost: list # Cost — item shape: {currency?: string, value?: float}
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Some long description)
  --id: string # Product Identifier (e.g. 21312411)
  --image: list # Image — item shape: {type?: string, url?: string}
  --is-active: oneof<nothing, bool> # Is active (e.g. true)
  --is-taxable: oneof<nothing, bool> # Is taxable (e.g. true)
  --manufacturer: string # Manufacturer (e.g. M&M)
  --name: string # Name (e.g. CPU)
  --price: list # Price — item shape: {currency?: string, value?: float}
  --quantity-in-demand: float # Quantity In Demand (format: float, e.g. 15.91)
  --quantity-in-stock: float # Quantity In Stock (format: float, e.g. 15.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --reorder-level: float # Reorder Level (format: float, e.g. 15.91)
  --sales-ended-at: string # Sales Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --sales-started-at: string # Sales Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --support-ended-at: string # Support Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --support-started-at: string # Support Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --type: string # Type (e.g. Service)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --url: string # URL (e.g. http://google.com/)
  --vendor: string # Vendor (e.g. M&M)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/product")
  let req_body = {"category": $category, "code": $code, "cost": $cost, "created_at": $created_at, "description": $description, "id": $id, "image": $image, "is_active": $is_active, "is_taxable": $is_taxable, "manufacturer": $manufacturer, "name": $name, "price": $price, "quantity_in_demand": $quantity_in_demand, "quantity_in_stock": $quantity_in_stock, "relation": $relation, "reorder_level": $reorder_level, "sales_ended_at": $sales_ended_at, "sales_started_at": $sales_started_at, "support_ended_at": $support_ended_at, "support_started_at": $support_started_at, "type": $type, "unit": $unit, "updated_at": $updated_at, "url": $url, "vendor": $vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for product
#
# GET /application/entity/product/aggregate
# operationId: getProductAggregate
export def "application-entity-product-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/product/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for product
#
# DELETE /application/entity/product/bulk
# operationId: deleteProductCollectionBulk
export def "application-entity-product-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/product/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for product
#
# POST /application/entity/product/bulk
# operationId: createProductEntityBulk
export def "application-entity-product-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/product/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for product
#
# PUT /application/entity/product/bulk
# operationId: updateProductEntityBulk
export def "application-entity-product-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/product/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for product
#
# GET /application/entity/product/count
# operationId: getProductCountCollection
export def "application-entity-product-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/product/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for product
#
# GET /application/entity/product/describe
# operationId: getProductDescribe
export def "application-entity-product-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/product/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for product
#
# GET /application/entity/product/list
# operationId: getProductCollection
export def "application-entity-product-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<category: list<string>, code: string, cost: list<record>, created_at: string, description: string, id: string, image: list<record>, is_active: bool, is_taxable: bool, manufacturer: string, name: string, price: list<record>, quantity_in_demand: float, quantity_in_stock: float, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, reorder_level: float, sales_ended_at: string, sales_started_at: string, support_ended_at: string, support_started_at: string, type: string, unit: string, updated_at: string, url: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/product/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for product
#
# DELETE /application/entity/product/{product_id}
# operationId: deleteProductEntity
export def "application-entity-product delete" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/application/entity/product/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for product
#
# GET /application/entity/product/{product_id}
# operationId: getProductEntity
export def "application-entity-product get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<category: list<string>, code: string, cost: table<currency: string, value: float>, created_at: string, description: string, id: string, image: table<type: string, url: string>, is_active: bool, is_taxable: bool, manufacturer: string, name: string, price: table<currency: string, value: float>, quantity_in_demand: float, quantity_in_stock: float, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, reorder_level: float, sales_ended_at: string, sales_started_at: string, support_ended_at: string, support_started_at: string, type: string, unit: string, updated_at: string, url: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/application/entity/product/{product_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for product
#
# PUT /application/entity/product/{product_id}
# operationId: updateProductEntity
# --cost item shape: {currency?: string, value?: float}
# --image item shape: {type?: string, url?: string}
# --price item shape: {currency?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-product update" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --category: list<string> # Category
  --code: string # Code (e.g. CM01-R)
  --cost: list # Cost — item shape: {currency?: string, value?: float}
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Some long description)
  --id: string # Product Identifier (e.g. 21312411)
  --image: list # Image — item shape: {type?: string, url?: string}
  --is-active: oneof<nothing, bool> # Is active (e.g. true)
  --is-taxable: oneof<nothing, bool> # Is taxable (e.g. true)
  --manufacturer: string # Manufacturer (e.g. M&M)
  --name: string # Name (e.g. CPU)
  --price: list # Price — item shape: {currency?: string, value?: float}
  --quantity-in-demand: float # Quantity In Demand (format: float, e.g. 15.91)
  --quantity-in-stock: float # Quantity In Stock (format: float, e.g. 15.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --reorder-level: float # Reorder Level (format: float, e.g. 15.91)
  --sales-ended-at: string # Sales Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --sales-started-at: string # Sales Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --support-ended-at: string # Support Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --support-started-at: string # Support Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --type: string # Type (e.g. Service)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --url: string # URL (e.g. http://google.com/)
  --vendor: string # Vendor (e.g. M&M)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/application/entity/product/{product_id}"))
  let req_body = {"category": $category, "code": $code, "cost": $cost, "created_at": $created_at, "description": $description, "id": $id, "image": $image, "is_active": $is_active, "is_taxable": $is_taxable, "manufacturer": $manufacturer, "name": $name, "price": $price, "quantity_in_demand": $quantity_in_demand, "quantity_in_stock": $quantity_in_stock, "relation": $relation, "reorder_level": $reorder_level, "sales_ended_at": $sales_ended_at, "sales_started_at": $sales_started_at, "support_ended_at": $support_ended_at, "support_started_at": $support_started_at, "type": $type, "unit": $unit, "updated_at": $updated_at, "url": $url, "vendor": $vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for project
#
# POST /application/entity/project
# operationId: createProjectEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-project create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --category: string # Category (e.g. Software)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Body (e.g. My first project)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Project Identifier (e.g. 21312411)
  --name: string # Name (e.g. Bill Wall)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --priority: string # Priority (e.g. Normal)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --started-at: string # Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --status: string # Status (e.g. Not Started)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/project")
  let req_body = {"category": $category, "created_at": $created_at, "description": $description, "ended_at": $ended_at, "id": $id, "name": $name, "pipeline_with_stage": $pipeline_with_stage, "priority": $priority, "relation": $relation, "started_at": $started_at, "status": $status, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for project
#
# GET /application/entity/project/aggregate
# operationId: getProjectAggregate
export def "application-entity-project-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/project/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for project
#
# DELETE /application/entity/project/bulk
# operationId: deleteProjectCollectionBulk
export def "application-entity-project-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/project/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for project
#
# POST /application/entity/project/bulk
# operationId: createProjectEntityBulk
export def "application-entity-project-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/project/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for project
#
# PUT /application/entity/project/bulk
# operationId: updateProjectEntityBulk
export def "application-entity-project-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/project/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for project
#
# GET /application/entity/project/count
# operationId: getProjectCountCollection
export def "application-entity-project-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/project/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for project
#
# GET /application/entity/project/describe
# operationId: getProjectDescribe
export def "application-entity-project-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/project/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for project
#
# GET /application/entity/project/list
# operationId: getProjectCollection
export def "application-entity-project-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<category: string, created_at: string, description: string, ended_at: string, id: string, name: string, pipeline_with_stage: string, priority: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, started_at: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/project/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for project
#
# DELETE /application/entity/project/{project_id}
# operationId: deleteProjectEntity
export def "application-entity-project delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/application/entity/project/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for project
#
# GET /application/entity/project/{project_id}
# operationId: getProjectEntity
export def "application-entity-project get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<category: string, created_at: string, description: string, ended_at: string, id: string, name: string, pipeline_with_stage: string, priority: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, started_at: string, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/application/entity/project/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for project
#
# PUT /application/entity/project/{project_id}
# operationId: updateProjectEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-project update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --category: string # Category (e.g. Software)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Body (e.g. My first project)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Project Identifier (e.g. 21312411)
  --name: string # Name (e.g. Bill Wall)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --priority: string # Priority (e.g. Normal)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --started-at: string # Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --status: string # Status (e.g. Not Started)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/application/entity/project/{project_id}"))
  let req_body = {"category": $category, "created_at": $created_at, "description": $description, "ended_at": $ended_at, "id": $id, "name": $name, "pipeline_with_stage": $pipeline_with_stage, "priority": $priority, "relation": $relation, "started_at": $started_at, "status": $status, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for quote
#
# POST /application/entity/quote
# operationId: createQuoteEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --currency shape: {code?: string}
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-quote create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --adjustment: float # Adjustment (format: float, e.g. 4235.91)
  --carrier: string # Carrier (e.g. DHL)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --expiration-date: string # Expiration Date (format: date, e.g. 1982-11-28)
  --grand-total: float # Grand Total (format: float, e.g. 4235.91)
  --id: string # Quote Identifier (e.g. 21312411)
  --number: string # Number (e.g. 21312411)
  --payment-terms: string # Payment Terms (e.g. Net 60)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --shipping-and-handling: float # Shipping And Handling (format: float, e.g. 4235.91)
  --status: string # Status (e.g. active)
  --subject: string # Subject (e.g. Sales)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --terms-and-conditions: string # Terms And Conditions (e.g. Conditions)
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quote")
  let req_body = {"address": $address, "adjustment": $adjustment, "carrier": $carrier, "created_at": $created_at, "currency": $currency, "description": $description, "discount": $discount, "expiration_date": $expiration_date, "grand_total": $grand_total, "id": $id, "number": $number, "payment_terms": $payment_terms, "relation": $relation, "shipping_and_handling": $shipping_and_handling, "status": $status, "subject": $subject, "subtotal": $subtotal, "tax": $tax, "terms_and_conditions": $terms_and_conditions, "total_price": $total_price, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for quote
#
# GET /application/entity/quote/aggregate
# operationId: getQuoteAggregate
export def "application-entity-quote-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/quote/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for quote
#
# DELETE /application/entity/quote/bulk
# operationId: deleteQuoteCollectionBulk
export def "application-entity-quote-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quote/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for quote
#
# POST /application/entity/quote/bulk
# operationId: createQuoteEntityBulk
export def "application-entity-quote-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quote/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for quote
#
# PUT /application/entity/quote/bulk
# operationId: updateQuoteEntityBulk
export def "application-entity-quote-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quote/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for quote
#
# GET /application/entity/quote/count
# operationId: getQuoteCountCollection
export def "application-entity-quote-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/quote/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for quote
#
# GET /application/entity/quote/describe
# operationId: getQuoteDescribe
export def "application-entity-quote-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quote/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for quote
#
# GET /application/entity/quote/list
# operationId: getQuoteCollection
export def "application-entity-quote-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<address: list<record>, adjustment: float, carrier: string, created_at: string, currency: record<code: string>, description: string, discount: list<record>, expiration_date: string, grand_total: float, id: string, number: string, payment_terms: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, shipping_and_handling: float, status: string, subject: string, subtotal: float, tax: list<record>, terms_and_conditions: string, total_price: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/quote/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for quote
#
# DELETE /application/entity/quote/{quote_id}
# operationId: deleteQuoteEntity
export def "application-entity-quote delete" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quote_id' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/application/entity/quote/{quote_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for quote
#
# GET /application/entity/quote/{quote_id}
# operationId: getQuoteEntity
export def "application-entity-quote get" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<address: table<city: string, country: string, state: string, street: string, type: string, zip: string>, adjustment: float, carrier: string, created_at: string, currency: record<code: string>, description: string, discount: table<percent_value: float, type: string, value: float>, expiration_date: string, grand_total: float, id: string, number: string, payment_terms: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, shipping_and_handling: float, status: string, subject: string, subtotal: float, tax: table<percent_value: float, type: string, value: float>, terms_and_conditions: string, total_price: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quote_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/application/entity/quote/{quote_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for quote
#
# PUT /application/entity/quote/{quote_id}
# operationId: updateQuoteEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --currency shape: {code?: string}
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-quote update" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --adjustment: float # Adjustment (format: float, e.g. 4235.91)
  --carrier: string # Carrier (e.g. DHL)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --currency: record # shape: {code?: string}
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --expiration-date: string # Expiration Date (format: date, e.g. 1982-11-28)
  --grand-total: float # Grand Total (format: float, e.g. 4235.91)
  --id: string # Quote Identifier (e.g. 21312411)
  --number: string # Number (e.g. 21312411)
  --payment-terms: string # Payment Terms (e.g. Net 60)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --shipping-and-handling: float # Shipping And Handling (format: float, e.g. 4235.91)
  --status: string # Status (e.g. active)
  --subject: string # Subject (e.g. Sales)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --terms-and-conditions: string # Terms And Conditions (e.g. Conditions)
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quote_id' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/application/entity/quote/{quote_id}"))
  let req_body = {"address": $address, "adjustment": $adjustment, "carrier": $carrier, "created_at": $created_at, "currency": $currency, "description": $description, "discount": $discount, "expiration_date": $expiration_date, "grand_total": $grand_total, "id": $id, "number": $number, "payment_terms": $payment_terms, "relation": $relation, "shipping_and_handling": $shipping_and_handling, "status": $status, "subject": $subject, "subtotal": $subtotal, "tax": $tax, "terms_and_conditions": $terms_and_conditions, "total_price": $total_price, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for quoteItem
#
# POST /application/entity/quoteItem
# operationId: createQuoteItemEntity
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-quote-item create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --id: string # QuoteItem Identifier (e.g. 21312411)
  --list-price: float # List Price (format: float, e.g. 4235.91)
  --number: string # Number (e.g. 21312411)
  --quantity: float # Quantity (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-price: float # Sales Price (format: float, e.g. 4235.91)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quoteItem")
  let req_body = {"created_at": $created_at, "description": $description, "discount": $discount, "id": $id, "list_price": $list_price, "number": $number, "quantity": $quantity, "relation": $relation, "sales_price": $sales_price, "subtotal": $subtotal, "tax": $tax, "total_price": $total_price, "unit": $unit, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for quoteItem
#
# GET /application/entity/quoteItem/aggregate
# operationId: getQuoteItemAggregate
export def "application-entity-quote-item-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/quoteItem/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for quoteItem
#
# DELETE /application/entity/quoteItem/bulk
# operationId: deleteQuoteItemCollectionBulk
export def "application-entity-quote-item-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quoteItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for quoteItem
#
# POST /application/entity/quoteItem/bulk
# operationId: createQuoteItemEntityBulk
export def "application-entity-quote-item-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quoteItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for quoteItem
#
# PUT /application/entity/quoteItem/bulk
# operationId: updateQuoteItemEntityBulk
export def "application-entity-quote-item-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quoteItem/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for quoteItem
#
# GET /application/entity/quoteItem/count
# operationId: getQuoteItemCountCollection
export def "application-entity-quote-item-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/quoteItem/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for quoteItem
#
# GET /application/entity/quoteItem/describe
# operationId: getQuoteItemDescribe
export def "application-entity-quote-item-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/quoteItem/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for quoteItem
#
# GET /application/entity/quoteItem/list
# operationId: getQuoteItemCollection
export def "application-entity-quote-item-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, discount: list<record>, id: string, list_price: float, number: string, quantity: float, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, sales_price: float, subtotal: float, tax: list<record>, total_price: float, unit: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/quoteItem/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for quoteItem
#
# DELETE /application/entity/quoteItem/{quoteItem_id}
# operationId: deleteQuoteItemEntity
export def "application-entity-quote-item delete" [
  quote_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_item_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteItem_id' must be non-empty" } }
  let full_url = (build-url $base ({quote_item_id: (encode-path-segment $quote_item_id)} | format pattern "/application/entity/quoteItem/{quote_item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for quoteItem
#
# GET /application/entity/quoteItem/{quoteItem_id}
# operationId: getQuoteItemEntity
export def "application-entity-quote-item get" [
  quote_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, discount: table<percent_value: float, type: string, value: float>, id: string, list_price: float, number: string, quantity: float, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, sales_price: float, subtotal: float, tax: table<percent_value: float, type: string, value: float>, total_price: float, unit: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_item_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteItem_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({quote_item_id: (encode-path-segment $quote_item_id)} | format pattern "/application/entity/quoteItem/{quote_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for quoteItem
#
# PUT /application/entity/quoteItem/{quoteItem_id}
# operationId: updateQuoteItemEntity
# --discount item shape: {percent_value?: float, type?: string, value?: float}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --tax item shape: {percent_value?: float, type?: string, value?: float}
export def "application-entity-quote-item update" [
  quote_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --discount: list # Discount — item shape: {percent_value?: float, type?: string, value?: float}
  --id: string # QuoteItem Identifier (e.g. 21312411)
  --list-price: float # List Price (format: float, e.g. 4235.91)
  --number: string # Number (e.g. 21312411)
  --quantity: float # Quantity (format: float, e.g. 4235.91)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --sales-price: float # Sales Price (format: float, e.g. 4235.91)
  --subtotal: float # Subtotal (format: float, e.g. 4235.91)
  --tax: list # Tax — item shape: {percent_value?: float, type?: string, value?: float}
  --total-price: float # Total Price (format: float, e.g. 4235.91)
  --unit: string # Unit (e.g. kg)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_item_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteItem_id' must be non-empty" } }
  let full_url = (build-url $base ({quote_item_id: (encode-path-segment $quote_item_id)} | format pattern "/application/entity/quoteItem/{quote_item_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "discount": $discount, "id": $id, "list_price": $list_price, "number": $number, "quantity": $quantity, "relation": $relation, "sales_price": $sales_price, "subtotal": $subtotal, "tax": $tax, "total_price": $total_price, "unit": $unit, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for tag
#
# POST /application/entity/tag
# operationId: createTagEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-tag create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. My first tag)
  --entity: string@entity-completer # Entity
  --id: string # Tag Identifier (e.g. 21312411)
  --name: string # Name (e.g. first_tag)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/tag")
  let req_body = {"created_at": $created_at, "description": $description, "entity": $entity, "id": $id, "name": $name, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for tag
#
# GET /application/entity/tag/aggregate
# operationId: getTagAggregate
export def "application-entity-tag-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/tag/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for tag
#
# DELETE /application/entity/tag/bulk
# operationId: deleteTagCollectionBulk
export def "application-entity-tag-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/tag/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for tag
#
# POST /application/entity/tag/bulk
# operationId: createTagEntityBulk
export def "application-entity-tag-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/tag/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for tag
#
# PUT /application/entity/tag/bulk
# operationId: updateTagEntityBulk
export def "application-entity-tag-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/tag/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for tag
#
# GET /application/entity/tag/count
# operationId: getTagCountCollection
export def "application-entity-tag-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/tag/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for tag
#
# GET /application/entity/tag/describe
# operationId: getTagDescribe
export def "application-entity-tag-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/tag/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for tag
#
# GET /application/entity/tag/list
# operationId: getTagCollection
export def "application-entity-tag-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, entity: string, id: string, name: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/tag/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for tag
#
# DELETE /application/entity/tag/{tag_id}
# operationId: deleteTagEntity
export def "application-entity-tag delete" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/application/entity/tag/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for tag
#
# GET /application/entity/tag/{tag_id}
# operationId: getTagEntity
export def "application-entity-tag get" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, entity: string, id: string, name: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/application/entity/tag/{tag_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for tag
#
# PUT /application/entity/tag/{tag_id}
# operationId: updateTagEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-tag update" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. My first tag)
  --entity: string@entity-completer # Entity
  --id: string # Tag Identifier (e.g. 21312411)
  --name: string # Name (e.g. first_tag)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tag_id' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/application/entity/tag/{tag_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "entity": $entity, "id": $id, "name": $name, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for task
#
# POST /application/entity/task
# operationId: createTaskEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. First task)
  --due-at: string # Due At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Task Identifier (e.g. 21312411)
  --priority: string # Priority (e.g. Normal)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --reminder-at: string # Remainder At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --started-at: string # Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --status: string # Status (e.g. Not Started)
  --subject: string # Name (e.g. Title)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/task")
  let req_body = {"created_at": $created_at, "description": $description, "due_at": $due_at, "ended_at": $ended_at, "id": $id, "priority": $priority, "relation": $relation, "reminder_at": $reminder_at, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for task
#
# GET /application/entity/task/aggregate
# operationId: getTaskAggregate
export def "application-entity-task-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/task/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for task
#
# DELETE /application/entity/task/bulk
# operationId: deleteTaskCollectionBulk
export def "application-entity-task-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/task/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for task
#
# POST /application/entity/task/bulk
# operationId: createTaskEntityBulk
export def "application-entity-task-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/task/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for task
#
# PUT /application/entity/task/bulk
# operationId: updateTaskEntityBulk
export def "application-entity-task-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/task/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for task
#
# GET /application/entity/task/count
# operationId: getTaskCountCollection
export def "application-entity-task-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/task/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for task
#
# GET /application/entity/task/describe
# operationId: getTaskDescribe
export def "application-entity-task-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/task/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for task
#
# GET /application/entity/task/list
# operationId: getTaskCollection
export def "application-entity-task-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, due_at: string, ended_at: string, id: string, priority: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, reminder_at: string, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/task/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for task
#
# DELETE /application/entity/task/{task_id}
# operationId: deleteTaskEntity
export def "application-entity-task delete" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/application/entity/task/{task_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for task
#
# GET /application/entity/task/{task_id}
# operationId: getTaskEntity
export def "application-entity-task get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, due_at: string, ended_at: string, id: string, priority: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, reminder_at: string, started_at: string, status: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/application/entity/task/{task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for task
#
# PUT /application/entity/task/{task_id}
# operationId: updateTaskEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-task update" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. First task)
  --due-at: string # Due At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --ended-at: string # Ended At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --id: string # Task Identifier (e.g. 21312411)
  --priority: string # Priority (e.g. Normal)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --reminder-at: string # Remainder At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --started-at: string # Started At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --status: string # Status (e.g. Not Started)
  --subject: string # Name (e.g. Title)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'task_id' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/application/entity/task/{task_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "due_at": $due_at, "ended_at": $ended_at, "id": $id, "priority": $priority, "relation": $relation, "reminder_at": $reminder_at, "started_at": $started_at, "status": $status, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for ticket
#
# POST /application/entity/ticket
# operationId: createTicketEntity
# --email item shape: {address?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-ticket create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --category: list<string> # Category
  --closed-at: string # Closed At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --due-at: string # Due At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --email: list # Email — item shape: {address?: string, type?: string}
  --id: string # Ticket Identifier (e.g. 21312411)
  --number: string # Number (e.g. 21312411)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --priority: string # Priority (e.g. high)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --resolution: string # Resolution (e.g. fixed)
  --body-source: string # Source (e.g. Email)
  --subject: string # Subject (e.g. Bill Wall)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/ticket")
  let req_body = {"category": $category, "closed_at": $closed_at, "created_at": $created_at, "description": $description, "due_at": $due_at, "email": $email, "id": $id, "number": $number, "pipeline_with_stage": $pipeline_with_stage, "priority": $priority, "relation": $relation, "resolution": $resolution, "source": $body_source, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for ticket
#
# GET /application/entity/ticket/aggregate
# operationId: getTicketAggregate
export def "application-entity-ticket-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/ticket/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for ticket
#
# DELETE /application/entity/ticket/bulk
# operationId: deleteTicketCollectionBulk
export def "application-entity-ticket-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/ticket/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for ticket
#
# POST /application/entity/ticket/bulk
# operationId: createTicketEntityBulk
export def "application-entity-ticket-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/ticket/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for ticket
#
# PUT /application/entity/ticket/bulk
# operationId: updateTicketEntityBulk
export def "application-entity-ticket-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/ticket/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for ticket
#
# GET /application/entity/ticket/count
# operationId: getTicketCountCollection
export def "application-entity-ticket-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/ticket/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for ticket
#
# GET /application/entity/ticket/describe
# operationId: getTicketDescribe
export def "application-entity-ticket-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/ticket/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for ticket
#
# GET /application/entity/ticket/list
# operationId: getTicketCollection
export def "application-entity-ticket-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<category: list<string>, closed_at: string, created_at: string, description: string, due_at: string, email: list<record>, id: string, number: string, pipeline_with_stage: string, priority: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, resolution: string, source: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/ticket/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for ticket
#
# DELETE /application/entity/ticket/{ticket_id}
# operationId: deleteTicketEntity
export def "application-entity-ticket delete" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/application/entity/ticket/{ticket_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for ticket
#
# GET /application/entity/ticket/{ticket_id}
# operationId: getTicketEntity
export def "application-entity-ticket get" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<category: list<string>, closed_at: string, created_at: string, description: string, due_at: string, email: table<address: string, type: string>, id: string, number: string, pipeline_with_stage: string, priority: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, resolution: string, source: string, subject: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/application/entity/ticket/{ticket_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for ticket
#
# PUT /application/entity/ticket/{ticket_id}
# operationId: updateTicketEntity
# --email item shape: {address?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity-ticket update" [
  ticket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --category: list<string> # Category
  --closed-at: string # Closed At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Description)
  --due-at: string # Due At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --email: list # Email — item shape: {address?: string, type?: string}
  --id: string # Ticket Identifier (e.g. 21312411)
  --number: string # Number (e.g. 21312411)
  --pipeline-with-stage: string # Pipeline With Stage (e.g. Default / Contacted)
  --priority: string # Priority (e.g. high)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --resolution: string # Resolution (e.g. fixed)
  --body-source: string # Source (e.g. Email)
  --subject: string # Subject (e.g. Bill Wall)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ticket_id | is-empty) { error make --unspanned { msg: "path parameter 'ticket_id' must be non-empty" } }
  let full_url = (build-url $base ({ticket_id: (encode-path-segment $ticket_id)} | format pattern "/application/entity/ticket/{ticket_id}"))
  let req_body = {"category": $category, "closed_at": $closed_at, "created_at": $created_at, "description": $description, "due_at": $due_at, "email": $email, "id": $id, "number": $number, "pipeline_with_stage": $pipeline_with_stage, "priority": $priority, "relation": $relation, "resolution": $resolution, "source": $body_source, "subject": $subject, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST for user
#
# POST /application/entity/user
# operationId: createUserEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --department: string # Department (e.g. Department)
  --description: string # Description (e.g. Description)
  --email: list # Email — item shape: {address?: string, type?: string}
  --first-name: string # First Name (e.g. Bill)
  --id: string # User Identifier (e.g. 21312411)
  --is-admin: oneof<nothing, bool> # Is admin (e.g. true)
  --is-associable: oneof<nothing, bool> # Is associable (e.g. true)
  --last-name: string # Last Name (e.g. Wall)
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --middle-name: string # Middle Name (e.g. van)
  --name-suffix: string # Name Suffix (e.g. Jr.)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --position: string # Position (e.g. Position)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --salutation: string # Salutation (e.g. Mr.)
  --status: string # Status (e.g. active)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --username: string # Username (e.g. billwall777)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/user")
  let req_body = {"address": $address, "created_at": $created_at, "department": $department, "description": $description, "email": $email, "first_name": $first_name, "id": $id, "is_admin": $is_admin, "is_associable": $is_associable, "last_name": $last_name, "messenger": $messenger, "middle_name": $middle_name, "name_suffix": $name_suffix, "phone": $phone, "position": $position, "relation": $relation, "salutation": $salutation, "status": $status, "updated_at": $updated_at, "username": $username, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for user
#
# GET /application/entity/user/aggregate
# operationId: getUserAggregate
export def "application-entity-user-aggregate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/user/aggregate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for user
#
# DELETE /application/entity/user/bulk
# operationId: deleteUserCollectionBulk
export def "application-entity-user-bulk delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/user/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for user
#
# POST /application/entity/user/bulk
# operationId: createUserEntityBulk
export def "application-entity-user-bulk create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/user/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for user
#
# PUT /application/entity/user/bulk
# operationId: updateUserEntityBulk
export def "application-entity-user-bulk update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/user/bulk")
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for user
#
# GET /application/entity/user/count
# operationId: getUserCountCollection
export def "application-entity-user-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/user/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for user
#
# GET /application/entity/user/describe
# operationId: getUserDescribe
export def "application-entity-user-describe get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/entity/user/describe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for user
#
# GET /application/entity/user/list
# operationId: getUserCollection
export def "application-entity-user-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<address: list<record>, created_at: string, department: string, description: string, email: list<record>, first_name: string, id: string, is_admin: bool, is_associable: bool, last_name: string, messenger: list<record>, middle_name: string, name_suffix: string, phone: list<record>, position: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, salutation: string, status: string, updated_at: string, username: string, website: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/entity/user/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for user
#
# DELETE /application/entity/user/{user_id}
# operationId: deleteUserEntity
export def "application-entity-user delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/application/entity/user/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for user
#
# GET /application/entity/user/{user_id}
# operationId: getUserEntity
export def "application-entity-user get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<address: table<city: string, country: string, state: string, street: string, type: string, zip: string>, created_at: string, department: string, description: string, email: table<address: string, type: string>, first_name: string, id: string, is_admin: bool, is_associable: bool, last_name: string, messenger: table<location: string, type: string>, middle_name: string, name_suffix: string, phone: table<number: string, type: string>, position: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, salutation: string, status: string, updated_at: string, username: string, website: table<address: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/application/entity/user/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for user
#
# PUT /application/entity/user/{user_id}
# operationId: updateUserEntity
# --address item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
# --email item shape: {address?: string, type?: string}
# --messenger item shape: {location?: string, type?: string}
# --phone item shape: {number?: string, type?: string}
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
# --website item shape: {address?: string, type?: string}
export def "application-entity-user update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --address: list # Address — item shape: {city?: string, country?: string, state?: string, street?: string, type?: string, zip?: string}
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --department: string # Department (e.g. Department)
  --description: string # Description (e.g. Description)
  --email: list # Email — item shape: {address?: string, type?: string}
  --first-name: string # First Name (e.g. Bill)
  --id: string # User Identifier (e.g. 21312411)
  --is-admin: oneof<nothing, bool> # Is admin (e.g. true)
  --is-associable: oneof<nothing, bool> # Is associable (e.g. true)
  --last-name: string # Last Name (e.g. Wall)
  --messenger: list # Messenger — item shape: {location?: string, type?: string}
  --middle-name: string # Middle Name (e.g. van)
  --name-suffix: string # Name Suffix (e.g. Jr.)
  --phone: list # Phone — item shape: {number?: string, type?: string}
  --position: string # Position (e.g. Position)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --salutation: string # Salutation (e.g. Mr.)
  --status: string # Status (e.g. active)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --username: string # Username (e.g. billwall777)
  --website: list # Website — item shape: {address?: string, type?: string}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/application/entity/user/{user_id}"))
  let req_body = {"address": $address, "created_at": $created_at, "department": $department, "description": $description, "email": $email, "first_name": $first_name, "id": $id, "is_admin": $is_admin, "is_associable": $is_associable, "last_name": $last_name, "messenger": $messenger, "middle_name": $middle_name, "name_suffix": $name_suffix, "phone": $phone, "position": $position, "relation": $relation, "salutation": $salutation, "status": $status, "updated_at": $updated_at, "username": $username, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET for entity
#
# GET /application/entity/{entity_id}
# operationId: getEntityEntity
export def "application-entity list" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<category: string, collection: string, customField: record, dataCache: record, entity: string, id: string, internalType: string, limit: int, methods: record, name: string, similarTo: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# POST for entityItem
#
# POST /application/entity/{entity_id}
# operationId: createEntityItemEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity create-item" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Entity Item Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}"))
  let req_body = {"created_at": $created_at, "id": $id, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# AGGREGATE for entityItem
#
# GET /application/entity/{entity_id}/aggregate
# operationId: getEntityItemAggregate
export def "application-entity-aggregate get-item" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --pipeline: string # Pipeline
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<id: string, result: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "pipeline" $pipeline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/aggregate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "pipeline": $pipeline} | compact), body: null}
}

# DELETE bulk for entityItem
#
# DELETE /application/entity/{entity_id}/bulk
# operationId: deleteEntityItemCollectionBulk
export def "application-entity-bulk delete-item-collection" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --item: list # Item
]: any -> record<item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/bulk"))
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST bulk for entityItem
#
# POST /application/entity/{entity_id}/bulk
# operationId: createEntityItemEntityBulk
export def "application-entity-bulk create-item" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/bulk"))
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# PUT bulk for entityItem
#
# PUT /application/entity/{entity_id}/bulk
# operationId: updateEntityItemEntityBulk
export def "application-entity-bulk update-item" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --item: list # Item
]: any -> record<id: string, item: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/bulk"))
  let req_body = {"item": $item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for entityItem
#
# GET /application/entity/{entity_id}/count
# operationId: getEntityItemCountCollection
export def "application-entity-count get-item-collection" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# DESCRIBE for entityItem
#
# GET /application/entity/{entity_id}/describe
# operationId: getEntityItemDescribe
export def "application-entity-describe get-item" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/describe"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for entityItem
#
# GET /application/entity/{entity_id}/list
# operationId: getEntityItemCollection
export def "application-entity-list get-item-collection" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --unique: string@unique-completer # Find all unique values for selected field
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, id: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "unique" $unique "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id)} | format pattern "/application/entity/{entity_id}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "expand": $expand, "fields": $fields, "sort": $qp_sort, "unique": $unique} | compact), body: null}
}

# DELETE for entityItem
#
# DELETE /application/entity/{entity_id}/{entity_item_id}
# operationId: deleteEntityItemEntity
export def "application-entity delete" [
  entity_id: string
  entity_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  if ($entity_item_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_item_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), entity_item_id: (encode-path-segment $entity_item_id)} | format pattern "/application/entity/{entity_id}/{entity_item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for entityItem
#
# GET /application/entity/{entity_id}/{entity_item_id}
# operationId: getEntityItemEntity
export def "application-entity get" [
  entity_id: string
  entity_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # Expand relations
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-data-enable: string@x-api2crm-data-enable-completer # Data Enable
  --x-api2crm-data-build: string@x-api2crm-data-build-completer # Data Build
  --x-api2crm-data-is-final: string@x-api2crm-data-is-final-completer # Data Is Final
  --x-api2crm-data-strategy: string@x-api2crm-data-strategy-completer # Data Strategy
  --x-api2crm-data-coherent-entities: string # Coherent Entities
  --x-api2crm-data-always-actual: string@x-api2crm-data-always-actual-completer # Data Is Actual
  --x-api2crm-data-actual-at: string # Data Actual At
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, id: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  if ($entity_item_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_item_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), entity_item_id: (encode-path-segment $entity_item_id)} | format pattern "/application/entity/{entity_id}/{entity_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DATA-ENABLE": $x_api2crm_data_enable, "X-API2CRM-DATA-BUILD": $x_api2crm_data_build, "X-API2CRM-DATA-IS-FINAL": $x_api2crm_data_is_final, "X-API2CRM-DATA-STRATEGY": $x_api2crm_data_strategy, "X-API2CRM-DATA-COHERENT-ENTITIES": $x_api2crm_data_coherent_entities, "X-API2CRM-DATA-ALWAYS-ACTUAL": $x_api2crm_data_always_actual, "X-API2CRM-DATA-ACTUAL-AT": $x_api2crm_data_actual_at, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "fields": $fields} | compact), body: null}
}

# PUT for entityItem
#
# PUT /application/entity/{entity_id}/{entity_item_id}
# operationId: updateEntityItemEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-entity update" [
  entity_id: string
  entity_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-native-enable: string@x-api2crm-native-enable-completer # Return native response
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --id: string # Entity Item Identifier (e.g. 21312411)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_id' must be non-empty" } }
  if ($entity_item_id | is-empty) { error make --unspanned { msg: "path parameter 'entity_item_id' must be non-empty" } }
  let full_url = (build-url $base ({entity_id: (encode-path-segment $entity_id), entity_item_id: (encode-path-segment $entity_item_id)} | format pattern "/application/entity/{entity_id}/{entity_item_id}"))
  let req_body = {"created_at": $created_at, "id": $id, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-NATIVE-ENABLE": $x_api2crm_native_enable, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for field
#
# GET /application/field/count
# operationId: getFieldCountCollection
export def "application-field-count get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/field/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for field
#
# GET /application/field/list
# operationId: getFieldCollection
export def "application-field-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<arrayItem: string, entity: list<string>, format: string, id: string, isEnum: bool, label: string, limit: int, methods: record, name: string, relation: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/field/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "fields": $fields} | compact), body: null}
}

# GET for field
#
# GET /application/field/{field_id}
# operationId: getFieldEntity
export def "application-field list" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<arrayItem: string, entity: list<string>, format: string, id: string, isEnum: bool, label: string, limit: int, methods: record, name: string, relation: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/application/field/{field_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# POST for fieldItem
#
# POST /application/field/{field_id}
# operationId: createFieldItemEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-field create-item-entity" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Custom)
  --entity: string # Entity (e.g. contact)
  --id: string # Field Item Identifier (e.g. 21312411)
  --label: string # Label (e.g. Custom)
  --name: string # Name (e.g. Custom)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/application/field/{field_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "entity": $entity, "id": $id, "label": $label, "name": $name, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for fieldItem
#
# GET /application/field/{field_id}/count
# operationId: getFieldItemCountCollection
export def "application-field-count get-item-collection" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/application/field/{field_id}/count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DESCRIBE for fieldItem
#
# GET /application/field/{field_id}/describe
# operationId: getFieldItemDescribe
export def "application-field-describe get-item" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<entity: string, schema: record<create: record, fetch: record, fetchAll: record, update: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/application/field/{field_id}/describe"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for fieldItem
#
# GET /application/field/{field_id}/list
# operationId: getFieldItemCollection
export def "application-field-list get-item-collection" [
  field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> table<created_at: string, description: string, entity: string, id: string, label: string, name: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/application/field/{field_id}/list") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "fields": $fields} | compact), body: null}
}

# DELETE for fieldItem
#
# DELETE /application/field/{field_id}/{field_item_id}
# operationId: deleteFieldItemEntity
export def "application-field delete-entity" [
  field_id: string
  field_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  if ($field_item_id | is-empty) { error make --unspanned { msg: "path parameter 'field_item_id' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), field_item_id: (encode-path-segment $field_item_id)} | format pattern "/application/field/{field_id}/{field_item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for fieldItem
#
# GET /application/field/{field_id}/{field_item_id}
# operationId: getFieldItemEntity
export def "application-field get-entity" [
  field_id: string
  field_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
]: nothing -> record<created_at: string, description: string, entity: string, id: string, label: string, name: string, relation: record<account: list<record>, attachment: list<record>, call: list<record>, campaign: list<record>, case: list<record>, comment: list<record>, contact: list<record>, email: list<record>, event: list<record>, invoice: list<record>, invoiceItem: list<record>, lead: list<record>, meeting: list<record>, note: list<record>, opportunity: list<record>, opportunityProduct: list<record>, post: list<record>, priceBook: list<record>, priceBookItem: list<record>, product: list<record>, project: list<record>, quote: list<record>, quoteItem: list<record>, tag: list<record>, task: list<record>, ticket: list<record>, user: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  if ($field_item_id | is-empty) { error make --unspanned { msg: "path parameter 'field_item_id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), field_item_id: (encode-path-segment $field_item_id)} | format pattern "/application/field/{field_id}/{field_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# PUT for fieldItem
#
# PUT /application/field/{field_id}/{field_item_id}
# operationId: updateFieldItemEntity
# --relation shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
export def "application-field update-entity" [
  field_id: string
  field_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --x-api2crm-describe-lifetime: string # Describe lifetime
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --description: string # Description (e.g. Custom)
  --entity: string # Entity (e.g. contact)
  --id: string # Field Item Identifier (e.g. 21312411)
  --label: string # Label (e.g. Custom)
  --name: string # Name (e.g. Custom)
  --relation: record # shape: {account?: list, attachment?: list, call?: list, campaign?: list, case?: list, comment?: list, contact?: list, email?: list, event?: list, invoice?: list, invoiceItem?: list, lead?: list, meeting?: list, note?: list, opportunity?: list, opportunityProduct?: list, post?: list, priceBook?: list, priceBookItem?: list, product?: list, project?: list, quote?: list, quoteItem?: list, tag?: list, task?: list, ticket?: list, user?: list}
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  if ($field_item_id | is-empty) { error make --unspanned { msg: "path parameter 'field_item_id' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id), field_item_id: (encode-path-segment $field_item_id)} | format pattern "/application/field/{field_id}/{field_item_id}"))
  let req_body = {"created_at": $created_at, "description": $description, "entity": $entity, "id": $id, "label": $label, "name": $name, "relation": $relation, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key, "X-API2CRM-DESCRIBE-LIFETIME": $x_api2crm_describe_lifetime} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET for application
#
# GET /application/list
# operationId: getApplicationCollection
export def "application-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --x-api2crm-user-key: string # API2CRM user key
]: nothing -> table<authorization: string, company: record<id: string>, created_at: string, description: string, key: string, last_used_at: string, type: string, updated_at: string, url: string, user_id: int, user_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "fields": $fields, "sort": $qp_sort} | compact), body: null}
}

# POST for request
#
# POST /application/request
# operationId: createRequestEntity
# --header item shape: {name?: string, value?: string}
export def "application-request create-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --x-api2crm-application-key: string # Application Key
  --content: string # Content (in base64 encoding)
  --header: list # Header — item shape: {name?: string, value?: string}
  --method: string # Method (e.g. GET)
  --path: string # Path (with query) (e.g. contact/111/comments?count=1)
]: any -> record<content: string, header: table<name: string, value: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/request")
  let req_body = {"content": $content, "header": $header, "method": $method, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key, "X-API2CRM-APPLICATION-KEY": $x_api2crm_application_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DELETE for application
#
# DELETE /application/{key}
# operationId: deleteApplicationEntity
export def "application delete-entity" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # API2CRM user key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/application/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for application
#
# GET /application/{key}
# operationId: getApplicationEntity
export def "application get-entity" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # API2CRM user key
]: nothing -> record<authorization: string, company: record<id: string>, created_at: string, description: string, is_authorized: bool, key: string, last_used_at: string, me: record<address: list<record>, created_at: string, department: string, description: string, email: list<record>, first_name: string, id: string, is_admin: bool, is_associable: bool, last_name: string, messenger: list<record>, middle_name: string, name_suffix: string, phone: list<record>, position: string, relation: record<account: list, attachment: list, call: list, campaign: list, case: list, comment: list, contact: list, email: list, event: list, invoice: list, invoiceItem: list, lead: list, meeting: list, note: list, opportunity: list, opportunityProduct: list, post: list, priceBook: list, priceBookItem: list, product: list, project: list, quote: list, quoteItem: list, tag: list, task: list, ticket: list, user: list>, salutation: string, status: string, updated_at: string, username: string, website: list<record>>, plan: string, requests_limit: record<is_exceeded: bool, retry_after: string, type: list<record>>, type: string, updated_at: string, url: string, user_id: int, user_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/application/{key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# PUT for application
#
# PUT /application/{key}
# operationId: updateApplicationEntity
export def "application update-entity" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # API2CRM user key
  --authorization: string # Application authorization
  --credential: record
  --description: string # Application description
  --type: string@type-completer # Application platform type
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/application/{key}"))
  let req_body = {"authorization": $authorization, "credential": $credential, "description": $description, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET for platform
#
# GET /platform/list
# operationId: getPlatformCollection
export def "platform-list get-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --x-api2crm-user-key: string # API2CRM user key
]: nothing -> table<authorization: list<record>, name: string, resource: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/platform/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "fields": $fields, "sort": $qp_sort} | compact), body: null}
}

# GET for platform
#
# GET /platform/{type}
# operationId: getPlatformEntity
export def "platform get-entity" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated list of fields to include in the response
  --x-api2crm-user-key: string # API2CRM user key
]: nothing -> record<authorization: table<description: string, platform_credential: list, type: string>, name: string, resource: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/platform/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# POST for internalUser
#
# POST /user
# operationId: createInternalUserEntity
export def "user create-internal-entity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --email: string # Email (e.g. bill.wall@mail.com)
  --internal-request-count: int # Internal Request Count (format: int32)
  --key: string # User Key (e.g. 21312411)
  --last-used-at: string # Last Used At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --name: string # Name (e.g. Bill Wall)
  --organization: string # Organization (e.g. M&M)
  --phone: string # Phone (e.g. (817) 569-8900)
  --request-count: int # Request Count (format: int32)
  --roles: list<string> # Roles
  --status: string # Status (e.g. active)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let req_body = {"created_at": $created_at, "email": $email, "internal_request_count": $internal_request_count, "key": $key, "last_used_at": $last_used_at, "name": $name, "organization": $organization, "phone": $phone, "request_count": $request_count, "roles": $roles, "status": $status, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# COUNT for internalUser
#
# GET /user/count
# operationId: getInternalUserCountCollection
export def "user-count get-internal-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter
  --x-api2crm-user-key: string # User Key
]: nothing -> record<total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# GET for internalUser
#
# GET /user/list
# operationId: getInternalUserCollection
export def "user-list get-internal-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Amount of results (default: 25) (format: int32)
  --page: int # Page to show (default: 1) (format: int32)
  --filter: string # Filter
  --fields: string # Comma-separated list of fields to include in the response
  --qp-sort: string # Specifies ascending or descending sort on existing fields
  --application-request-start: string # All Application Requests from this date (format: date)
  --application-request-end: string # All Application Requests until this date (format: date)
  --x-api2crm-user-key: string # User Key
]: nothing -> table<created_at: string, email: string, internal_request_count: int, key: string, last_used_at: string, name: string, organization: string, phone: string, request_count: int, roles: list<string>, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "application_request_start" $application_request_start "scalar") (serialize-qp "application_request_end" $application_request_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page_size": $page_size, "page": $page, "filter": $filter, "fields": $fields, "sort": $qp_sort, "application_request_start": $application_request_start, "application_request_end": $application_request_end} | compact), body: null}
}

# DELETE for internalUser
#
# DELETE /user/{internal_user_id}
# operationId: deleteInternalUserEntity
export def "user delete-entity" [
  internal_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($internal_user_id | is-empty) { error make --unspanned { msg: "path parameter 'internal_user_id' must be non-empty" } }
  let full_url = (build-url $base ({internal_user_id: (encode-path-segment $internal_user_id)} | format pattern "/user/{internal_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET for internalUser
#
# GET /user/{internal_user_id}
# operationId: getInternalUserEntity
export def "user get-entity" [
  internal_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Comma-separated list of fields to include in the response
  --application-request-start: string # All Application Requests from this date (format: date)
  --application-request-end: string # All Application Requests until this date (format: date)
  --x-api2crm-user-key: string # User Key
]: nothing -> record<created_at: string, email: string, internal_request_count: int, key: string, last_used_at: string, name: string, organization: string, phone: string, request_count: int, roles: list<string>, status: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($internal_user_id | is-empty) { error make --unspanned { msg: "path parameter 'internal_user_id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "application_request_start" $application_request_start "scalar") (serialize-qp "application_request_end" $application_request_end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({internal_user_id: (encode-path-segment $internal_user_id)} | format pattern "/user/{internal_user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "application_request_start": $application_request_start, "application_request_end": $application_request_end} | compact), body: null}
}

# PUT for internalUser
#
# PUT /user/{internal_user_id}
# operationId: updateInternalUserEntity
export def "user update-entity" [
  internal_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api2crm-user-key: string # User Key
  --created-at: string # Created At (format: date-time, e.g. 2015-01-01T05:18:23-0700)
  --email: string # Email (e.g. bill.wall@mail.com)
  --internal-request-count: int # Internal Request Count (format: int32)
  --key: string # User Key (e.g. 21312411)
  --last-used-at: string # Last Used At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
  --name: string # Name (e.g. Bill Wall)
  --organization: string # Organization (e.g. M&M)
  --phone: string # Phone (e.g. (817) 569-8900)
  --request-count: int # Request Count (format: int32)
  --roles: list<string> # Roles
  --status: string # Status (e.g. active)
  --updated-at: string # Updated At (format: date-time, e.g. 2015-02-10T17:12:23-0700)
]: any -> record<key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($internal_user_id | is-empty) { error make --unspanned { msg: "path parameter 'internal_user_id' must be non-empty" } }
  let full_url = (build-url $base ({internal_user_id: (encode-path-segment $internal_user_id)} | format pattern "/user/{internal_user_id}"))
  let req_body = {"created_at": $created_at, "email": $email, "internal_request_count": $internal_request_count, "key": $key, "last_used_at": $last_used_at, "name": $name, "organization": $organization, "phone": $phone, "request_count": $request_count, "roles": $roles, "status": $status, "updated_at": $updated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API2CRM-USER-KEY": $x_api2crm_user_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
