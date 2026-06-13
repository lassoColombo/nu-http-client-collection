# Auto-generated client for API Reference - Ideal Postcodes v3.7.0
# Source: https://api.apis.guru/v2/specs/ideal-postcodes.co.uk/3.7.0/openapi.json
# Auth: --token flag or $env.API_REFERENCE_IDEAL_POSTCODES_TOKEN

const BASE_URL = "https://api.ideal-postcodes.co.uk/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_REFERENCE_IDEAL_POSTCODES_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ideal-postcodes.co.uk/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bias-ip-completer [] { ["true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addresses Addresses" } } | get name | first)
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

# Extract Addresses
#
# GET /addresses
# operationId: Addresses
export def "addresses Addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --qp-query: string # Specifies the address you wish to query. Query can be shortened to `q=`
  --limit: int # format: int32, default: 10, e.g. 5
  --page: int # format: int32, default: 0, e.g. 0
  --filter: string # e.g. line_1,line_2,line_3
  --lon: float # format: float, e.g. -0.12767
  --lat: float # format: float, e.g. 51.503541
  --postcode-outward: string # e.g. 1AA
  --postcode: string # e.g. SW1A 2AA
  --postcode-area: string # e.g. SW
  --postcode-sector: string # e.g. SW1A 2
  --post-town: string # e.g. London
  --uprn: int # e.g. 100023336956
  --country: string # e.g. England
  --postcode-type: string # e.g. L
  --su-organisation-indicator: string # e.g. Y
  --box: string # e.g. 2.095,57.15,-2.096,57.14
  --bias-postcode-outward: string
  --bias-postcode: string # e.g. /addresses?postcode=SW1A2AA&q=10
  --bias-postcode-area: string # e.g. The postcode area of SW1A 2AA and N1 6RT are SW and N respectively
  --bias-postcode-sector: string # e.g. SW1A 2AA is SW1A 2
  --bias-post-town: string
  --bias-thoroughfare: string
  --bias-country: string
  --bias-lonlat: string # e.g. -2.095,57.15,100
]: nothing -> record<code: int, message: string, result: record<hits: list<any>, limit: int, page: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "postcode_outward" $postcode_outward "scalar") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "postcode_area" $postcode_area "scalar") (serialize-qp "postcode_sector" $postcode_sector "scalar") (serialize-qp "post_town" $post_town "scalar") (serialize-qp "uprn" $uprn "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "postcode_type" $postcode_type "scalar") (serialize-qp "su_organisation_indicator" $su_organisation_indicator "scalar") (serialize-qp "box" $box "scalar") (serialize-qp "bias_postcode_outward" $bias_postcode_outward "scalar") (serialize-qp "bias_postcode" $bias_postcode "scalar") (serialize-qp "bias_postcode_area" $bias_postcode_area "scalar") (serialize-qp "bias_postcode_sector" $bias_postcode_sector "scalar") (serialize-qp "bias_post_town" $bias_post_town "scalar") (serialize-qp "bias_thoroughfare" $bias_thoroughfare "scalar") (serialize-qp "bias_country" $bias_country "scalar") (serialize-qp "bias_lonlat" $bias_lonlat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find Address
#
# GET /autocomplete/addresses
# operationId: AddressAutocomplete
export def "autocomplete-addresses AddressAutocomplete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --qp-query: string # Specifies the address you wish to query. Query can be shortened to `q=`
  --context: string
  --limit: int # Limits number of address suggestions unless a postcode is detected. In this instance entire list of addreses for that postcode is returned.  (format: int32, default: 10, e.g. 5)
  --postcode-outward: string # e.g. 1AA
  --postcode: string # e.g. SW1A 2AA
  --postcode-area: string # e.g. SW
  --postcode-sector: string # e.g. SW1A 2
  --post-town: string # e.g. London
  --uprn: int # e.g. 100023336956
  --country: string # e.g. England
  --postcode-type: string # e.g. L
  --su-organisation-indicator: string # e.g. Y
  --box: string # e.g. 2.095,57.15,-2.096,57.14
  --bias-postcode-outward: string
  --bias-postcode: string # e.g. /addresses?postcode=SW1A2AA&q=10
  --bias-postcode-area: string # e.g. The postcode area of SW1A 2AA and N1 6RT are SW and N respectively
  --bias-postcode-sector: string # e.g. SW1A 2AA is SW1A 2
  --bias-post-town: string
  --bias-thoroughfare: string
  --bias-country: string
  --bias-lonlat: string # e.g. -2.095,57.15,100
  --bias-ip: string@bias-ip-completer # e.g. true
]: nothing -> record<code: int, message: string, result: record<hits: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "postcode_outward" $postcode_outward "scalar") (serialize-qp "postcode" $postcode "scalar") (serialize-qp "postcode_area" $postcode_area "scalar") (serialize-qp "postcode_sector" $postcode_sector "scalar") (serialize-qp "post_town" $post_town "scalar") (serialize-qp "uprn" $uprn "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "postcode_type" $postcode_type "scalar") (serialize-qp "su_organisation_indicator" $su_organisation_indicator "scalar") (serialize-qp "box" $box "scalar") (serialize-qp "bias_postcode_outward" $bias_postcode_outward "scalar") (serialize-qp "bias_postcode" $bias_postcode "scalar") (serialize-qp "bias_postcode_area" $bias_postcode_area "scalar") (serialize-qp "bias_postcode_sector" $bias_postcode_sector "scalar") (serialize-qp "bias_post_town" $bias_post_town "scalar") (serialize-qp "bias_thoroughfare" $bias_thoroughfare "scalar") (serialize-qp "bias_country" $bias_country "scalar") (serialize-qp "bias_lonlat" $bias_lonlat "scalar") (serialize-qp "bias_ip" $bias_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/autocomplete/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve Address (GBR)
#
# GET /autocomplete/addresses/{address}/gbr
# operationId: Resolve
export def "autocomplete-addresses-gbr Resolve" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/autocomplete/addresses/($address)/gbr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve Address (USA)
#
# GET /autocomplete/addresses/{address}/usa
# operationId: ResolveUsa
export def "autocomplete-addresses-usa ResolveUsa" [
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/autocomplete/addresses/($address)/usa" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cleanse
#
# POST /cleanse/addresses
# operationId: AddressCleanse
export def "cleanse-addresses AddressCleanse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --body-query: string # Freeform address input to cleanse  (e.g. 10 Downing Street, London, SW2A 2BN)
]: any -> record<code: int, message: string, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cleanse/addresses" $qp)
  let body = {query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Email Validation
#
# GET /emails
# operationId: EmailValidation
export def "emails EmailValidation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --qp-query: string # Specifies the email address to validate
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Availability
#
# GET /keys/{key}
# operationId: KeyAvailability
export def "keys KeyAvailability" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, result: record<available: bool, context: any, contexts: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /keys/{key}/configs
# operationId: ListConfigs
export def "keys-configs ListConfigs" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<configs: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/configs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /keys/{key}/configs
# operationId: CreateConfig
export def "keys-configs CreateConfig" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  name: string # A unique name to identify the configuration payload (e.g. woocommerce)
  payload: string # A serialised payload of up to `4096` characters (e.g. {   "removeOrganisation": false } )
]: any -> record<code: int, message: string, result: record<createdAt: string, name: string, payload: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/configs" $qp)
  let body = {name: $name, payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /keys/{key}/configs/{config}
# operationId: DeleteConfig
export def "keys-configs DeleteConfig" [
  key: string
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<deleted: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/configs/($config)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve
#
# GET /keys/{key}/configs/{config}
# operationId: RetrieveConfig
export def "keys-configs RetrieveConfig" [
  key: string
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string, result: record<createdAt: string, name: string, payload: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($key)/configs/($config)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# POST /keys/{key}/configs/{config}
# operationId: UpdateConfig
export def "keys-configs UpdateConfig" [
  key: string
  config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --payload: string # A serialised payload of up to `4096` characters (e.g. {   "removeOrganisation": false } )
]: any -> record<code: int, message: string, result: record<createdAt: string, name: string, payload: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/configs/($config)" $qp)
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Details
#
# GET /keys/{key}/details
# operationId: KeyDetails
export def "keys-details KeyDetails" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<allowed_urls: list<string>, automated_topups: record<enabled: bool>, current_purchases: list<record>, daily_limit: record<consumed: int, limit: int>, datasets: record<ecad: bool, ecaf: bool, herewe: bool, mr: bool, nyb: bool, paf: bool, pafa: bool, pafw: bool, usps: bool>, individual_limit: record<limit: int>, lookups_remaining: int, notifications: record<emails: list, enabled: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List
#
# GET /keys/{key}/licensees
# operationId: ListLicensees
export def "keys-licensees ListLicensees" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --starting-after: int # Specify ID of the licensee after which you would like to list results (format: int32)
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --limit: int # Specify the maximum number of results to return per page. Default and maximum is `100`. (format: int32, default: 10, e.g. 5)
  --qp-query: string # Filter result by licensee name. Query can be shortened to `q=`
]: nothing -> record<code: int, message: string, result: record<hasMore: bool, licensees: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "starting_after" $starting_after "scalar") (serialize-qp "user_token" $user_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/licensees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create
#
# POST /keys/{key}/licensees
# operationId: CreateLicensee
# --daily shape: {limit?: float}
export def "keys-licensees CreateLicensee" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --address: string # Licensee's first, second and third line address as well as post town concatenated by commas (e.g. 12 High Street, Manchester)
  --daily: record # shape: {limit?: float}
  --name: string # Licensee individual or organisation name (e.g. Qwerty Widgets Limited)
  --postcode: string # Licensee's postcode (e.g. ID1 1QD)
  --whitelist: list # A list of allowed URLs. An empty list means that whitelisting is disabled
]: any -> record<code: int, message: string, result: record<address: string, daily: record<count: float, updatedAt: string>, name: string, postcode: string, whitelist: list<string>, createdAt: string, id: string, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/licensees" $qp)
  let body = {address: $address, daily: $daily, name: $name, postcode: $postcode, whitelist: $whitelist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel
#
# DELETE /keys/{key}/licensees/{licensee}
# operationId: DeleteLicensee
export def "keys-licensees DeleteLicensee" [
  key: string
  licensee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<deleted: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/licensees/($licensee)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve
#
# GET /keys/{key}/licensees/{licensee}
# operationId: RetrieveLicensee
export def "keys-licensees RetrieveLicensee" [
  key: string
  licensee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
]: nothing -> record<code: int, message: string, result: record<address: string, daily: record<count: float, updatedAt: string>, name: string, postcode: string, whitelist: list<string>, createdAt: string, id: string, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/licensees/($licensee)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update
#
# PUT /keys/{key}/licensees/{licensee}
# operationId: UpdateLicensee
# --daily shape: {limit?: float}
export def "keys-licensees UpdateLicensee" [
  key: string
  licensee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-token: string # e.g. uk_B59ScW1p1HHouf1VqclEPZUx
  --address: string # Licensee's first, second and third line address as well as post town concatenated by commas (e.g. 12 High Street, Manchester)
  --daily: record # shape: {limit?: float}
  --name: string # Licensee individual or organisation name (e.g. Qwerty Widgets Limited)
  --postcode: string # Licensee's postcode (e.g. ID1 1QD)
  --whitelist: list # A list of allowed URLs. An empty list means that whitelisting is disabled
]: any -> record<code: int, message: string, result: record<address: string, daily: record<count: float, updatedAt: string>, name: string, postcode: string, whitelist: list<string>, createdAt: string, id: string, key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_token" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/licensees/($licensee)" $qp)
  let body = {address: $address, daily: $daily, name: $name, postcode: $postcode, whitelist: $whitelist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Logs (CSV)
#
# GET /keys/{key}/lookups
# operationId: KeyLogs
export def "keys-lookups KeyLogs" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # An start date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no start time is provided, the start time will be assigned to a time 21 days prior to the end time. (format: int32, e.g. 1418556452651)
  --end: int # An end date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no end time is provided, the current time will be used. (format: int32, e.g. 1418556477882)
  --licensee: string # Sublicensed keys only. This will restrict the analysed dataset to a specific licensee. (e.g. sk_hk71kco54zGSGvF9eXXrvvnMOLLNh)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "licensee" $licensee "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/lookups" $qp)
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Usage Stats
#
# GET /keys/{key}/usage
# operationId: KeyUsage
export def "keys-usage KeyUsage" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # A start date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no start time is provided, the start time will be assigned to a time 21 days prior to the end time. (format: int32, e.g. 1418556452651)
  --end: int # An end date/time in the form of a UNIX Timestamp in milliseconds, e.g. `1418556452651`. If no end time is provided, the current time will be used. (format: int32, e.g. 1418556477882)
  --tags: string # e.g. foo,bar
  --licensee: string # Sublicensed keys only. This will restrict the analysed dataset to a specific licensee. (e.g. sk_hk71kco54zGSGvF9eXXrvvnMOLLNh)
]: nothing -> record<code: int, message: string, result: record<dailyCount: list<record>, end: string, start: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "licensee" $licensee "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keys/($key)/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Phone Number Validation
#
# GET /phone_numbers
# operationId: PhoneNumberValidation
export def "phone-numbers PhoneNumberValidation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --qp-query: string # Specifies the phone number to validate. Phone number must include a country code in acceptable format. For instance, UK phone numbers should be suffixed `+44`, `44` or `0044`.
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find Place
#
# GET /places
# operationId: FindPlace
export def "places FindPlace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --qp-query: string # Specifies the place you wish to query. Query can be shortened to `q=`
  --country-iso: string # e.g. GBR
  --bias-country-iso: string # e.g. GBR
  --bias-lonlat: string # e.g. -2.095,57.15,100
  --bias-ip: string@bias-ip-completer # e.g. true
]: nothing -> record<code: int, message: string, result: record<hits: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "country_iso" $country_iso "scalar") (serialize-qp "bias_country_iso" $bias_country_iso "scalar") (serialize-qp "bias_lonlat" $bias_lonlat "scalar") (serialize-qp "bias_ip" $bias_ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve Place
#
# GET /places/${place}
# operationId: ResolvePlace
export def "places-place ResolvePlace" [
  place: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/$($place)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lookup Postcode
#
# GET /postcodes/{postcode}
# operationId: Postcodes
export def "postcodes Postcodes" [
  postcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --filter: string # e.g. line_1,line_2,line_3
  --page: int # format: int32, default: 0, e.g. 0
]: nothing -> record<code: int, message: string, result: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/postcodes/($postcode)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve by UDPRN
#
# GET /udprn/{udprn}
# operationId: UDPRN
export def "udprn UDPRN" [
  udprn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --filter: string # e.g. line_1,line_2,line_3
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/udprn/($udprn)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve by UMPRN
#
# GET /umprn/{umprn}
# operationId: UMPRN
export def "umprn UMPRN" [
  umprn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # e.g. ak_test
  --filter: string # e.g. line_1,line_2,line_3
]: nothing -> record<code: int, message: string, result: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/umprn/($umprn)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
