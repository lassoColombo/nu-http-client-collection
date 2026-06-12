# Auto-generated client for Onfido Public API v3.6 vv3.6
# Source: https://raw.githubusercontent.com/onfido/onfido-openapi-spec/master/generated/artifacts/openapi/openapi.json
# Auth: --token flag or $env.ONFIDO_PUBLIC_API_V3_6_TOKEN

const BASE_URL = "https://api.eu.onfido.com/v3.6"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ONFIDO_PUBLIC_API_V3_6_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["https://api.eu.onfido.com/v3.6" "https://api.us.onfido.com/v3.6" "https://api.ca.onfido.com/v3.6"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["asc" "desc"] }
def accept-completer [] { ["application/json" "application/pdf"] }
def accept-completer-1 [] { ["application/json" "application/zip"] }
def side-completer [] { ["back" "front"] }
def accept-completer-2 [] { ["*/*" "application/json"] }
def report-name-completer [] { ["watchlist_aml" "watchlist_standard"] }
def state-completer [] { ["ACTIVE" "INACTIVE"] }
def accept-completer-3 [] { ["application/json" "text/plain"] }
def expected-result-completer [] { ["clear" "consider"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applicants applicants" } } | get name | first)
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

# List Applicants
#
# GET /applicants
# operationId: list_applicants
export def "applicants applicants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page to return. The first page is `page=1` (default: 1)
  --per-page: int # The number of objects per page. (default: 20)
  --include-deleted: oneof<nothing, bool> # Whether to also include applicants scheduled for deletion. (default: false)
]: nothing -> record<applicants: table<email: string, dob: string, id_numbers: list, phone_number: string, first_name: string, last_name: string, id: string, created_at: string, delete_at: string, href: string, sandbox: bool, address: record, location: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include_deleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applicants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Applicant
#
# POST /applicants
# operationId: create_applicant
# --id_numbers item shape: {type?: "ssn"|"social_insurance"|"tax_id"|"identity_card"|"driving_license"|"driving_licence"|"share_code"|"voter_id"|"passport"|"other", value?: string, state_code?: string}
# --consents item shape: {name: "privacy_notices_read"|"ssn_verification"|"phone_number_verification", granted: bool}
export def "applicants applicant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The applicant's email address. Required if doing a US check, or a UK check for which `applicant_provides_data` is `true`.
  --dob: string # The applicant's date of birth (format: date)
  --id-numbers: list # item shape: {type?: "ssn"|"social_insurance"|"tax_id"|"identity_card"|"driving_license"|"driving_licence"|"share_code"|"voter_id"|"passport"|"other", value?: string, state_code?: string}
  --phone-number: string # The applicant's phone number
  --consents: list # The applicant's consents — item shape: {name: "privacy_notices_read"|"ssn_verification"|"phone_number_verification", granted: bool}
  --address: any
  --location: any
  first_name: string # The applicant's first name
  last_name: string # The applicant's surname
]: any -> record<email: string, dob: string, id_numbers: table<type: string, value: string, state_code: string>, phone_number: string, first_name: string, last_name: string, id: string, created_at: string, delete_at: string, href: string, sandbox: bool, address: record<flat_number: string, building_number: string, building_name: string, street: string, sub_street: string, town: string, postcode: string, country: string, state: string, line1: string, line2: string, line3: string>, location: record<ip_address: string, country_of_residence: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applicants")
  let body = {email: $email, dob: $dob, id_numbers: $id_numbers, phone_number: $phone_number, consents: $consents, address: $address, location: $location, first_name: $first_name, last_name: $last_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Applicant
#
# DELETE /applicants/{applicant_id}
# operationId: delete_applicant
export def "applicants applicant-by-applicant_id" [
  applicant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applicants/($applicant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Applicant
#
# GET /applicants/{applicant_id}
# operationId: find_applicant
export def "applicants applicant-by-applicant_id-1" [
  applicant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<email: string, dob: string, id_numbers: table<type: string, value: string, state_code: string>, phone_number: string, first_name: string, last_name: string, id: string, created_at: string, delete_at: string, href: string, sandbox: bool, address: record<flat_number: string, building_number: string, building_name: string, street: string, sub_street: string, town: string, postcode: string, country: string, state: string, line1: string, line2: string, line3: string>, location: record<ip_address: string, country_of_residence: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applicants/($applicant_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Applicant
#
# PUT /applicants/{applicant_id}
# operationId: update_applicant
# --id_numbers item shape: {type?: "ssn"|"social_insurance"|"tax_id"|"identity_card"|"driving_license"|"driving_licence"|"share_code"|"voter_id"|"passport"|"other", value?: string, state_code?: string}
# --consents item shape: {name: "privacy_notices_read"|"ssn_verification"|"phone_number_verification", granted: bool}
export def "applicants applicant-by-applicant_id-2" [
  applicant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The applicant's email address. Required if doing a US check, or a UK check for which `applicant_provides_data` is `true`.
  --dob: string # The applicant's date of birth (format: date)
  --id-numbers: list # item shape: {type?: "ssn"|"social_insurance"|"tax_id"|"identity_card"|"driving_license"|"driving_licence"|"share_code"|"voter_id"|"passport"|"other", value?: string, state_code?: string}
  --phone-number: string # The applicant's phone number
  --consents: list # The applicant's consents — item shape: {name: "privacy_notices_read"|"ssn_verification"|"phone_number_verification", granted: bool}
  --address: any
  --location: any
  --first-name: string # The applicant's first name
  --last-name: string # The applicant's surname
]: any -> record<email: string, dob: string, id_numbers: table<type: string, value: string, state_code: string>, phone_number: string, first_name: string, last_name: string, id: string, created_at: string, delete_at: string, href: string, sandbox: bool, address: record<flat_number: string, building_number: string, building_name: string, street: string, sub_street: string, town: string, postcode: string, country: string, state: string, line1: string, line2: string, line3: string>, location: record<ip_address: string, country_of_residence: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applicants/($applicant_id)")
  let body = {email: $email, dob: $dob, id_numbers: $id_numbers, phone_number: $phone_number, consents: $consents, address: $address, location: $location, first_name: $first_name, last_name: $last_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restore Applicant
#
# POST /applicants/{applicant_id}/restore
# operationId: restore_applicant
export def "applicants-restore applicant" [
  applicant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applicants/($applicant_id)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Applicant Consents
#
# GET /applicants/{applicant_id}/consents
# operationId: find_applicant_consents
export def "applicants-consents consents" [
  applicant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, granted: bool, granted_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applicants/($applicant_id)/consents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Workflow Runs
#
# GET /workflow_runs
# operationId: list_workflow_runs
export def "workflow-runs runs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The number of the page to be retrieved. If not specified, defaults to 1. (default: 1)
  --status: string # A list of comma separated status values to filter the results. Possible values are 'processing', 'awaiting_input', 'approved', 'declined', 'review', 'abandoned' and 'error'.
  --created-at-gt: string # A ISO-8601 date to filter results with a created date greater than (after) the one provided. (format: date)
  --created-at-lt: string # A ISO-8601 date to filter results with a created date less than (before) the one provided. (format: date)
  --qp-sort: string@sort-completer # A string with the value 'desc' or 'asc' that allows to sort the returned list by the completed datetime either descending or ascending, respectively. If not specified, defaults to 'desc'. (default: desc)
  --applicant-id: string # the applicant's id. (format: uuid)
  --tags: list # A list of tags to filter the results.
]: nothing -> table<applicant_id: string, workflow_id: string, tags: list<string>, customer_user_id: string, link: record, created_at: string, updated_at: string, id: string, workflow_version_id: int, dashboard_url: string, status: record, output: record, reasons: list<string>, error: record, sdk_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "created_at_gt" $created_at_gt "scalar") (serialize-qp "created_at_lt" $created_at_lt "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "applicant_id" $applicant_id "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/workflow_runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Workflow Run
#
# POST /workflow_runs
# operationId: create_workflow_run
# --link shape: {url?: string, completed_redirect_url?: string, expired_redirect_url?: string, expires_at?: string, language?: "en_US"|"de_DE"|"es_ES"|"fr_FR"|"it_IT"|"pt_PT"|"nl_NL"}
export def "workflow-runs run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicant_id: string # The unique identifier for the Applicant. (format: uuid)
  workflow_id: string # The unique identifier for the Workflow. (format: uuid)
  --tags: list # Tags or labels assigned to the workflow run. (nullable)
  --customer-user-id: string # Customer-provided user identifier.
  --link: record # Object for the configuration of the Workflow Run link. — shape: {url?: string, completed_redirect_url?: string, expired_redirect_url?: string, expires_at?: string, language?: "en_US"|"de_DE"|"es_ES"|"fr_FR"|"it_IT"|"pt_PT"|"nl_NL"}
  --created-at: string # The date and time when the Workflow Run was created. (format: date-time)
  --updated-at: string # The date and time when the Workflow Run was last updated. (format: date-time)
  --custom-data: record # Object with Custom Input Data to be used in the Workflow Run.
]: any -> record<applicant_id: string, workflow_id: string, tags: list<string>, customer_user_id: string, link: record, created_at: string, updated_at: string, id: string, workflow_version_id: int, dashboard_url: string, status: record, output: record, reasons: list<string>, error: record, sdk_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workflow_runs")
  let body = {applicant_id: $applicant_id, workflow_id: $workflow_id, tags: $tags, customer_user_id: $customer_user_id, link: $link, created_at: $created_at, updated_at: $updated_at, custom_data: $custom_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Workflow Run
#
# GET /workflow_runs/{workflow_run_id}
# operationId: find_workflow_run
export def "workflow-runs run-by-workflow_run_id" [
  workflow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applicant_id: string, workflow_id: string, tags: list<string>, customer_user_id: string, link: record, created_at: string, updated_at: string, id: string, workflow_version_id: int, dashboard_url: string, status: record, output: record, reasons: list<string>, error: record, sdk_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Workflow Run Evidence Summary File
#
# GET /workflow_runs/{workflow_run_id}/signed_evidence_file
# operationId: download_signed_evidence_file
export def "workflow-runs-signed-evidence-file file" [
  workflow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/signed_evidence_file")
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Workflow Run Evidence Folder
#
# GET /workflow_runs/{workflow_run_id}/evidence_folder
# operationId: download_evidence_folder
export def "workflow-runs-evidence-folder folder" [
  workflow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/evidence_folder")
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List documents
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
  --applicant-id: string # format: uuid
]: nothing -> record<documents: table<file_type: string, type: string, side: string, issuing_country: string, applicant_id: string, id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a document
#
# POST /documents
# operationId: upload_document
export def "documents document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file-type: string # The file type of the uploaded file
  type: string # The type of document
  --side: string@side-completer # The side of the document, if applicable. The possible values are front and back
  --issuing-country: string # The issuing country of the document, a 3-letter ISO code.
  applicant_id: string # The ID of the applicant whose document is being uploaded. (format: uuid)
  file: string # The file to be uploaded. (format: binary)
  --validate-image-quality: oneof<nothing, bool> # Defaults to false. When true the submitted image will undergo an image quality validation which may take up to 5 seconds.
  --location: any
]: any -> record<file_type: string, type: string, side: string, issuing_country: string, applicant_id: string, id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let body = {file_type: $file_type, type: $type, side: $side, issuing_country: $issuing_country, applicant_id: $applicant_id, file: $file, validate_image_quality: $validate_image_quality, location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve document
#
# GET /documents/{document_id}
# operationId: find_document
export def "documents document-by-document_id" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<file_type: string, type: string, side: string, issuing_country: string, applicant_id: string, id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($document_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download document
#
# GET /documents/{document_id}/download
# operationId: download_document
export def "documents-download document" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($document_id)/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download NFC face
#
# GET /documents/{document_id}/nfc_face
# operationId: download_nfc_face
export def "documents-nfc-face face" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($document_id)/nfc_face")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download document video
#
# GET /documents/{document_id}/video/download
# operationId: download_document_video
export def "documents-video-download video" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($document_id)/video/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List signing documents
#
# GET /signing_documents
# operationId: list_signing_documents
export def "signing-documents documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # format: uuid
]: nothing -> record<signing_documents: table<applicant_id: string, id: string, created_at: string, href: string, download_href: string, file_type: string, file_name: string, file_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/signing_documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a signing document
#
# POST /signing_documents
# operationId: upload_signing_document
export def "signing-documents document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicant_id: string # The ID of the applicant whose signing document is being uploaded. (format: uuid)
  file: string # The file to be uploaded. (format: binary)
]: any -> record<applicant_id: string, id: string, created_at: string, href: string, download_href: string, file_type: string, file_name: string, file_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signing_documents")
  let body = {applicant_id: $applicant_id, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve signing document
#
# GET /signing_documents/{signing_document_id}
# operationId: find_signing_document
export def "signing-documents document-by-signing_document_id" [
  signing_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applicant_id: string, id: string, created_at: string, href: string, download_href: string, file_type: string, file_name: string, file_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signing_documents/($signing_document_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download signing document
#
# GET /signing_documents/{signing_document_id}/download
# operationId: download_signing_document
export def "signing-documents-download document" [
  signing_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signing_documents/($signing_document_id)/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List live photos
#
# GET /live_photos
# operationId: list_live_photos
export def "live-photos photos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # The id of the applicant the live photos belong to. (format: uuid)
]: nothing -> record<live_photos: table<id: string, created_at: string, href: string, download_href: string, file_name: string, file_type: string, file_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/live_photos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload live photo
#
# POST /live_photos
# operationId: upload_live_photo
export def "live-photos photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicant_id: string # The ID of the applicant whose live photo is being uploaded. (format: uuid)
  file: string # The file to be uploaded. (format: binary)
  --advanced-validation: oneof<nothing, bool> # Validates that the live photo contains exactly one face. (default: true)
]: any -> record<id: string, created_at: string, href: string, download_href: string, file_name: string, file_type: string, file_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live_photos")
  let body = {applicant_id: $applicant_id, file: $file, advanced_validation: $advanced_validation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve live photo
#
# GET /live_photos/{live_photo_id}
# operationId: find_live_photo
export def "live-photos photo-by-live_photo_id" [
  live_photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: string, href: string, download_href: string, file_name: string, file_type: string, file_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/live_photos/($live_photo_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download live photo
#
# GET /live_photos/{live_photo_id}/download
# operationId: download_live_photo
export def "live-photos-download photo" [
  live_photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/live_photos/($live_photo_id)/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List live videos
#
# GET /live_videos
# operationId: list_live_videos
export def "live-videos videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # The id of the applicant the live videos belong to. (format: uuid)
]: nothing -> record<live_videos: table<id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int, file_type: string, challenge: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/live_videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve live video
#
# GET /live_videos/{live_video_id}
# operationId: find_live_video
export def "live-videos video" [
  live_video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int, file_type: string, challenge: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/live_videos/($live_video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download live video
#
# GET /live_videos/{live_video_id}/download
# operationId: download_live_video
export def "live-videos-download video" [
  live_video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/live_videos/($live_video_id)/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download live video frame
#
# GET /live_videos/{live_video_id}/frame
# operationId: download_live_video_frame
export def "live-videos-frame frame" [
  live_video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/live_videos/($live_video_id)/frame")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Tasks
#
# GET /workflow_runs/{workflow_run_id}/tasks
# operationId: list_tasks
export def "workflow-runs-tasks tasks" [
  workflow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, workflow_run_id: string, task_def_id: string, task_def_version: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Task
#
# GET /workflow_runs/{workflow_run_id}/tasks/{task_id}
# operationId: find_task
export def "workflow-runs-tasks task" [
  workflow_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, workflow_run_id: string, task_def_id: string, task_def_version: string, input: record, output: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete Task
#
# POST /workflow_runs/{workflow_run_id}/tasks/{task_id}/complete
# operationId: complete_task
export def "workflow-runs-tasks-complete task" [
  workflow_run_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: any # The Task completion payload.
]: any -> record<error: record<type: string, message: string, fields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/tasks/($task_id)/complete")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List motion captures
#
# GET /motion_captures
# operationId: list_motion_captures
export def "motion-captures captures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # The id of the applicant the motion captures belong to. (format: uuid)
]: nothing -> record<motion_captures: table<id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int, file_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/motion_captures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve motion capture
#
# GET /motion_captures/{motion_capture_id}
# operationId: find_motion_capture
export def "motion-captures capture" [
  motion_capture_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: string, href: string, download_href: string, file_name: string, file_size: int, file_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/motion_captures/($motion_capture_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download motion capture
#
# GET /motion_captures/{motion_capture_id}/download
# operationId: download_motion_capture
export def "motion-captures-download capture" [
  motion_capture_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/motion_captures/($motion_capture_id)/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download motion capture frame
#
# GET /motion_captures/{motion_capture_id}/frame
# operationId: download_motion_capture_frame
export def "motion-captures-frame frame" [
  motion_capture_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/motion_captures/($motion_capture_id)/frame")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List monitors
#
# GET /watchlist_monitors
# operationId: list_watchlist_monitors
export def "watchlist-monitors monitors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # The id of the applicant the watchlist monitors belong to. If omitted, all monitors for the account will be listed. (format: uuid)
  --include-deleted: oneof<nothing, bool> # Whether to also include deleted (inactive) monitors. (default: false)
]: nothing -> record<monitors: table<applicant_id: string, report_name: string, tags: list, id: string, created_at: string, deleted_at: string, is_sandbox: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar") (serialize-qp "include_deleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/watchlist_monitors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create monitor
#
# POST /watchlist_monitors
# operationId: create_watchlist_monitor
export def "watchlist-monitors monitor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicant_id: string # The ID for the applicant associated with the monitor. (format: uuid)
  report_name: string@report-name-completer # The name of the report type the monitor creates.
  --tags: list # A list of tags associated with this monitor. These tags will be applied to each check this monitor creates.
]: any -> record<applicant_id: string, report_name: string, tags: list<string>, id: string, created_at: string, deleted_at: string, is_sandbox: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_monitors")
  let body = {applicant_id: $applicant_id, report_name: $report_name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete monitor
#
# DELETE /watchlist_monitors/{monitor_id}
# operationId: delete_watchlist_monitor
export def "watchlist-monitors monitor-by-monitor_id" [
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/watchlist_monitors/($monitor_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve monitor
#
# GET /watchlist_monitors/{monitor_id}
# operationId: find_watchlist_monitor
export def "watchlist-monitors monitor-by-monitor_id-1" [
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applicant_id: string, report_name: string, tags: list<string>, id: string, created_at: string, deleted_at: string, is_sandbox: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/watchlist_monitors/($monitor_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List matches (BETA)
#
# GET /watchlist_monitors/{monitor_id}/matches
# operationId: list_watchlist_monitor_matches
export def "watchlist-monitors-matches matches" [
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<matches: table<id: string, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/watchlist_monitors/($monitor_id)/matches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set match status (BETA)
#
# PATCH /watchlist_monitors/{monitor_id}/matches
# operationId: update_watchlist_monitor_match
export def "watchlist-monitors-matches match" [
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enable: list
  --disable: list
]: any -> record<matches: table<id: string, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/watchlist_monitors/($monitor_id)/matches")
  let body = {enable: $enable, disable: $disable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Force new report creation (BETA)
#
# POST /watchlist_monitors/{monitor_id}/new_report
# operationId: force_report_creation_from_watchlist_monitor
export def "watchlist-monitors-new-report monitor" [
  monitor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/watchlist_monitors/($monitor_id)/new_report")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List ID photos
#
# GET /id_photos
# operationId: list_id_photos
export def "id-photos photos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # The id of the applicant the ID photos belong to. (format: uuid)
]: nothing -> record<id_photos: table<id: string, created_at: string, href: string, download_href: string, file_name: string, file_type: string, file_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/id_photos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload ID photo
#
# POST /id_photos
# operationId: upload_id_photo
export def "id-photos photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicant_id: string # The ID of the applicant whose ID photo is being uploaded. (format: uuid)
  file: string # The file to be uploaded. (format: binary)
]: any -> record<id: string, created_at: string, href: string, download_href: string, file_name: string, file_type: string, file_size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/id_photos")
  let body = {applicant_id: $applicant_id, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve ID photo
#
# GET /id_photos/{id_photo_id}
# operationId: find_id_photo
export def "id-photos photo-by-id_photo_id" [
  id_photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, created_at: string, href: string, download_href: string, file_name: string, file_type: string, file_size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/id_photos/($id_photo_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download ID photo
#
# GET /id_photos/{id_photo_id}/download
# operationId: download_id_photo
export def "id-photos-download photo" [
  id_photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/id_photos/($id_photo_id)/download")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the signed document or application form
#
# GET /qualified_electronic_signature/documents
# operationId: download_qes_document
export def "qualified-electronic-signature-documents document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --workflow-run-id: string # The unique identifier of the Workflow Run for which you want to retrieve the signed document. (format: uuid)
  --file-id: string # The unique identifier of the file which you want to retrieve. (format: uuid)
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qualified_electronic_signature/documents" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the signed document or signing transaction receipt
#
# GET /advanced_electronic_signature/documents
# operationId: download_aes_document
export def "advanced-electronic-signature-documents document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --workflow-run-id: string # The unique identifier of the Workflow Run for which you want to retrieve the signed document. (format: uuid)
  --id: string # The unique identifier of the file which you want to retrieve. (format: uuid)
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/advanced_electronic_signature/documents" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the signed document or signing transaction receipt
#
# GET /simple_electronic_signature/documents
# operationId: download_ses_document
export def "simple-electronic-signature-documents document" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --workflow-run-id: string # The unique identifier of the Workflow Run for which you want to retrieve the signed document. (format: uuid)
  --id: string # The unique identifier of the file which you want to retrieve. (format: uuid)
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/simple_electronic_signature/documents" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Timeline File for Workflow Run
#
# POST /workflow_runs/{workflow_run_id}/timeline_file
# operationId: create_timeline_file
export def "workflow-runs-timeline-file file-by-workflow_run_id" [
  workflow_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<workflow_timeline_file_id: string, href: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/timeline_file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Timeline File for Workflow Run
#
# GET /workflow_runs/{workflow_run_id}/timeline_file/{timeline_file_id}
# operationId: find_timeline_file
export def "workflow-runs-timeline-file file-by-workflow_run_id-timeline_file_id" [
  workflow_run_id: string
  timeline_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/workflow_runs/($workflow_run_id)/timeline_file/($timeline_file_id)")
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete passkeys
#
# DELETE /passkeys/{username}
# operationId: delete_passkeys
export def "passkeys passkeys-by-username" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/passkeys/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List passkeys
#
# GET /passkeys/{username}
# operationId: list_passkeys
export def "passkeys passkeys-by-username-1" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<passkeys: table<id: string, application_domain: string, state: string, created_at: string, last_used_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/passkeys/($username)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete passkey
#
# DELETE /passkeys/{username}/{passkey_id}
# operationId: delete_passkey
export def "passkeys passkey-by-username-passkey_id" [
  username: string
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/passkeys/($username)/($passkey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve passkey
#
# GET /passkeys/{username}/{passkey_id}
# operationId: find_passkey
export def "passkeys passkey-by-username-passkey_id-1" [
  username: string
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, application_domain: string, state: string, created_at: string, last_used_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/passkeys/($username)/($passkey_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update passkey
#
# PUT /passkeys/{username}/{passkey_id}
# operationId: update_passkey
export def "passkeys passkey-by-username-passkey_id-2" [
  username: string
  passkey_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  state: string@state-completer # Desired passkey state value.
]: any -> record<id: string, application_domain: string, state: string, created_at: string, last_used_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/passkeys/($username)/($passkey_id)")
  let body = {state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Ping
#
# GET /ping
# operationId: ping
export def "ping ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-3 # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhooks
#
# GET /webhooks
# operationId: list_webhooks
export def "webhooks webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhooks: table<enabled: bool, events: list, environments: list, payload_version: int, oauth_enabled: bool, oauth_server_url: string, oauth_server_client_id: string, oauth_server_client_secret: string, oauth_server_scope: string, id: string, name: string, url: string, token: string, href: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register webhook
#
# POST /webhooks
# operationId: create_webhook
export def "webhooks webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Determine if the webhook is active.
  --events: list # The events that will be published to the webhook. If the events parameter is omitted all the events will be subscribed.
  --environments: list # The environments from which the webhook will receive events. Allowed values are “sandbox” and “live”. If the environments parameter is omitted the webhook will receive events from both environments.
  --payload-version: int # Webhook version used to control the payload object when sending webhooks.
  --oauth-enabled: oneof<nothing, bool> # Determines if the webhook will fetch OAuth access tokens to send in the Authorization header.
  --oauth-server-url: string # The url to fetch the OAuth access token using client credentials grant.
  --oauth-server-client-id: string # The client id to authenticate the client credentials grant.
  --oauth-server-client-secret: string # The client secret to authenticate the client credentials grant.
  --oauth-server-scope: string # The scopes to be sent when requesting the access token.
  --name: string # Name of the webhook.
  --body-url: string # The url that will listen to notifications (must be https).
]: any -> record<enabled: bool, events: list<string>, environments: list<string>, payload_version: int, oauth_enabled: bool, oauth_server_url: string, oauth_server_client_id: string, oauth_server_client_secret: string, oauth_server_scope: string, id: string, name: string, url: string, token: string, href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {enabled: $enabled, events: $events, environments: $environments, payload_version: $payload_version, oauth_enabled: $oauth_enabled, oauth_server_url: $oauth_server_url, oauth_server_client_id: $oauth_server_client_id, oauth_server_client_secret: $oauth_server_client_secret, oauth_server_scope: $oauth_server_scope, name: $name, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /webhooks/{webhook_id}
# operationId: delete_webhook
export def "webhooks webhook-by-webhook_id" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Webhook
#
# GET /webhooks/{webhook_id}
# operationId: find_webhook
export def "webhooks webhook-by-webhook_id-1" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, events: list<string>, environments: list<string>, payload_version: int, oauth_enabled: bool, oauth_server_url: string, oauth_server_client_id: string, oauth_server_client_secret: string, oauth_server_scope: string, id: string, name: string, url: string, token: string, href: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit a webhook
#
# PUT /webhooks/{webhook_id}
# operationId: update_webhook
export def "webhooks webhook-by-webhook_id-2" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Determine if the webhook is active.
  --events: list # The events that will be published to the webhook. If the events parameter is omitted all the events will be subscribed.
  --environments: list # The environments from which the webhook will receive events. Allowed values are “sandbox” and “live”. If the environments parameter is omitted the webhook will receive events from both environments.
  --payload-version: int # Webhook version used to control the payload object when sending webhooks.
  --oauth-enabled: oneof<nothing, bool> # Determines if the webhook will fetch OAuth access tokens to send in the Authorization header.
  --oauth-server-url: string # The url to fetch the OAuth access token using client credentials grant.
  --oauth-server-client-id: string # The client id to authenticate the client credentials grant.
  --oauth-server-client-secret: string # The client secret to authenticate the client credentials grant.
  --oauth-server-scope: string # The scopes to be sent when requesting the access token.
  --name: string # Name of the webhook.
  --body-url: string # The url that will listen to notifications (must be https).
]: any -> record<enabled: bool, events: list<string>, environments: list<string>, payload_version: int, oauth_enabled: bool, oauth_server_url: string, oauth_server_client_id: string, oauth_server_client_secret: string, oauth_server_scope: string, id: string, name: string, url: string, token: string, href: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let body = {enabled: $enabled, events: $events, environments: $environments, payload_version: $payload_version, oauth_enabled: $oauth_enabled, oauth_server_url: $oauth_server_url, oauth_server_client_id: $oauth_server_client_id, oauth_server_client_secret: $oauth_server_client_secret, oauth_server_scope: $oauth_server_scope, name: $name, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resends webhooks
#
# POST /webhooks/resend
# operationId: resend_webhooks
# --data item shape: {resource_id: string, event: string}
export def "webhooks-resend webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: list # item shape: {resource_id: string, event: string}
]: any -> record<error: record<type: string, message: string, fields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/resend")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Address Picker
#
# GET /addresses/pick
# operationId: find_addresses
export def "addresses-pick addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --postcode: string
]: nothing -> record<addresses: table<flat_number: string, building_number: string, building_name: string, street: string, sub_street: string, town: string, postcode: string, country: string, state: string, line1: string, line2: string, line3: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "postcode" $postcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addresses/pick" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a SDK token
#
# POST /sdk_token
# operationId: generate_sdk_token
export def "sdk-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicant_id: string # The unique identifier of the applicant (format: uuid)
  --referrer: string # The referrer URL pattern
  --application-id: string # The application ID (iOS or Android)
  --cross-device-url: string # The URL to be used by the Web SDK for the cross device flow.
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sdk_token")
  let body = {applicant_id: $applicant_id, referrer: $referrer, application_id: $application_id, cross_device_url: $cross_device_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve repeat attempts
#
# GET /repeat_attempts/{report_id}
# operationId: list_repeat_attempts
export def "repeat-attempts attempts" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<report_id: string, repeat_attempts: table<report_id: string, applicant_id: string, date_of_birth: string, names: string, result: string, created_at: string, completed_at: string>, attempts_count: int, attempts_clear_rate: float, unique_mismatches_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/repeat_attempts/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Autofill
#
# POST /extractions
# operationId: extract
export def "extractions extract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  document_id: string # The unique identifier of the uploaded document to run extraction on (format: uuid)
]: any -> record<document_id: string, document_classification: record<issuing_country: string, document_type: string, issuing_state: string, subtype: string, version: string>, extracted_data: record<document_number: string, first_name: string, last_name: string, full_name: string, spouse_name: string, widow_name: string, alias_name: string, gender: string, date_of_birth: string, date_of_expiry: string, expiry_date: string, nationality: string, mrz_line_1: string, mrz_line_2: string, mrz_line_3: string, address_1: string, address_2: string, address_3: string, address_4: string, address_5: string, issuing_authority: string, issuing_country: string, document_type: string, place_of_birth: string, issuing_state: string, issuing_date: string, personal_number: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/extractions")
  let body = {document_id: $document_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fraud reporting (ALPHA)
#
# POST /results_feedback
# operationId: post_results_feedback
export def "results-feedback feedback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expected-result: string@expected-result-completer # The expected result for the check or report.
  --check-id: string # The ID of the check (only if report_id is not provided). (format: uuid)
  --report-id: string # The ID of the check (only if check_id is not provided). (format: uuid)
  --feedback-notes: string # Any additional information or feedback.
]: any -> record<expected_result: string, check_id: string, report_id: string, feedback_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/results_feedback")
  let body = {expected_result: $expected_result, check_id: $check_id, report_id: $report_id, feedback_notes: $feedback_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Checks
#
# GET /checks
# operationId: list_checks
export def "checks checks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicant-id: string # format: uuid
]: nothing -> record<checks: table<webhook_ids: list, applicant_id: string, applicant_provides_data: bool, tags: list, redirect_uri: string, privacy_notices_read_consent_given: bool, id: string, created_at: string, href: string, status: string, result: string, form_uri: string, results_uri: string, report_ids: list, sandbox: bool, paused: bool, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicant_id" $applicant_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a check
#
# POST /checks
# operationId: create_check
# --report_configuration shape: {facial_similarity_photo?: record, facial_similarity_photo_fully_auto?: record, facial_similarity_video?: record, facial_similarity_motion?: record}
@deprecated --flag report-configuration
export def "checks check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook-ids: list # An array of webhook ids describing which webhooks to trigger for this check.
  applicant_id: string # The ID of the applicant to do the check on. (format: uuid)
  --applicant-provides-data: oneof<nothing, bool> # Send an applicant form to applicant to complete to proceed with check. Defaults to false. (default: false)
  --tags: list # Array of tags being assigned to this check.
  --redirect-uri: string # For checks where `applicant_provides_data` is `true`, redirect to this URI when the applicant has submitted their data.
  --privacy-notices-read-consent-given: oneof<nothing, bool>
  report_names: list # An array of report names (strings).
  --document-ids: list # Optional. An array of document ids, for use with Document reports only. If omitted, the Document report will use the most recently uploaded document by default.
  --asynchronous: oneof<nothing, bool> # Defaults to `true`. If set to `false`, you will only receive a response when all reports in your check have completed.  (default: true)
  --suppress-form-emails: oneof<nothing, bool> # For checks where `applicant_provides_data` is `true`, applicant form will not be automatically sent if `suppress_form_emails` is set to `true`. You can manually send the form at any time after the check has been created, using the link found in the form_uri attribute of the check object. Write-only. Defaults to false.
  --sub-result: string # Triggers responses for particular sub-results for sandbox Document reports.
  --consider: list # Array of names of particular reports to return consider as their results. This is a feature available in sandbox testing
  --us-driving-licence: any
  --report-configuration: record # Defines configuration options for facial similarity checks used to distinguish between onboarding and reverification scenarios.  (DEPRECATED) — shape: {facial_similarity_photo?: record, facial_similarity_photo_fully_auto?: record, facial_similarity_video?: record, facial_similarity_motion?: record}
]: any -> record<webhook_ids: list<string>, applicant_id: string, applicant_provides_data: bool, tags: list<string>, redirect_uri: string, privacy_notices_read_consent_given: bool, id: string, created_at: string, href: string, status: string, result: string, form_uri: string, results_uri: string, report_ids: list<string>, sandbox: bool, paused: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checks")
  let body = {webhook_ids: $webhook_ids, applicant_id: $applicant_id, applicant_provides_data: $applicant_provides_data, tags: $tags, redirect_uri: $redirect_uri, privacy_notices_read_consent_given: $privacy_notices_read_consent_given, report_names: $report_names, document_ids: $document_ids, asynchronous: $asynchronous, suppress_form_emails: $suppress_form_emails, sub_result: $sub_result, consider: $consider, us_driving_licence: $us_driving_licence, report_configuration: $report_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Check
#
# GET /checks/{check_id}
# operationId: find_check
export def "checks check-by-check_id" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook_ids: list<string>, applicant_id: string, applicant_provides_data: bool, tags: list<string>, redirect_uri: string, privacy_notices_read_consent_given: bool, id: string, created_at: string, href: string, status: string, result: string, form_uri: string, results_uri: string, report_ids: list<string>, sandbox: bool, paused: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($check_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume a Check
#
# POST /checks/{check_id}/resume
# operationId: resume_check
export def "checks-resume check" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($check_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download check
#
# GET /checks/{check_id}/download
# operationId: download_check
export def "checks-download check" [
  check_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checks/($check_id)/download")
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List reports
#
# GET /reports
# operationId: list_reports
export def "reports reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --check-id: string # format: uuid
]: nothing -> record<reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "check_id" $check_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve report
#
# GET /reports/{report_id}
# Discriminator (response): name = document, document_video, document_video_with_address_information, document_with_address_information, document_with_driving_licence_information, document_with_driver_verification, facial_similarity_photo, facial_similarity_photo_fully_auto, facial_similarity_video, facial_similarity_motion, known_faces, identity_enhanced, watchlist_aml, watchlist_enhanced, watchlist_standard, watchlist_peps_only, watchlist_sanctions_only, proof_of_address, us_driving_licence, device_intelligence, india_pan
# operationId: find_report
export def "reports report" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume report
#
# POST /reports/{report_id}/resume
# operationId: resume_report
export def "reports-resume report" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/($report_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel report
#
# POST /reports/{report_id}/cancel
# operationId: cancel_report
export def "reports-cancel report" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<type: string, message: string, fields: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/($report_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
