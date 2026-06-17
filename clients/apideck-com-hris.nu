# Auto-generated client for HRIS API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/hris/9.3.0/openapi.json
# Auth: --token flag or $env.HRIS_API_TOKEN

const BASE_URL = "https://unify.apideck.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HRIS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["active" "inactive" "other" "trial"] }
def employment-status-completer [] { ["active" "inactive" "other" "terminated"] }
def gender-completer [] { ["female" "male" "not_specified" "other" "unisex"] }
def leaving-reason-completer [] { ["dismissed" "other" "redundancy" "resigned"] }
def request-type-completer [] { ["bereavement" "jury_duty" "other" "personal" "sick" "vacation" "volunteer"] }
def status-completer-1 [] { ["approved" "cancelled" "declined" "deleted" "other" "requested"] }
def units-completer [] { ["days" "hours" "other"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "hris-companies companiesAll" } } | get name | first)
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

# List Companies
#
# GET /hris/companies
# operationId: companiesAll
export def "hris-companies companiesAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/companies" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Company
#
# POST /hris/companies
# operationId: companiesAdd
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --websites item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
export def "hris-companies companiesAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --company-number: string # An Company Number, Company ID or Company Code, is a unique number that has been assigned to each company. (nullable, e.g. 123456-AB)
  --debtor-id: string # e.g. 12345
  --display-name: string # e.g. SpaceX
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  legal_name: string # e.g. SpaceX
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --status: string@status-completer # e.g. active
  --subdomain: string # e.g. company
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/companies" $qp)
  let body = {"addresses": $addresses, "company_number": $company_number, "debtor_id": $debtor_id, "display_name": $display_name, "emails": $emails, "legal_name": $legal_name, "phone_numbers": $phone_numbers, "status": $status, "subdomain": $subdomain, "websites": $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Company
#
# DELETE /hris/companies/{id}
# operationId: companiesDelete
export def "hris-companies companiesDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/companies/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Company
#
# GET /hris/companies/{id}
# operationId: companiesOne
export def "hris-companies companiesOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/companies/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Company
#
# PATCH /hris/companies/{id}
# operationId: companiesUpdate
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --websites item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
export def "hris-companies companiesUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --company-number: string # An Company Number, Company ID or Company Code, is a unique number that has been assigned to each company. (nullable, e.g. 123456-AB)
  --debtor-id: string # e.g. 12345
  --display-name: string # e.g. SpaceX
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  legal_name: string # e.g. SpaceX
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --status: string@status-completer # e.g. active
  --subdomain: string # e.g. company
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/companies/{id}") $qp)
  let body = {"addresses": $addresses, "company_number": $company_number, "debtor_id": $debtor_id, "display_name": $display_name, "emails": $emails, "legal_name": $legal_name, "phone_numbers": $phone_numbers, "status": $status, "subdomain": $subdomain, "websites": $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Departments
#
# GET /hris/departments
# operationId: departmentsAll
export def "hris-departments departmentsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/departments" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Department
#
# POST /hris/departments
# operationId: departmentsAdd
export def "hris-departments departmentsAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --code: string # nullable, e.g. 2
  --description: string # nullable, e.g. R&D
  --name: string # Department name (nullable, e.g. R&D)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/departments" $qp)
  let body = {"code": $code, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Department
#
# DELETE /hris/departments/{id}
# operationId: departmentsDelete
export def "hris-departments departmentsDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/departments/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Department
#
# GET /hris/departments/{id}
# operationId: departmentsOne
export def "hris-departments departmentsOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/departments/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Department
#
# PATCH /hris/departments/{id}
# operationId: departmentsUpdate
export def "hris-departments departmentsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --code: string # nullable, e.g. 2
  --description: string # nullable, e.g. R&D
  --name: string # Department name (nullable, e.g. R&D)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/departments/{id}") $qp)
  let body = {"code": $code, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Employees
#
# GET /hris/employees
# operationId: employeesAll
export def "hris-employees employeesAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {company_id: 1234, department_id: 1234, email: elon@tesla.com, employee_number: 123456-AB, employment_status: active, first_name: Elon, last_name: Musk, manager_id: 1234, title: Manager})
  --qp-sort: record # Apply sorting (e.g. {by: created_at, direction: desc})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "sort" $qp_sort "deepObject") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/employees" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Employee
#
# POST /hris/employees
# operationId: employeesAdd
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --compensations item shape: {currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", effective_date?: string, flsa_status?: "exempt"|"salaried-nonexempt"|"nonexempt"|"owner", payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", rate?: float}
# --custom_fields item shape: {description?: string, id: string, name?: string, value?: any}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --employment_role shape: {sub_type?: "full_time"|"part_time"|"hourly", type?: "contractor"|"employee"|"freelance"|"temp"|"internship"|"other"}
# --jobs item shape: {compensation_rate?: float, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", end_date?: string, hired_at?: string, is_primary?: bool, location?: record, payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", role?: string, start_date?: string, title?: string}
# --manager shape: {email?: string, employment_status?: "active"|"inactive"|"terminated"|"other", first_name?: string, last_name?: string, name?: string}
# --partner shape: {birthday?: string, deceased_on?: string, first_name?: string, gender?: "male"|"female"|"unisex"|"other"|"not_specified", initials?: string, last_name?: string, middle_name?: string}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --social_links item shape: {id?: string, type?: string, url: string}
# --team shape: {id?: string, name?: string}
@deprecated --flag department
export def "hris-employees employeesAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --birthday: string # The date of birth of the person. (nullable, format: date, e.g. 2000-08-12)
  --company-id: string # The unique identifier of the company. (nullable, e.g. 23456)
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --compensations: list # item shape: {currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", effective_date?: string, flsa_status?: "exempt"|"salaried-nonexempt"|"nonexempt"|"owner", payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", rate?: float}
  --country-of-birth: string # Country code according to ISO 3166-1 alpha-2. (nullable, e.g. US)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --deceased-on: string # The date the person deceased. (nullable, format: date, e.g. 2000-08-12)
  --deleted: oneof<nothing, bool> # nullable, e.g. true
  --department: string # The department the person is currently in. [Deprecated](https://developers.apideck.com/changelog) in favor of the dedicated department_id and department_name field. (DEPRECATED, nullable, e.g. R&D)
  --department-id: string # Unique identifier of the department ID this employee belongs to. (nullable, e.g. 12345)
  --department-name: string # Name of the department this employee belongs to. (nullable, e.g. 12345)
  --description: string # A description of the object. (nullable, e.g. A description)
  --dietary-preference: string # Indicate the employee's dietary preference. (nullable, e.g. Veggie)
  --direct-reports: list # The direct reports refer to the individuals who report directly to a person in the organizational hierarchy. (nullable, e.g. [a0d636c6-43b3-4bde-8c70-85b707d992f4, a98lfd96-43b3-4bde-8c70-85b707d992e6])
  --display-name: string # The name used to display the employee, often a combination of their first and last names. (nullable, e.g. Technoking)
  --division: string # The division the person is currently in. Usually a collection of departments or teams or regions. (nullable, e.g. Europe)
  --division-id: string # Unique identifier of the division this employee belongs to. (nullable, e.g. 12345)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --employee-number: string # An Employee Number, Employee ID or Employee Code, is a unique number that has been assigned to each individual staff member within a company. (nullable, e.g. 123456-AB)
  --employment-end-date: string # An End Date is the date that the employee ended working at the company (nullable, e.g. 2028-10-26)
  --employment-role: record # shape: {sub_type?: "full_time"|"part_time"|"hourly", type?: "contractor"|"employee"|"freelance"|"temp"|"internship"|"other"}
  --employment-start-date: string # A Start Date is the date that the employee started working at the company (nullable, e.g. 2021-10-26)
  --employment-status: string@employment-status-completer # The employment status of the employee, indicating whether they are currently employed, inactive, terminated, or in another status. (nullable, e.g. active)
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --food-allergies: list # Indicate the employee's food allergies. (nullable, e.g. [No allergies])
  --gender: string@gender-completer # The gender represents the gender identity of a person. (nullable, e.g. male)
  --initials: string # The initials of the person, usually derived from their first, middle, and last names. (nullable, e.g. EM)
  --jobs: list # item shape: {compensation_rate?: float, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", end_date?: string, hired_at?: string, is_primary?: bool, location?: record, payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", role?: string, start_date?: string, title?: string}
  --languages: list
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --leaving-reason: string@leaving-reason-completer # The reason because the employment ended. (nullable, e.g. resigned)
  --manager: record # shape: {email?: string, employment_status?: "active"|"inactive"|"terminated"|"other", first_name?: string, last_name?: string, name?: string}
  --marital-status: string # The marital status of the employee. (nullable, e.g. married)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --nationalities: list
  --partner: record # shape: {birthday?: string, deceased_on?: string, first_name?: string, gender?: "male"|"female"|"unisex"|"other"|"not_specified", initials?: string, last_name?: string, middle_name?: string}
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --photo-url: string # The URL of the photo of a person. (nullable, e.g. https://unavatar.io/elon-musk)
  --preferred-language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --preferred-name: string # The name the employee prefers to be addressed by, which may be different from their legal name. (nullable, e.g. Elon Musk)
  --pronouns: string # The preferred pronouns of the person. (nullable, e.g. she,her)
  --record-url: string # nullable, e.g. https://app.intercom.io/contacts/12345
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --salutation: string # A formal salutation for the person. For example, 'Mr', 'Mrs' (nullable, e.g. Mr)
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --social-security-number: string # A unique identifier assigned by the government. This field is considered sensitive information and may be subject to special security and privacy restrictions. (nullable, e.g. 123456789)
  --body-source: string # When the employee is imported as a new hire, this field indicates what system (e.g. the name of the ATS) this employee was imported from. (nullable, e.g. lever)
  --source-id: string # Unique identifier of the employee in the system this employee was imported from (e.g. the ID in the ATS). (nullable, e.g. 12345)
  --tags: list # e.g. [New]
  --tax-code: string # nullable, e.g. 1111
  --tax-id: string # nullable, e.g. 234-32-0000
  --team: record # The team the person is currently in. (nullable) — shape: {id?: string, name?: string}
  --timezone: string # The time zone related to the resource. The value is a string containing a standard time zone identifier, e.g. Europe/London. (nullable, e.g. Europe/London)
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --works-remote: oneof<nothing, bool> # Indicates if the employee works from a remote location. (nullable, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/employees" $qp)
  let body = {"addresses": $addresses, "birthday": $birthday, "company_id": $company_id, "company_name": $company_name, "compensations": $compensations, "country_of_birth": $country_of_birth, "custom_fields": $custom_fields, "deceased_on": $deceased_on, "deleted": $deleted, "department": $department, "department_id": $department_id, "department_name": $department_name, "description": $description, "dietary_preference": $dietary_preference, "direct_reports": $direct_reports, "display_name": $display_name, "division": $division, "division_id": $division_id, "emails": $emails, "employee_number": $employee_number, "employment_end_date": $employment_end_date, "employment_role": $employment_role, "employment_start_date": $employment_start_date, "employment_status": $employment_status, "first_name": $first_name, "food_allergies": $food_allergies, "gender": $gender, "initials": $initials, "jobs": $jobs, "languages": $languages, "last_name": $last_name, "leaving_reason": $leaving_reason, "manager": $manager, "marital_status": $marital_status, "middle_name": $middle_name, "nationalities": $nationalities, "partner": $partner, "phone_numbers": $phone_numbers, "photo_url": $photo_url, "preferred_language": $preferred_language, "preferred_name": $preferred_name, "pronouns": $pronouns, "record_url": $record_url, "row_version": $row_version, "salutation": $salutation, "social_links": $social_links, "social_security_number": $social_security_number, "source": $body_source, "source_id": $source_id, "tags": $tags, "tax_code": $tax_code, "tax_id": $tax_id, "team": $team, "timezone": $timezone, "title": $title, "works_remote": $works_remote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Employee
#
# DELETE /hris/employees/{id}
# operationId: employeesDelete
export def "hris-employees employeesDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/employees/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Employee
#
# GET /hris/employees/{id}
# operationId: employeesOne
export def "hris-employees employeesOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/employees/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Employee
#
# PATCH /hris/employees/{id}
# operationId: employeesUpdate
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --compensations item shape: {currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", effective_date?: string, flsa_status?: "exempt"|"salaried-nonexempt"|"nonexempt"|"owner", payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", rate?: float}
# --custom_fields item shape: {description?: string, id: string, name?: string, value?: any}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --employment_role shape: {sub_type?: "full_time"|"part_time"|"hourly", type?: "contractor"|"employee"|"freelance"|"temp"|"internship"|"other"}
# --jobs item shape: {compensation_rate?: float, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", end_date?: string, hired_at?: string, is_primary?: bool, location?: record, payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", role?: string, start_date?: string, title?: string}
# --manager shape: {email?: string, employment_status?: "active"|"inactive"|"terminated"|"other", first_name?: string, last_name?: string, name?: string}
# --partner shape: {birthday?: string, deceased_on?: string, first_name?: string, gender?: "male"|"female"|"unisex"|"other"|"not_specified", initials?: string, last_name?: string, middle_name?: string}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --social_links item shape: {id?: string, type?: string, url: string}
# --team shape: {id?: string, name?: string}
@deprecated --flag department
export def "hris-employees employeesUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --birthday: string # The date of birth of the person. (nullable, format: date, e.g. 2000-08-12)
  --company-id: string # The unique identifier of the company. (nullable, e.g. 23456)
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --compensations: list # item shape: {currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", effective_date?: string, flsa_status?: "exempt"|"salaried-nonexempt"|"nonexempt"|"owner", payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", rate?: float}
  --country-of-birth: string # Country code according to ISO 3166-1 alpha-2. (nullable, e.g. US)
  --custom-fields: list # item shape: {description?: string, id: string, name?: string, value?: any}
  --deceased-on: string # The date the person deceased. (nullable, format: date, e.g. 2000-08-12)
  --deleted: oneof<nothing, bool> # nullable, e.g. true
  --department: string # The department the person is currently in. [Deprecated](https://developers.apideck.com/changelog) in favor of the dedicated department_id and department_name field. (DEPRECATED, nullable, e.g. R&D)
  --department-id: string # Unique identifier of the department ID this employee belongs to. (nullable, e.g. 12345)
  --department-name: string # Name of the department this employee belongs to. (nullable, e.g. 12345)
  --description: string # A description of the object. (nullable, e.g. A description)
  --dietary-preference: string # Indicate the employee's dietary preference. (nullable, e.g. Veggie)
  --direct-reports: list # The direct reports refer to the individuals who report directly to a person in the organizational hierarchy. (nullable, e.g. [a0d636c6-43b3-4bde-8c70-85b707d992f4, a98lfd96-43b3-4bde-8c70-85b707d992e6])
  --display-name: string # The name used to display the employee, often a combination of their first and last names. (nullable, e.g. Technoking)
  --division: string # The division the person is currently in. Usually a collection of departments or teams or regions. (nullable, e.g. Europe)
  --division-id: string # Unique identifier of the division this employee belongs to. (nullable, e.g. 12345)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --employee-number: string # An Employee Number, Employee ID or Employee Code, is a unique number that has been assigned to each individual staff member within a company. (nullable, e.g. 123456-AB)
  --employment-end-date: string # An End Date is the date that the employee ended working at the company (nullable, e.g. 2028-10-26)
  --employment-role: record # shape: {sub_type?: "full_time"|"part_time"|"hourly", type?: "contractor"|"employee"|"freelance"|"temp"|"internship"|"other"}
  --employment-start-date: string # A Start Date is the date that the employee started working at the company (nullable, e.g. 2021-10-26)
  --employment-status: string@employment-status-completer # The employment status of the employee, indicating whether they are currently employed, inactive, terminated, or in another status. (nullable, e.g. active)
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --food-allergies: list # Indicate the employee's food allergies. (nullable, e.g. [No allergies])
  --gender: string@gender-completer # The gender represents the gender identity of a person. (nullable, e.g. male)
  --initials: string # The initials of the person, usually derived from their first, middle, and last names. (nullable, e.g. EM)
  --jobs: list # item shape: {compensation_rate?: float, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", end_date?: string, hired_at?: string, is_primary?: bool, location?: record, payment_unit?: "hour"|"week"|"month"|"year"|"paycheck", role?: string, start_date?: string, title?: string}
  --languages: list
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --leaving-reason: string@leaving-reason-completer # The reason because the employment ended. (nullable, e.g. resigned)
  --manager: record # shape: {email?: string, employment_status?: "active"|"inactive"|"terminated"|"other", first_name?: string, last_name?: string, name?: string}
  --marital-status: string # The marital status of the employee. (nullable, e.g. married)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --nationalities: list
  --partner: record # shape: {birthday?: string, deceased_on?: string, first_name?: string, gender?: "male"|"female"|"unisex"|"other"|"not_specified", initials?: string, last_name?: string, middle_name?: string}
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --photo-url: string # The URL of the photo of a person. (nullable, e.g. https://unavatar.io/elon-musk)
  --preferred-language: string # language code according to ISO 639-1. For the United States - EN (nullable, e.g. EN)
  --preferred-name: string # The name the employee prefers to be addressed by, which may be different from their legal name. (nullable, e.g. Elon Musk)
  --pronouns: string # The preferred pronouns of the person. (nullable, e.g. she,her)
  --record-url: string # nullable, e.g. https://app.intercom.io/contacts/12345
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --salutation: string # A formal salutation for the person. For example, 'Mr', 'Mrs' (nullable, e.g. Mr)
  --social-links: list # item shape: {id?: string, type?: string, url: string}
  --social-security-number: string # A unique identifier assigned by the government. This field is considered sensitive information and may be subject to special security and privacy restrictions. (nullable, e.g. 123456789)
  --body-source: string # When the employee is imported as a new hire, this field indicates what system (e.g. the name of the ATS) this employee was imported from. (nullable, e.g. lever)
  --source-id: string # Unique identifier of the employee in the system this employee was imported from (e.g. the ID in the ATS). (nullable, e.g. 12345)
  --tags: list # e.g. [New]
  --tax-code: string # nullable, e.g. 1111
  --tax-id: string # nullable, e.g. 234-32-0000
  --team: record # The team the person is currently in. (nullable) — shape: {id?: string, name?: string}
  --timezone: string # The time zone related to the resource. The value is a string containing a standard time zone identifier, e.g. Europe/London. (nullable, e.g. Europe/London)
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --works-remote: oneof<nothing, bool> # Indicates if the employee works from a remote location. (nullable, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/employees/{id}") $qp)
  let body = {"addresses": $addresses, "birthday": $birthday, "company_id": $company_id, "company_name": $company_name, "compensations": $compensations, "country_of_birth": $country_of_birth, "custom_fields": $custom_fields, "deceased_on": $deceased_on, "deleted": $deleted, "department": $department, "department_id": $department_id, "department_name": $department_name, "description": $description, "dietary_preference": $dietary_preference, "direct_reports": $direct_reports, "display_name": $display_name, "division": $division, "division_id": $division_id, "emails": $emails, "employee_number": $employee_number, "employment_end_date": $employment_end_date, "employment_role": $employment_role, "employment_start_date": $employment_start_date, "employment_status": $employment_status, "first_name": $first_name, "food_allergies": $food_allergies, "gender": $gender, "initials": $initials, "jobs": $jobs, "languages": $languages, "last_name": $last_name, "leaving_reason": $leaving_reason, "manager": $manager, "marital_status": $marital_status, "middle_name": $middle_name, "nationalities": $nationalities, "partner": $partner, "phone_numbers": $phone_numbers, "photo_url": $photo_url, "preferred_language": $preferred_language, "preferred_name": $preferred_name, "pronouns": $pronouns, "record_url": $record_url, "row_version": $row_version, "salutation": $salutation, "social_links": $social_links, "social_security_number": $social_security_number, "source": $body_source, "source_id": $source_id, "tags": $tags, "tax_code": $tax_code, "tax_id": $tax_id, "team": $team, "timezone": $timezone, "title": $title, "works_remote": $works_remote} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Jobs
#
# GET /hris/jobs/employees/{employee_id}
# operationId: jobsAll
export def "hris-jobs-employees jobsAll" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({employee_id: $employee_id} | format pattern "/hris/jobs/employees/{employee_id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# One Job
#
# GET /hris/jobs/employees/{employee_id}/jobs/{job_id}
# operationId: jobsOne
export def "hris-jobs-employees-jobs jobsOne" [
  employee_id: string
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({employee_id: $employee_id, job_id: $job_id} | format pattern "/hris/jobs/employees/{employee_id}/jobs/{job_id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Payroll
#
# GET /hris/payrolls
# operationId: payrollsAll
export def "hris-payrolls payrollsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --filter: record # Apply filters (e.g. {end_date: 2022-04-21, start_date: 2022-04-08})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/payrolls" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Employee Payrolls
#
# GET /hris/payrolls/employees/{employee_id}
# operationId: employeePayrollsAll
export def "hris-payrolls-employees employeePayrollsAll" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --filter: record # Apply filters (e.g. {end_date: 2022-04-21, start_date: 2022-04-08})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({employee_id: $employee_id} | format pattern "/hris/payrolls/employees/{employee_id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Employee Payroll
#
# GET /hris/payrolls/employees/{employee_id}/payrolls/{payroll_id}
# operationId: employeePayrollsOne
export def "hris-payrolls-employees-payrolls employeePayrollsOne" [
  employee_id: string
  payroll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({employee_id: $employee_id, payroll_id: $payroll_id} | format pattern "/hris/payrolls/employees/{employee_id}/payrolls/{payroll_id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payroll
#
# GET /hris/payrolls/{payroll_id}
# operationId: payrollsOne
export def "hris-payrolls payrollsOne" [
  payroll_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payroll_id: $payroll_id} | format pattern "/hris/payrolls/{payroll_id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Employee Schedules
#
# GET /hris/schedules/employees/{employee_id}
# operationId: employeeSchedulesAll
export def "hris-schedules-employees employeeSchedulesAll" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({employee_id: $employee_id} | format pattern "/hris/schedules/employees/{employee_id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Time Off Requests
#
# GET /hris/time-off-requests
# operationId: timeOffRequestsAll
export def "hris-time-off-requests timeOffRequestsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {employee_id: 1234, end_date: 2022-04-21, start_date: 2022-04-08, time_off_request_status: approved})
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/time-off-requests" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Time Off Request
#
# POST /hris/time-off-requests
# operationId: timeOffRequestsAdd
# --notes shape: {employee?: string, manager?: string}
export def "hris-time-off-requests timeOffRequestsAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --amount: float # The amount of time off requested. (e.g. 3.5)
  --approval-date: string # The date the request was approved (e.g. 2022-03-21)
  --description: string # Description of the time off request. (e.g. Enjoying some sun.)
  --employee-id: string # ID of the employee (e.g. 12345)
  --end-date: string # The end date of the time off request. (e.g. 2022-04-01)
  --notes: record # shape: {employee?: string, manager?: string}
  --policy-id: string # ID of the policy (e.g. 12345)
  --request-date: string # The date the request was made. (e.g. 2022-03-21)
  --request-type: string@request-type-completer # The type of request (e.g. vacation)
  --start-date: string # The start date of the time off request. (e.g. 2022-04-01)
  --status: string@status-completer-1 # The status of the time off request. (e.g. approved)
  --units: string@units-completer # The unit of time off requested. Possible values include: `hours`, `days`, or `other`. (e.g. hours)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hris/time-off-requests" $qp)
  let body = {"amount": $amount, "approval_date": $approval_date, "description": $description, "employee_id": $employee_id, "end_date": $end_date, "notes": $notes, "policy_id": $policy_id, "request_date": $request_date, "request_type": $request_type, "start_date": $start_date, "status": $status, "units": $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Time Off Request
#
# DELETE /hris/time-off-requests/{id}
# operationId: timeOffRequestsDelete
export def "hris-time-off-requests timeOffRequestsDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/time-off-requests/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Time Off Request
#
# GET /hris/time-off-requests/{id}
# operationId: timeOffRequestsOne
export def "hris-time-off-requests timeOffRequestsOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/time-off-requests/{id}") $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Time Off Request
#
# PATCH /hris/time-off-requests/{id}
# operationId: timeOffRequestsUpdate
# --notes shape: {employee?: string, manager?: string}
export def "hris-time-off-requests timeOffRequestsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --amount: float # The amount of time off requested. (e.g. 3.5)
  --approval-date: string # The date the request was approved (e.g. 2022-03-21)
  --description: string # Description of the time off request. (e.g. Enjoying some sun.)
  --employee-id: string # ID of the employee (e.g. 12345)
  --end-date: string # The end date of the time off request. (e.g. 2022-04-01)
  --notes: record # shape: {employee?: string, manager?: string}
  --policy-id: string # ID of the policy (e.g. 12345)
  --request-date: string # The date the request was made. (e.g. 2022-03-21)
  --request-type: string@request-type-completer # The type of request (e.g. vacation)
  --start-date: string # The start date of the time off request. (e.g. 2022-04-01)
  --status: string@status-completer-1 # The status of the time off request. (e.g. approved)
  --units: string@units-completer # The unit of time off requested. Possible values include: `hours`, `days`, or `other`. (e.g. hours)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hris/time-off-requests/{id}") $qp)
  let body = {"amount": $amount, "approval_date": $approval_date, "description": $description, "employee_id": $employee_id, "end_date": $end_date, "notes": $notes, "policy_id": $policy_id, "request_date": $request_date, "request_type": $request_type, "start_date": $start_date, "status": $status, "units": $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
