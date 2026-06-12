# Auto-generated client for Business Registries v0.0.6
# Source: https://api.apis.guru/v2/specs/ato.gov.au/0.0.6/openapi.json
# Auth: --token flag or $env.BUSINESS_REGISTRIES_TOKEN

const BASE_URL = "http://localhost//api.abr.ato.gov.au"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_REGISTRIES_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost//api.abr.ato.gov.au" "http://localhost//api.sandbox.abr.ato.gov.au"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def gender-completer [] { ["Female" "Male" "Not Applicable" "Not Known"] }
def lifecycleState-completer [] { ["Approved" "Expired" "Issued" "Pending Approval" "Suspended"] }
def electronicAddressType-completer [] { ["Email" "Fax" "Landline" "Mobile" "Website"] }
def licenseType-completer [] { ["Australian Financial Services License" "License 2B"] }
def partyRoleType-completer [] { ["Director" "Employee" "Member" "Partner" "Trustee"] }
def relatedPartyRoleType-completer [] { ["Association" "Company" "Employer" "Organisation" "Partnership" "Trust"] }
def relationshipType-completer [] { ["Directorship" "Employment" "Membership" "Partnership" "Trusteeship"] }
def legalEntityType-completer [] { ["Company" "Joint Venture" "Partnership" "Trust"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-names get" } } | get name | first)
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

# Retrieve a list of business names
#
# GET /business-names
export def "business-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business-names")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of address types
#
# GET /classifications/address-types
export def "classifications-address-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/address-types")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of business name lifecycle states
#
# GET /classifications/business-name-lifecycle-states
export def "classifications-business-name-lifecycle-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/business-name-lifecycle-states")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of electronic address types
#
# GET /classifications/electronic-address-types
export def "classifications-electronic-address-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/electronic-address-types")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of genders
#
# GET /classifications/genders
export def "classifications-genders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<gender: string, id: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/genders")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of legal entity types
#
# GET /classifications/legal-entity-types
export def "classifications-legal-entity-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/legal-entity-types")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of license lifecycle states
#
# GET /classifications/license-lifecycle-states
export def "classifications-license-lifecycle-states get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/license-lifecycle-states")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of license types
#
# GET /classifications/license-types
export def "classifications-license-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/license-types")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of name directions
#
# GET /classifications/name-directions
export def "classifications-name-directions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/name-directions")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of name prefixes
#
# GET /classifications/name-prefixes
export def "classifications-name-prefixes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/name-prefixes")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of name types
#
# GET /classifications/name-types
export def "classifications-name-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/name-types")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of registered identifier types
#
# GET /classifications/registered-identifier-types
export def "classifications-registered-identifier-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<description: string, id: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/registered-identifier-types")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of roles
#
# GET /classifications/roles
export def "classifications-roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<id: record, reciprocalRole: string, reciprocalRoleDescription: string, relationship: string, role: string, roleDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/classifications/roles")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of individuals
#
# GET /individuals
export def "individuals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dateOfBirth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format).
  --placeOfBirth: string # The individual's place of birth, for example, `Tamworth`.
  --apiKey: string # The API key.
]: nothing -> table<addresses: list<record>, dateOfBirth: string, electronicAddresses: list<record>, fromDate: string, gender: string, id: record, names: list<record>, placeOfBirth: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateOfBirth" $dateOfBirth "scalar") (serialize-qp "placeOfBirth" $placeOfBirth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/individuals" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an individual
#
# POST /individuals
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
export def "individuals post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
  dateOfBirth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1979-01-13)
  --electronicAddresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  --gender: string@gender-completer # The individual's gender. (default: Male)
  --names: list # item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
  placeOfBirth: string # The individual's place of birth, for example, `Tamworth`. (e.g. Tamworth)
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: record, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: record, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/individuals")
  let body = {addresses: $addresses, dateOfBirth: $dateOfBirth, electronicAddresses: $electronicAddresses, gender: $gender, names: $names, placeOfBirth: $placeOfBirth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an individual
#
# DELETE /individuals/{partyId}
export def "individuals delete" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an individual
#
# GET /individuals/{partyId}
export def "individuals get" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: record, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: record, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an individual
#
# PUT /individuals/{partyId}
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
export def "individuals put" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"|"Principal Place of Residence"}
  dateOfBirth: string # The individual's date of birth, for example, `1979-01-13` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1979-01-13)
  --electronicAddresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  --gender: string@gender-completer # The individual's gender. (default: Male)
  --names: list # item shape: {direction?: "left-to-right"|"right-to-left", familyName?: string, formalSalutation?: string, givenName?: string, informalSalutation?: string, middleName?: string, namePrefix?: "Mr"|"Ms", nameSuffix?: string, nameType?: "Alias"|"Principal Name"}
  placeOfBirth: string # The individual's place of birth, for example, `Tamworth`. (e.g. Tamworth)
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, dateOfBirth: string, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, fromDate: string, gender: string, id: record, names: table<direction: string, familyName: string, formalSalutation: string, fromDate: string, givenName: string, id: record, informalSalutation: string, middleName: string, namePrefix: string, nameSuffix: string, nameType: string, toDate: string>, placeOfBirth: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)")
  let body = {addresses: $addresses, dateOfBirth: $dateOfBirth, electronicAddresses: $electronicAddresses, gender: $gender, names: $names, placeOfBirth: $placeOfBirth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of addresses
#
# GET /individuals/{partyId}/addresses
export def "individuals-addresses list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/addresses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an address
#
# POST /individuals/{partyId}/addresses
export def "individuals-addresses post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postalCode: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/addresses")
  let body = {city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postalCode: $postalCode, suburb: $suburb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an address
#
# DELETE /individuals/{partyId}/addresses/{addressId}
export def "individuals-addresses delete" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an address
#
# GET /individuals/{partyId}/addresses/{addressId}
export def "individuals-addresses get" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an address
#
# PUT /individuals/{partyId}/addresses/{addressId}
export def "individuals-addresses put" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postalCode: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/addresses/($addressId)")
  let body = {city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postalCode: $postalCode, suburb: $suburb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of business names
#
# GET /individuals/{partyId}/business-names
export def "individuals-business-names list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/business-names")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a business name
#
# POST /individuals/{partyId}/business-names
export def "individuals-business-names post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/business-names")
  let body = {lifecycleState: $lifecycleState, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a business name
#
# DELETE /individuals/{partyId}/business-names/{productId}
export def "individuals-business-names delete" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/business-names/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a business name
#
# GET /individuals/{partyId}/business-names/{productId}
export def "individuals-business-names get" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/business-names/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a business name
#
# PUT /individuals/{partyId}/business-names/{productId}
export def "individuals-business-names put" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/business-names/($productId)")
  let body = {lifecycleState: $lifecycleState, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of electronic addresses
#
# GET /individuals/{partyId}/electronic-addresses
export def "individuals-electronic-addresses list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/electronic-addresses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an electronic address
#
# POST /individuals/{partyId}/electronic-addresses
export def "individuals-electronic-addresses post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --areaCode: string # The area code, for example, "02". (e.g. 02)
  --countryPrefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronicAddressType: string@electronicAddressType-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --body-url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/electronic-addresses")
  let body = {areaCode: $areaCode, countryPrefix: $countryPrefix, electronicAddressType: $electronicAddressType, email: $email, extension: $extension, number: $number, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an electronic address
#
# DELETE /individuals/{partyId}/electronic-addresses/{addressId}
export def "individuals-electronic-addresses delete" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/electronic-addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an electronic address
#
# GET /individuals/{partyId}/electronic-addresses/{addressId}
export def "individuals-electronic-addresses get" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/electronic-addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an electronic address
#
# PUT /individuals/{partyId}/electronic-addresses/{addressId}
export def "individuals-electronic-addresses put" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --areaCode: string # The area code, for example, "02". (e.g. 02)
  --countryPrefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronicAddressType: string@electronicAddressType-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --body-url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/electronic-addresses/($addressId)")
  let body = {areaCode: $areaCode, countryPrefix: $countryPrefix, electronicAddressType: $electronicAddressType, email: $email, extension: $extension, number: $number, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of licenses
#
# GET /individuals/{partyId}/licenses
export def "individuals-licenses list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/licenses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a license
#
# POST /individuals/{partyId}/licenses
export def "individuals-licenses post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --licenseType: string@licenseType-completer # The license type. (default: Australian Financial Services License)
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/licenses")
  let body = {licenseType: $licenseType, lifecycleState: $lifecycleState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a license
#
# DELETE /individuals/{partyId}/licenses/{productId}
export def "individuals-licenses delete" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/licenses/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a license
#
# GET /individuals/{partyId}/licenses/{productId}
export def "individuals-licenses get" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/licenses/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a license
#
# PUT /individuals/{partyId}/licenses/{productId}
export def "individuals-licenses put" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --licenseType: string@licenseType-completer # The license type. (default: Australian Financial Services License)
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/licenses/($productId)")
  let body = {licenseType: $licenseType, lifecycleState: $lifecycleState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of roles
#
# GET /individuals/{partyId}/roles
export def "individuals-roles list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/roles")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role
#
# POST /individuals/{partyId}/roles
export def "individuals-roles post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --partyRoleType: string@partyRoleType-completer # The party's role type. (default: Employee)
  relatedPartyId: any # The related party's unique identifier.
  --relatedPartyRoleType: string@relatedPartyRoleType-completer # The related party's role type. (default: Employer)
  relationshipType: string@relationshipType-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/roles")
  let body = {partyRoleType: $partyRoleType, relatedPartyId: $relatedPartyId, relatedPartyRoleType: $relatedPartyRoleType, relationshipType: $relationshipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /individuals/{partyId}/roles/{roleId}
export def "individuals-roles delete" [
  partyId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/roles/($roleId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a role
#
# GET /individuals/{partyId}/roles/{roleId}
export def "individuals-roles get" [
  partyId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/roles/($roleId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role
#
# PUT /individuals/{partyId}/roles/{roleId}
export def "individuals-roles put" [
  partyId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --partyRoleType: string@partyRoleType-completer # The party's role type. (default: Employee)
  relatedPartyId: any # The related party's unique identifier.
  --relatedPartyRoleType: string@relatedPartyRoleType-completer # The related party's role type. (default: Employer)
  relationshipType: string@relationshipType-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/($partyId)/roles/($roleId)")
  let body = {partyRoleType: $partyRoleType, relatedPartyId: $relatedPartyId, relatedPartyRoleType: $relatedPartyRoleType, relationshipType: $relationshipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of licenses
#
# GET /licenses
export def "licenses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licenses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of organisations
#
# GET /organisations
export def "organisations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --registeredIdentifier: string # The registered identifier, for example, `ACN` or `ABN`.
  --identifier: string # The identifier, for example, `123456789`.
  --apiKey: string # The API key.
]: nothing -> table<addresses: list<record>, electronicAddresses: list<record>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: list<record>, registeredIdentifiers: list<record>, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "registeredIdentifier" $registeredIdentifier "scalar") (serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organisations" $qp)
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an organisation
#
# POST /organisations
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {name?: string}
# --registeredIdentifiers item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
export def "organisations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
  --electronicAddresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  establishmentDate: string # The organisation's establishment date, for example, `1928-03-03` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1928-03-03)
  legalEntityType: string@legalEntityType-completer # The organisation's legal entity type. (default: Company)
  --names: list # item shape: {name?: string}
  --registeredIdentifiers: list # item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: table<fromDate: string, id: record, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: record, identifier: string, identifierType: string, toDate: string>, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations")
  let body = {addresses: $addresses, electronicAddresses: $electronicAddresses, establishmentDate: $establishmentDate, legalEntityType: $legalEntityType, names: $names, registeredIdentifiers: $registeredIdentifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an organisation
#
# DELETE /organisations/{partyId}
export def "organisations delete" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an organisation
#
# GET /organisations/{partyId}
export def "organisations get" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: table<fromDate: string, id: record, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: record, identifier: string, identifierType: string, toDate: string>, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an organisation
#
# PUT /organisations/{partyId}
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
# --electronicAddresses item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
# --names item shape: {name?: string}
# --registeredIdentifiers item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
export def "organisations put" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --addresses: list # item shape: {city?: string, country?: string, line1?: string, line2?: string, line3?: string, name?: string, postalCode?: string, suburb?: string, addressType?: "Mailing"|"Principal Place of Business"}
  --electronicAddresses: list # item shape: {areaCode?: string, countryPrefix?: string, electronicAddressType?: "Email"|"Fax"|"Landline"|"Mobile"|"Website", email?: string, extension?: string, number?: string, url?: string}
  establishmentDate: string # The organisation's establishment date, for example, `1928-03-03` (in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format). (format: date, e.g. 1928-03-03)
  legalEntityType: string@legalEntityType-completer # The organisation's legal entity type. (default: Company)
  --names: list # item shape: {name?: string}
  --registeredIdentifiers: list # item shape: {identifier?: string, identifierType?: "ACN"|"ABN"}
]: any -> record<addresses: table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string, addressType: string>, electronicAddresses: table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string>, establishmentDate: string, fromDate: string, id: record, legalEntityType: string, names: table<fromDate: string, id: record, name: string, toDate: string>, registeredIdentifiers: table<fromDate: string, id: record, identifier: string, identifierType: string, toDate: string>, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)")
  let body = {addresses: $addresses, electronicAddresses: $electronicAddresses, establishmentDate: $establishmentDate, legalEntityType: $legalEntityType, names: $names, registeredIdentifiers: $registeredIdentifiers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of addresses
#
# GET /organisations/{partyId}/addresses
export def "organisations-addresses list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/addresses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an address
#
# POST /organisations/{partyId}/addresses
export def "organisations-addresses post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postalCode: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/addresses")
  let body = {city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postalCode: $postalCode, suburb: $suburb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an address
#
# DELETE /organisations/{partyId}/addresses/{addressId}
export def "organisations-addresses delete" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an address
#
# GET /organisations/{partyId}/addresses/{addressId}
export def "organisations-addresses get" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an address
#
# PUT /organisations/{partyId}/addresses/{addressId}
export def "organisations-addresses put" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --city: string # The city. (e.g. Canberra)
  --country: string # The country. (e.g. Australia)
  --line1: string # The address line 1. (e.g. Level 7)
  --line2: string # The address line 2. (e.g. 21 Genge Street)
  --line3: string # The address line 3. (e.g. )
  --name: string # The address name. (e.g. Kembery Building)
  --postalCode: string # The postal code. (e.g. 2601)
  --suburb: string # The suburb. (e.g. Civic)
]: any -> record<city: string, country: string, fromDate: string, id: record, line1: string, line2: string, line3: string, name: string, postalCode: string, suburb: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/addresses/($addressId)")
  let body = {city: $city, country: $country, line1: $line1, line2: $line2, line3: $line3, name: $name, postalCode: $postalCode, suburb: $suburb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of business names
#
# GET /organisations/{partyId}/business-names
export def "organisations-business-names list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/business-names")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a business name
#
# POST /organisations/{partyId}/business-names
export def "organisations-business-names post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/business-names")
  let body = {lifecycleState: $lifecycleState, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a business name
#
# DELETE /organisations/{partyId}/business-names/{productId}
export def "organisations-business-names delete" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/business-names/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a business name
#
# GET /organisations/{partyId}/business-names/{productId}
export def "organisations-business-names get" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/business-names/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a business name
#
# PUT /organisations/{partyId}/business-names/{productId}
export def "organisations-business-names put" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
  --name: string # The business name. (e.g. XYZ Technology Ventures)
]: any -> record<fromDate: string, id: record, lifecycleState: string, name: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/business-names/($productId)")
  let body = {lifecycleState: $lifecycleState, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of electronic addresses
#
# GET /organisations/{partyId}/electronic-addresses
export def "organisations-electronic-addresses list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/electronic-addresses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an electronic address
#
# POST /organisations/{partyId}/electronic-addresses
export def "organisations-electronic-addresses post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --areaCode: string # The area code, for example, "02". (e.g. 02)
  --countryPrefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronicAddressType: string@electronicAddressType-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --body-url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/electronic-addresses")
  let body = {areaCode: $areaCode, countryPrefix: $countryPrefix, electronicAddressType: $electronicAddressType, email: $email, extension: $extension, number: $number, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an electronic address
#
# DELETE /organisations/{partyId}/electronic-addresses/{addressId}
export def "organisations-electronic-addresses delete" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/electronic-addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an electronic address
#
# GET /organisations/{partyId}/electronic-addresses/{addressId}
export def "organisations-electronic-addresses get" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/electronic-addresses/($addressId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an electronic address
#
# PUT /organisations/{partyId}/electronic-addresses/{addressId}
export def "organisations-electronic-addresses put" [
  partyId: string
  addressId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --areaCode: string # The area code, for example, "02". (e.g. 02)
  --countryPrefix: string # The country prefix, for example, "61". (e.g. 61)
  --electronicAddressType: string@electronicAddressType-completer # The electronic address type. (default: Landline)
  --email: string # The email address, for example, "robert.ferguson@ato.gov.au". (e.g. )
  --extension: string # The extension number, for example, "4453". (e.g. )
  --number: string # The number, for example, "62164453". (e.g. 62164453)
  --body-url: string # The website address, for example, "https://ato.gov.au". (e.g. )
]: any -> record<areaCode: string, countryPrefix: string, electronicAddressType: string, email: string, extension: string, fromDate: string, id: record, number: string, toDate: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/electronic-addresses/($addressId)")
  let body = {areaCode: $areaCode, countryPrefix: $countryPrefix, electronicAddressType: $electronicAddressType, email: $email, extension: $extension, number: $number, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of licenses
#
# GET /organisations/{partyId}/licenses
export def "organisations-licenses list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/licenses")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a license
#
# POST /organisations/{partyId}/licenses
export def "organisations-licenses post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --licenseType: string@licenseType-completer # The license type. (default: Australian Financial Services License)
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/licenses")
  let body = {licenseType: $licenseType, lifecycleState: $lifecycleState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a license
#
# DELETE /organisations/{partyId}/licenses/{productId}
export def "organisations-licenses delete" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/licenses/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a license
#
# GET /organisations/{partyId}/licenses/{productId}
export def "organisations-licenses get" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/licenses/($productId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a license
#
# PUT /organisations/{partyId}/licenses/{productId}
export def "organisations-licenses put" [
  partyId: string
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --licenseType: string@licenseType-completer # The license type. (default: Australian Financial Services License)
  --lifecycleState: string@lifecycleState-completer # The business name's lifecycle state. (default: Pending Approval)
]: any -> record<fromDate: string, id: record, licenseType: string, lifecycleState: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/licenses/($productId)")
  let body = {licenseType: $licenseType, lifecycleState: $lifecycleState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of roles
#
# GET /organisations/{partyId}/roles
export def "organisations-roles list" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> table<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/roles")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role
#
# POST /organisations/{partyId}/roles
export def "organisations-roles post" [
  partyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --partyRoleType: string@partyRoleType-completer # The party's role type. (default: Employee)
  relatedPartyId: any # The related party's unique identifier.
  --relatedPartyRoleType: string@relatedPartyRoleType-completer # The related party's role type. (default: Employer)
  relationshipType: string@relationshipType-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/roles")
  let body = {partyRoleType: $partyRoleType, relatedPartyId: $relatedPartyId, relatedPartyRoleType: $relatedPartyRoleType, relationshipType: $relationshipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role
#
# DELETE /organisations/{partyId}/roles/{roleId}
export def "organisations-roles delete" [
  partyId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/roles/($roleId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a role
#
# GET /organisations/{partyId}/roles/{roleId}
export def "organisations-roles get" [
  partyId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
]: nothing -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/roles/($roleId)")
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role
#
# PUT /organisations/{partyId}/roles/{roleId}
export def "organisations-roles put" [
  partyId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # The API key.
  --partyRoleType: string@partyRoleType-completer # The party's role type. (default: Employee)
  relatedPartyId: any # The related party's unique identifier.
  --relatedPartyRoleType: string@relatedPartyRoleType-completer # The related party's role type. (default: Employer)
  relationshipType: string@relationshipType-completer # The relationship type. (default: Employment)
]: any -> record<fromDate: string, id: record, partyRoleType: string, relatedPartyId: record, relatedPartyRoleType: string, relationshipType: string, toDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/($partyId)/roles/($roleId)")
  let body = {partyRoleType: $partyRoleType, relatedPartyId: $relatedPartyId, relatedPartyRoleType: $relatedPartyRoleType, relationshipType: $relationshipType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apiKey": $apiKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
