# Auto-generated client for Noosh API application v1.0
# Source: https://api.apis.guru/v2/specs/noosh.com/1.0/openapi.json
# Auth: --token flag or $env.NOOSH_API_APPLICATION_TOKEN

const BASE_URL = "http://example.com:80/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOOSH_API_APPLICATION_TOKEN | default "" }
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

def base-url-completer [] { ["http://example.com:80/v1"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json" "application/x-json-smile" "application/x-yaml" "application/xml" "text/csv" "text/x-yaml" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "11-workgroups-projects-file-tags get" } } | get name | first)
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

# List Tags from Workgroup and Project.
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/fileTags
# operationId: getFileTags
export def "11-workgroups-projects-file-tags get" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<isSpec: bool, tagId: int, tagName: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/fileTags"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Files from Project.  Works for Regular and Remote Files
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/files
# operationId: getFiles
export def "11-workgroups-projects-files list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/files"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload File to Project.  A multipart/form-data request with a name "file"
#
# POST /1.1/workgroups/{workgroup_id}/projects/{project_id}/files
# operationId: uploadFile
export def "11-workgroups-projects-files upload" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/files"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get File from Project.  Works for Regular and Remote Files
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/files/{file_id}
# operationId: getFile
export def "11-workgroups-projects-files get" [
  workgroup_id: string
  project_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list<record>, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, file_id: $file_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/files/{file_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a specific spec of project Level
#
# GET /1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# operationId: getSpec
export def "11-workgroups-projects-specs get" [
  workgroup_id: string
  project_id: string
  spec_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<client_status: string, create_date: string, created_by: record<email: string, first_name: string, last_name: string, middle_name: string>, first_level_custom_fields: record<property_attributes: list, property_id: int, property_name: string>, header_custom_fields: record<property_attributes: list, property_id: int, property_name: string>, job_id: int, last_updated: string, product_type: string, product_type_info: record<label: string, product_type_id: int>, quantity_1: int, quantity_2: int, quantity_3: int, quantity_4: int, quantity_5: int, reference_number: string, second_level_custom_fields: list<record>, sku: string, spec_id: int, spec_name: string, spec_options: list<record>, spec_options_complete: list<record>, spec_original: record<spec_id: int, spec_name: string>, spec_type: record<spec_type_id: int, spec_type_name: string>, supplier_status: string, uofms: list<record>, user_state: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Spec
#
# PUT /1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# operationId: putSpec
# --first_level_custom_fields shape: {property_attributes?: list, property_id?: int, property_name?: string}
# --header_custom_fields shape: {property_attributes?: list, property_id?: int, property_name?: string}
# --second_level_custom_fields item shape: {property_attributes?: list, property_id?: int, property_name?: string}
# --versions item shape: {description?: string, qty?: int}
export def "11-workgroups-projects-specs update" [
  workgroup_id: string
  project_id: string
  spec_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --first-level-custom-fields: any # Java type: com.noosh.domain.nooshapi.persist.po.v1x1.V1x1ProperyPO — shape: {property_attributes?: list, property_id?: int, property_name?: string}
  --header-custom-fields: any # Java type: com.noosh.domain.nooshapi.persist.po.v1x1.V1x1ProperyPO — shape: {property_attributes?: list, property_id?: int, property_name?: string}
  --product-type-id: int # format: int64, e.g. 1
  --quantity-1: int # format: int64, e.g. 1
  --quantity-2: int # format: int64, e.g. 1
  --quantity-3: int # format: int64, e.g. 1
  --quantity-4: int # format: int64, e.g. 1
  --quantity-5: int # format: int64, e.g. 1
  --second-level-custom-fields: list # item shape: {property_attributes?: list, property_id?: int, property_name?: string}
  --sku: string # e.g. sample sku
  --spec-name: string # e.g. sample spec_name
  --spec-type-id: int # format: int64, e.g. 1
  --versions: list # item shape: {description?: string, qty?: int}
]: any -> record<spec_id: int, spec_name: string, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"))
  let body = {"first_level_custom_fields": $first_level_custom_fields, "header_custom_fields": $header_custom_fields, "product_type_id": $product_type_id, "quantity_1": $quantity_1, "quantity_2": $quantity_2, "quantity_3": $quantity_3, "quantity_4": $quantity_4, "quantity_5": $quantity_5, "second_level_custom_fields": $second_level_custom_fields, "sku": $sku, "spec_name": $spec_name, "spec_type_id": $spec_type_id, "versions": $versions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invite a team member or all the members of team template for the specific project.
#
# POST /1.1/workgroups/{workgroup_id}/projects/{project_id}/teammembers
# operationId: postTeamMemberOfProject
export def "11-workgroups-projects-teammembers create-team-member-of" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --role-id: int # format: int64, e.g. 1
  --team-template-id: int # format: int64, e.g. 1
  --user-id: int # format: int64, e.g. 1
]: any -> record<results: table<role: record, team_member_id: int, user: record, was_invited_before: bool>, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/1.1/workgroups/{workgroup_id}/projects/{project_id}/teammembers"))
  let body = {"role_id": $role_id, "team_template_id": $team_template_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Spec Type Fields
#
# GET /1.1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields
# operationId: getSpecTypeFields
export def "11-workgroups-spec-types-spec-type-fields get" [
  workgroup_id: string
  spec_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: any, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, spec_type_id: $spec_type_id} | format pattern "/1.1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all countries
#
# GET /v1/countries
# operationId: getCountryList
export def "countries get-country-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<constant_token: string, country: string, country_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/countries")
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the workgroups
#
# GET /v1/workgroups
# operationId: getWorkgroupList
export def "workgroups get-workgroup-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --workgroup-name: string # Workgroup Name
  --workgroup-types: list # 1000001 for Buyer, 1000002 for supplier, 1000003 for agent, 1000004 for Broker/Outsourcer and 1000005 for Partner
]: nothing -> record<results: table<is_default: bool, parent_workgroup: record, workgroup_id: int, workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workgroup_name" $workgroup_name "scalar") (serialize-qp "workgroup_types" $workgroup_types "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workgroups" $qp)
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List current user's automatic invitations info 
#
# GET /v1/workgroups/{workgroup_id}/automaticInvitations
# operationId: getAutomaticInvitationList
export def "workgroups-automatic-invitations get-automatic-invitation-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<automatic_invitation_type_name: string, team_template: record>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/automaticInvitations"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Billing Recipients
#
# GET /v1/workgroups/{workgroup_id}/billingRecipients
# operationId: getBillingRecipients
export def "workgroups-billing-recipients get" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<address: string, company_name: string, email: string, first_name: string, last_name: string, primary_phone: string, user_id: int, workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/billingRecipients"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the buy orders of workgroup
#
# GET /v1/workgroups/{workgroup_id}/buyOrders
# operationId: getBuyOrderListOfWorkgroup
export def "workgroups-buy-orders get-buy-order-list-of" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, project: record, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/buyOrders"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific buy order of workgroup
#
# GET /v1/workgroups/{workgroup_id}/buyOrders/{order_id}
# operationId: getBuyOrderOfWorkgroup
export def "workgroups-buy-orders get-buy-order-of" [
  workgroup_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: list<record>, classification: string, closed_date: string, closing_change_orders: list<record>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list<record>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: list<record>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/buyOrders/{order_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List client workgroups
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups
# operationId: getClientWorkgroupList
export def "workgroups-client-workgroups get-client-workgroup-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<client_ac_workgroup_id: int, client_workgroup_id: int, client_workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/clientWorkgroups"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific client workgroups
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}
# operationId: getSpecificClientWorkgroup
export def "workgroups-client-workgroups get-specific" [
  workgroup_id: string
  client_workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<client_ac_workgroup_id: int, client_workgroup_id: int, client_workgroup_name: string, custom_fields: list<record>, margin_percent: any, markup: any, markup_percent: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the project categories of client side
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectCategory
# operationId: getProjectCategoryListOfClient
export def "workgroups-client-workgroups-project-category get-project-category-list-of" [
  workgroup_id: string
  client_workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<project_category_id: int, project_category_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectCategory"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projec home user fields of client workgroup
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectHomeUserFields
# operationId: getProjectHomeUserFieldListOfClient
export def "workgroups-client-workgroups-project-home-user-fields get-project-home-user-field-list-of" [
  workgroup_id: string
  client_workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<is_required: bool, label: string, ordinal_number: int, param_name: string, type: string, user_field_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectHomeUserFields"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the project status of client
#
# GET /v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectStatus
# operationId: getProjectStatusOfClient
export def "workgroups-client-workgroups-project-status get-project-status-of" [
  workgroup_id: string
  client_workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<project_status_id: int, project_status_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, client_workgroup_id: $client_workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/clientWorkgroups/{client_workgroup_id}/projectStatus"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the contacts
#
# GET /v1/workgroups/{workgroup_id}/contacts
# operationId: getContactList
export def "workgroups-contacts get-contact-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<address: string, company_name: string, email: string, first_name: string, last_name: string, primary_phone: string, user_id: int, workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/contacts"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Contact Info
#
# GET /v1/workgroups/{workgroup_id}/contacts/{user_id}
# operationId: getContactUserInfo
export def "workgroups-contacts get-contact-user-info" [
  workgroup_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<address: any, company_name: string, email: string, fax_number: string, first_name: string, last_name: string, locale: string, middle_name: string, organization: string, phone_number: string, time_zone: string, title: string, user_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, user_id: $user_id} | format pattern "/v1/workgroups/{workgroup_id}/contacts/{user_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom task status of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/customTaskStatus
# operationId: getWgTaskStatusListOfWorkgroup
export def "workgroups-custom-task-status get-wg-task-status-list-of" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<description: string, is_active: bool, is_default: bool, task_status_name: string, tasks_status_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/customTaskStatus"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom task types of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/customTaskTypes
# operationId: getCustomTaskTypesOfWg
export def "workgroups-custom-task-types get-custom-task-types-of-wg" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<task_type: string, task_type_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/customTaskTypes"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all deactivation reasons
#
# GET /v1/workgroups/{workgroup_id}/deactivationReasons
# operationId: getDeactivationReasonList
export def "workgroups-deactivation-reasons get-deactivation-reason-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<deactivation_reason_id: int, deactivation_reason_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/deactivationReasons"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default task priority list
#
# GET /v1/workgroups/{workgroup_id}/defaultTaskPriority
# operationId: TaskPriorityList
export def "workgroups-default-task-priority list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<task_priority_id: int, task_priority_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/defaultTaskPriority"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default task status list
#
# GET /v1/workgroups/{workgroup_id}/defaultTaskStatus
# operationId: getDefaultTaskStatusList
export def "workgroups-default-task-status get-default-task-status-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<task_status_id: int, task_status_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/defaultTaskStatus"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Detail workgroup info
#
# GET /v1/workgroups/{workgroup_id}/detail
# operationId: getWorkgroupDetail
export def "workgroups-detail get" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<address_line1: string, address_line2: string, address_line3: string, city: string, country: string, country_code: string, custom_fields: list<record>, default_currency: string, portal: string, postal: string, state: string, workgroup_id: int, workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/detail"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Workgroup
#
# PUT /v1/workgroups/{workgroup_id}/detail
# operationId: putWorkgroup
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-detail update" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address-line1: string # e.g. sample address_line1
  --address-line2: string # e.g. sample address_line2
  --address-line3: string # e.g. sample address_line3
  --city: string # e.g. sample city
  --country: string # e.g. sample country
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --decimal-places: int # format: int64, e.g. 1
  --postal: string # e.g. sample postal
  --state: string # e.g. sample state
  --workgroup-name: string # e.g. sample workgroup_name
]: any -> record<status_code: int, status_reason: string, workgroup_id: int, workgroup_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/detail"))
  let body = {"address_line1": $address_line1, "address_line2": $address_line2, "address_line3": $address_line3, "city": $city, "country": $country, "custom_fields": $custom_fields, "decimal_places": $decimal_places, "postal": $postal, "state": $state, "workgroup_name": $workgroup_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Exchange Rate List
#
# GET /v1/workgroups/{workgroup_id}/exchangeRate
# operationId: getExchangeRateList
export def "workgroups-exchange-rate get-exchange-rate-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/exchangeRate"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Exchange Rates
#
# POST /v1/workgroups/{workgroup_id}/exchangeRate
# operationId: postExchangeRate
# --exchange_rates item shape: {activate_date?: string, buClientWorkgroupId?: int, currency?: string, rate?: any, target?: string}
export def "workgroups-exchange-rate create" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --exchange-rates: list # item shape: {activate_date?: string, buClientWorkgroupId?: int, currency?: string, rate?: any, target?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/exchangeRate"))
  let body = {"exchange_rates": $exchange_rates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List my time cards
#
# GET /v1/workgroups/{workgroup_id}/myTimeCards
# operationId: getMyTimeCardList
export def "workgroups-my-time-cards get-my-time-card-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<is_submit: bool, last_updated_date: string, no_of_workdays: int, submit_date: string, timecard_id: int, total_hours: any, week_beginning: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/myTimeCards"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific my time cards
#
# GET /v1/workgroups/{workgroup_id}/myTimeCards/{timeCard_id}
# operationId: getMyTimeCard
export def "workgroups-my-time-cards get" [
  workgroup_id: string
  time_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billable_hours: any, is_submit: bool, last_updated_date: string, no_of_workdays: int, nonbillable_hours: any, submit_date: string, time_card_line: table<activity_name: string, day1_hours_spent: any, day2_hours_spent: any, day3_hours_spent: any, day4_hours_spent: any, day5_hours_spent: any, day6_hours_spent: any, day7_hours_spent: any, project: record, task: record, time_card_line_id: int, total_hours_spent: any>, timecard_id: int, total_hours: any, week_beginning: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, time_card_id: $time_card_id} | format pattern "/v1/workgroups/{workgroup_id}/myTimeCards/{time_card_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product type of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/productTypes
# operationId: getProductTypeListOfWorkgroup
export def "workgroups-product-types get-product-type-list-of" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<is_checked: bool, label: string, product_type_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/productTypes"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product type of spec level by workgroupId
#
# GET /v1/workgroups/{workgroup_id}/productTypesOfSpecTypes
# operationId: getSpecProductTypeListOfWorkgroup
export def "workgroups-product-types-of-spec-types get-spec-product-type-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<is_checked: bool, label: string, product_type_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/productTypesOfSpecTypes"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register product types for spec types
#
# POST /v1/workgroups/{workgroup_id}/productTypesOfSpecTypes
# operationId: postSpecProductTypeListOfWorkgroup
# --spec_prdType_list item shape: {prdType_labels?: list, spec_type_id?: int}
export def "workgroups-product-types-of-spec-types create-spec-product-type-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --enable-differentiate-prd-type-preference: oneof<nothing, bool> # e.g. false
  --spec-prd-type-list: list # item shape: {prdType_labels?: list, spec_type_id?: int}
]: any -> record<enableDifferentiatePrdTypePreference: bool, spec_prdType_list: table<prdType_labels: list, spec_type_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/productTypesOfSpecTypes"))
  let body = {"enableDifferentiatePrdTypePreference": $enable_differentiate_prd_type_preference, "spec_prdType_list": $spec_prd_type_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload Profile Image.  A multipart/form-data request with a name "file"
#
# POST /v1/workgroups/{workgroup_id}/profileImage
# operationId: uploadProfileImage
export def "workgroups-profile-image upload" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> record<profileImgUrl: string, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/profileImage"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the project categories
#
# GET /v1/workgroups/{workgroup_id}/projectCategory
# operationId: getProjectCategoryList
export def "workgroups-project-category get-project-category-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<project_category_id: int, project_category_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/projectCategory"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projec home user fields
#
# GET /v1/workgroups/{workgroup_id}/projectHomeUserFields
# operationId: getProjectHomeUserFieldsList
export def "workgroups-project-home-user-fields get-project-home-user-fields-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<is_required: bool, label: string, ordinal_number: int, param_name: string, type: string, user_field_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/projectHomeUserFields"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the project status
#
# GET /v1/workgroups/{workgroup_id}/projectStatus
# operationId: getProjectStatus
export def "workgroups-project-status get" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<project_status_id: int, project_status_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/projectStatus"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the projects
#
# GET /v1/workgroups/{workgroup_id}/projects
# operationId: getProjectList
export def "workgroups-projects get-project-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<client_account: string, client_workgroup_id: int, completion_date: string, is_active: bool, is_hot: bool, last_spec_update: string, project_id: int, project_name: string, project_number: string, project_status: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/projects"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Project
#
# POST /v1/workgroups/{workgroup_id}/projects
# operationId: postProject
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-projects create" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-account: string # e.g. sample client_account
  --client-user-id: int # format: int64, e.g. 1
  --client-workgroup-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --completion-date: string # format: date
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --deactivation-reason-id: int # format: int64, e.g. 1
  --is-active: oneof<nothing, bool> # e.g. false
  --is-hot: oneof<nothing, bool> # e.g. false
  --is-paper-direct: oneof<nothing, bool> # e.g. false
  --project-category-id: int # format: int64, e.g. 1
  --project-description: string # e.g. sample project_description
  --project-name: string # e.g. sample project_name
  --project-number: string # e.g. sample project_number
  --project-owner-user-id: int # format: int64, e.g. 1
  project_status_id: int # format: int64, e.g. 1
]: any -> record<project_id: int, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/projects"))
  let body = {"client_account": $client_account, "client_user_id": $client_user_id, "client_workgroup_id": $client_workgroup_id, "comments": $comments, "completion_date": $completion_date, "custom_fields": $custom_fields, "deactivation_reason_id": $deactivation_reason_id, "is_active": $is_active, "is_hot": $is_hot, "is_paper_direct": $is_paper_direct, "project_category_id": $project_category_id, "project_description": $project_description, "project_name": $project_name, "project_number": $project_number, "project_owner_user_id": $project_owner_user_id, "project_status_id": $project_status_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Archieve a specific Project
#
# DELETE /v1/workgroups/{workgroup_id}/projects/{project_id}
# operationId: deleteProject
export def "workgroups-projects delete" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}
# operationId: getProject
export def "workgroups-projects get" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<category: string, client_account: string, client_user: string, client_user_id: int, client_workgroup_id: int, comments: string, completion_date: string, custom_fields: list<record>, deactivation_reason: string, is_active: bool, is_hot: bool, last_spec_update: string, mod_date: string, owner_workgroup: string, parent_project: record<client_account: string, client_user: string, client_user_id: int, client_workgroup_id: int, comments: string, created_by: record, project_create_date: string, project_description: string, project_id: int, project_name: string, project_number: string>, project_create_date: string, project_description: string, project_id: int, project_name: string, project_number: string, project_status: string, team_owners: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch a specific Project
#
# PATCH /v1/workgroups/{workgroup_id}/projects/{project_id}
# operationId: patchProject
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-projects update-by-workgroup_id-project_id" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-user-id: int # format: int64, e.g. 1
  --client-workgroup-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --completion-date: string # format: date
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --deactivation-reason-id: int # format: int64, e.g. 1
  --is-active: oneof<nothing, bool> # e.g. false
  --is-hot: oneof<nothing, bool> # e.g. false
  --project-category-id: int # format: int64, e.g. 1
  --project-description: string # e.g. sample project_description
  --project-name: string # e.g. sample project_name
  --project-number: string # e.g. sample project_number
  --project-status-id: int # format: int64, e.g. 1
]: any -> record<status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}"))
  let body = {"client_user_id": $client_user_id, "client_workgroup_id": $client_workgroup_id, "comments": $comments, "completion_date": $completion_date, "custom_fields": $custom_fields, "deactivation_reason_id": $deactivation_reason_id, "is_active": $is_active, "is_hot": $is_hot, "project_category_id": $project_category_id, "project_description": $project_description, "project_name": $project_name, "project_number": $project_number, "project_status_id": $project_status_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a specific Project
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}
# operationId: putProject
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-projects update-by-workgroup_id-project_id-1" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-account: string # e.g. sample client_account
  --client-user-id: int # format: int64, e.g. 1
  --client-workgroup-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --completion-date: string # format: date
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --deactivation-reason-id: int # format: int64, e.g. 1
  --is-active: oneof<nothing, bool> # e.g. false
  --is-hot: oneof<nothing, bool> # e.g. false
  --is-paper-direct: oneof<nothing, bool> # e.g. false
  --project-category-id: int # format: int64, e.g. 1
  --project-description: string # e.g. sample project_description
  --project-name: string # e.g. sample project_name
  --project-number: string # e.g. sample project_number
  --project-owner-user-id: int # format: int64, e.g. 1
  project_status_id: int # format: int64, e.g. 1
]: any -> record<status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}"))
  let body = {"client_account": $client_account, "client_user_id": $client_user_id, "client_workgroup_id": $client_workgroup_id, "comments": $comments, "completion_date": $completion_date, "custom_fields": $custom_fields, "deactivation_reason_id": $deactivation_reason_id, "is_active": $is_active, "is_hot": $is_hot, "is_paper_direct": $is_paper_direct, "project_category_id": $project_category_id, "project_description": $project_description, "project_name": $project_name, "project_number": $project_number, "project_owner_user_id": $project_owner_user_id, "project_status_id": $project_status_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the buy orders
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders
# operationId: getBuyOrderList
export def "workgroups-projects-buy-orders get-buy-order-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a quick buy order
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders
# operationId: postBuyOrder
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
# --order_items item shape: {completion_date?: string, custom_fields?: list, ex_tax_value_calculated?: any, notes?: string, per?: int, price?: any, quantity?: any, shipping?: any, spec_id?: int, spec_reference_id?: int, tax?: string}
export def "workgroups-projects-buy-orders create" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --buyer-user-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --invoice-or-billing-recipient: int # format: int64, e.g. 1
  --order-completion-date: string # format: date
  --order-items: list # item shape: {completion_date?: string, custom_fields?: list, ex_tax_value_calculated?: any, notes?: string, per?: int, price?: any, quantity?: any, shipping?: any, spec_id?: int, spec_reference_id?: int, tax?: string}
  --other-selection-reason: string # e.g. sample other_selection_reason
  --payment-method-id: int # format: int64, e.g. 1
  --payment-reference-no: string # e.g. sample payment_reference_no
  --sell-order: oneof<nothing, bool> # e.g. false
  --shipping: any # Java type: java.math.BigDecimal
  --supplier-reference: string # e.g. sample supplier_reference
  --supplier-selection-reason-id: int # format: int64, e.g. 1
  --supplier-user-id: int # format: int64, e.g. 1
  --tax: string # e.g. sample tax
  --title: string # e.g. sample title
]: any -> record<buyer_user_id: int, comments: string, custom_fields: table<date_value: string, number_value: any, param_name: string, string_value: string>, invoice_or_billing_recipient: int, order_completion_date: string, order_items: table<completion_date: string, custom_fields: list, ex_tax_value_calculated: any, notes: string, per: int, price: any, quantity: any, shipping: any, spec_id: int, spec_reference_id: int, tax: string>, other_selection_reason: string, payment_method_id: int, payment_reference_no: string, sellOrder: bool, shipping: any, supplier_reference: string, supplier_selection_reason_id: int, supplier_user_id: int, tax: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders"))
  let body = {"buyer_user_id": $buyer_user_id, "comments": $comments, "custom_fields": $custom_fields, "invoice_or_billing_recipient": $invoice_or_billing_recipient, "order_completion_date": $order_completion_date, "order_items": $order_items, "other_selection_reason": $other_selection_reason, "payment_method_id": $payment_method_id, "payment_reference_no": $payment_reference_no, "sellOrder": $sell_order, "shipping": $shipping, "supplier_reference": $supplier_reference, "supplier_selection_reason_id": $supplier_selection_reason_id, "supplier_user_id": $supplier_user_id, "tax": $tax, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific buy order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}
# operationId: getBuyOrder
export def "workgroups-projects-buy-orders get" [
  workgroup_id: string
  project_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific buy order
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}
# operationId: putBuyOrder
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-projects-buy-orders update" [
  workgroup_id: string
  project_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string # accept or reject (e.g. sample action)
  --budget-type-field-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --order-completion-date: string # format: date
  --body-order-id: int # format: int64, e.g. 1
  --other-selection-reason: string # e.g. sample other_selection_reason
  --overs-percent: any # Java type: java.math.BigDecimal
  --payment-method-id: int # format: int64, e.g. 1
  --payment-reference-no: string # e.g. sample payment_reference_no
  --reject-reason: string # e.g. sample reject_reason
  --supplier-selection-reason-id: int # format: int64, e.g. 1
  --unders-percent: any # Java type: java.math.BigDecimal
]: any -> record<order_id: int, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/buyOrders/{order_id}"))
  let body = {"action": $action, "budget_type_field_id": $budget_type_field_id, "comments": $comments, "custom_fields": $custom_fields, "order_completion_date": $order_completion_date, "order_id": $body_order_id, "other_selection_reason": $other_selection_reason, "overs_percent": $overs_percent, "payment_method_id": $payment_method_id, "payment_reference_no": $payment_reference_no, "reject_reason": $reject_reason, "supplier_selection_reason_id": $supplier_selection_reason_id, "unders_percent": $unders_percent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attach children projects to specific Project
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/children
# operationId: attachProject
export def "workgroups-projects-children attach" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --child-project-ids: list
]: any -> record<status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/children"))
  let body = {"childProjectIds": $child_project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the Estimates
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/estimates
# operationId: getEstimateList
export def "workgroups-projects-estimates get-estimate-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<create_date: string, currency: string, estimate_id: int, estimate_title: string, expiration_date: string, project: record, rfe: record, status: string, submit_date: string, supplier_workgroup: record, transactional_currency: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/estimates"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Estimate
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/estimates
# operationId: postEstimate
# --estimate_items item shape: {paper_items?: list, quantity_1_price?: any, quantity_1_shipping?: any, quantity_1_tax?: any, quantity_2_price?: any, quantity_2_shipping?: any, quantity_2_tax?: any, quantity_3_price?: any, quantity_3_shipping?: any, quantity_3_tax?: any, quantity_4_price?: any, quantity_4_shipping?: any, quantity_4_tax?: any, quantity_5_price?: any, quantity_5_shipping?: any, quantity_5_tax?: any, rfe_item_id?: int}
export def "workgroups-projects-estimates create" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comments: string # e.g. sample comments
  --description: string # e.g. sample description
  --estimate-items: list # item shape: {paper_items?: list, quantity_1_price?: any, quantity_1_shipping?: any, quantity_1_tax?: any, quantity_2_price?: any, quantity_2_shipping?: any, quantity_2_tax?: any, quantity_3_price?: any, quantity_3_shipping?: any, quantity_3_tax?: any, quantity_4_price?: any, quantity_4_shipping?: any, quantity_4_tax?: any, quantity_5_price?: any, quantity_5_shipping?: any, quantity_5_tax?: any, rfe_item_id?: int}
  --estimate-title: string # e.g. sample estimate_title
  --expiration-date: string # format: date
  --owner-reference: string # e.g. sample owner_reference
  --rfe-id: int # format: int64, e.g. 1
]: any -> record<comments: string, description: string, estimate_items: table<paper_items: list, quantity_1_price: any, quantity_1_shipping: any, quantity_1_tax: any, quantity_2_price: any, quantity_2_shipping: any, quantity_2_tax: any, quantity_3_price: any, quantity_3_shipping: any, quantity_3_tax: any, quantity_4_price: any, quantity_4_shipping: any, quantity_4_tax: any, quantity_5_price: any, quantity_5_shipping: any, quantity_5_tax: any, rfe_item_id: int>, estimate_title: string, expiration_date: string, owner_reference: string, rfe_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/estimates"))
  let body = {"comments": $comments, "description": $description, "estimate_items": $estimate_items, "estimate_title": $estimate_title, "expiration_date": $expiration_date, "owner_reference": $owner_reference, "rfe_id": $rfe_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific estimate of project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/estimates/{estimate_id}
# operationId: getEstimate
export def "workgroups-projects-estimates get" [
  workgroup_id: string
  project_id: string
  estimate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<comments: string, create_date: string, currency: string, custom_fields: list<record>, description: string, estimate_id: int, estimate_title: string, expiration_date: string, items: list<record>, project: record<project_id: int, project_name: string, project_number: string>, reference_number: string, rfe: record<rfe_due_date: string, rfe_id: int, rfe_title: string, status: string>, status: string, submit_date: string, submitted_by: string, submitted_by_user_id: int, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, transactional_currency: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, estimate_id: $estimate_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/estimates/{estimate_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invoices by a specific order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/orders/{order_id}
# operationId: getInvoices
export def "workgroups-projects-invoices-orders get" [
  workgroup_id: string
  project_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<comments: string, currency: string, custom_fields: list, grand_total: any, invoice_date: string, invoice_due_date: string, invoice_id: int, invoice_number: string, invoice_to: string, is_final: int, is_nonBillable: int, items: list, order_reference: string, order_title: string, payment_method: string, prepared_by: string, project_number: int, reference_number: string, shipping: any, status: string, sub_total: any, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_shipping: any, transactional_sub_total: any, transactional_tax: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/orders/{order_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a specific invoice of project Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}
# operationId: getInvoice
export def "workgroups-projects-invoices get" [
  workgroup_id: string
  project_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<comments: string, currency: string, custom_fields: list<record>, grand_total: any, invoice_date: string, invoice_due_date: string, invoice_id: int, invoice_number: string, invoice_to: string, is_final: int, is_nonBillable: int, items: list<record>, order_reference: string, order_title: string, payment_method: string, prepared_by: string, project_number: int, reference_number: string, shipping: any, status: string, sub_total: any, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_shipping: any, transactional_sub_total: any, transactional_tax: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, invoice_id: $invoice_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List files of invoice Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}/files
# operationId: getInvoiceFiles
export def "workgroups-projects-invoices-files get" [
  workgroup_id: string
  project_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<description: string, download_link: string, file_id: int, file_name: string, file_size: any, file_type: string, is_remote: bool, modified_date: string, tagList: list, upload_date: string, uploaded_by: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, invoice_id: $invoice_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/invoices/{invoice_id}/files"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the role options for the user
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/memberroles/{user_id}
# operationId: getMemberRoles
export def "workgroups-projects-memberroles get" [
  workgroup_id: string
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<role_id: int, role_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, user_id: $user_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/memberroles/{user_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific buy/sell order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/orders/{order_id}
# operationId: getOrder
export def "workgroups-projects-orders get" [
  workgroup_id: string
  project_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, is_sell_order: bool, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/orders/{order_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the quotes
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/quotes
# operationId: getQuoteList
export def "workgroups-projects-quotes get-quote-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --quote-state-id-use-filters-quote-state-id-111111: string # Quote Object State Id, use /workgroups/{workgroup_id}/quoteStates to get correct value
]: nothing -> record<result: table<currency: string, grand_total: any, quote_id: int, quote_title: string, rfq: record, status: string, submit_date: string, transactional_currency: string, transactional_grand_total: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_state_id, use filters={"quote_state_id":111111}" $quote_state_id_use_filters_quote_state_id_111111 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/quotes") $qp)
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific quote of project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}
# operationId: getQuote
export def "workgroups-projects-quotes get" [
  workgroup_id: string
  project_id: string
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<client: string, client_user_id: int, comments: string, creator_user_id: int, currency: string, custom_fields: list<record>, description: string, grand_total: any, is_show_supplier_information: bool, last_update_by_user_id: int, proposed_order_completion_date: string, quote_expiration_date: string, quote_id: int, quote_items: list<record>, quote_items_total: any, quote_title: string, shipping: any, status: string, submit_date: string, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_quote_items_total: any, transactional_shipping: any, transactional_tax: any, vat_code: string, vat_rate: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, quote_id: $quote_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accept / Reject a Quote
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}
# operationId: putQuote
export def "workgroups-projects-quotes update" [
  workgroup_id: string
  project_id: string
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string # e.g. sample action
  --po-number: string # e.g. sample po_number
  --body-quote-id: int # format: int64, e.g. 1
  --state-change-comments: string # e.g. sample state_change_comments
]: any -> record<status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, quote_id: $quote_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/quotes/{quote_id}"))
  let body = {"action": $action, "po_number": $po_number, "quote_id": $body_quote_id, "state_change_comments": $state_change_comments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the RFES
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfes
# operationId: getRfeList
export def "workgroups-projects-rfes get-rfe-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<estimate_due_date: string, rfe_id: int, rfe_items: list, rfe_title: string, supplier_estimates: list>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfes"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a RFE
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/rfes
# operationId: postRfe
# --specs item shape: {quantity_1?: int, quantity_2?: int, quantity_3?: int, quantity_4?: int, quantity_5?: int, spec_id?: int}
export def "workgroups-projects-rfes create" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # e.g. sample description
  --details: string # e.g. sample details
  --estimate-due-date: string # format: date
  --proposed-order-completion-date: string # format: date
  --rfe-number: string # e.g. sample rfe_number
  --rfe-title: string # e.g. sample rfe_title
  --specs: list # item shape: {quantity_1?: int, quantity_2?: int, quantity_3?: int, quantity_4?: int, quantity_5?: int, spec_id?: int}
  --supplier-user-ids: list
]: any -> record<rfq_id: int, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfes"))
  let body = {"description": $description, "details": $details, "estimate_due_date": $estimate_due_date, "proposed_order_completion_date": $proposed_order_completion_date, "rfe_number": $rfe_number, "rfe_title": $rfe_title, "specs": $specs, "supplier_user_ids": $supplier_user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific Rfe
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfes/{rfe_id}
# operationId: getRfe
export def "workgroups-projects-rfes get" [
  workgroup_id: string
  project_id: string
  rfe_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<description: string, details: string, estimate_due_date: string, estimators: list<string>, itemized_tax_and_shipping: int, proposed_order_completion_date: string, reference_number: string, requestor: string, rfe_id: int, rfe_items: list<record>, status: string, submitted_date: string, supplier_estimates: list<record>, title: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, rfe_id: $rfe_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfes/{rfe_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the rfqs
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs
# operationId: getRfqList
export def "workgroups-projects-rfqs get-rfq-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<quotes: list, received_date: string, rfq_id: int, rfq_title: string, status: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Rfq
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs/{rfq_id}
# operationId: getRfq
export def "workgroups-projects-rfqs get" [
  workgroup_id: string
  project_id: string
  rfq_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<comments: string, description: string, proposed_completion_date: string, quote_due_date: string, quotes: list<record>, received_date: string, recipient_name: string, requestor_name: string, rfq_id: int, rfq_items: list<record>, rfq_title: string, status: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, rfq_id: $rfq_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/rfqs/{rfq_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the sell orders
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders
# operationId: getSellOrderList
export def "workgroups-projects-sell-orders get-sell-order-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific sell order
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}
# operationId: getSellOrder
export def "workgroups-projects-sell-orders get" [
  workgroup_id: string
  project_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, classification: string, closed_date: string, closing_change_orders: table<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record, buyer_workgroup: record, classification: string, closed_date: string, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list, grand_total: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: table<date_value: string, number_value: any, param_id: int, param_name: string, property_attribute_id: int, string_value: string>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: table<comments: string, completion_date: string, custom_fields: list, item_id: int, item_price: float, quantity: float, shipping: any, spec: record, tax: any, transactional_item_price: float, transactional_shipping: any, transactional_tax: any, transactional_unit_price: any, unit_description: string, unit_price: any>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update / Accept or Reject a specific sell order
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}
# operationId: putSellOrder
# --custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-projects-sell-orders update" [
  workgroup_id: string
  project_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string # accept or reject (e.g. sample action)
  --budget-type-field-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --order-completion-date: string # format: date
  --body-order-id: int # format: int64, e.g. 1
  --other-selection-reason: string # e.g. sample other_selection_reason
  --overs-percent: any # Java type: java.math.BigDecimal
  --payment-method-id: int # format: int64, e.g. 1
  --payment-reference-no: string # e.g. sample payment_reference_no
  --reject-reason: string # e.g. sample reject_reason
  --supplier-selection-reason-id: int # format: int64, e.g. 1
  --unders-percent: any # Java type: java.math.BigDecimal
]: any -> record<order_id: int, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/sellOrders/{order_id}"))
  let body = {"action": $action, "budget_type_field_id": $budget_type_field_id, "comments": $comments, "custom_fields": $custom_fields, "order_completion_date": $order_completion_date, "order_id": $body_order_id, "other_selection_reason": $other_selection_reason, "overs_percent": $overs_percent, "payment_method_id": $payment_method_id, "payment_reference_no": $payment_reference_no, "reject_reason": $reject_reason, "supplier_selection_reason_id": $supplier_selection_reason_id, "unders_percent": $unders_percent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List shipments of project
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments
# operationId: getShipmentList
export def "workgroups-projects-shipments get-shipment-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a shipment
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments
# operationId: postShipment
# --shipment_custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
# --shipment_request_custom_fields item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
export def "workgroups-projects-shipments create" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --address-line1: string # e.g. sample address_line1
  --address-line2: string # e.g. sample address_line2
  --address-line3: string # e.g. sample address_line3
  --batch-label: string # e.g. sample batch_label
  --city: string # e.g. sample city
  --company-name: string # e.g. sample company_name
  --country-iso-code: string # e.g. sample country_iso_code
  --delivery-date: string # format: date
  --description-or-title: string # e.g. sample description_or_title
  --email: string # e.g. sample email
  --first-name: string # e.g. sample first_name
  --inner-carton-label: string # e.g. sample inner_carton_label
  --last-name: string # e.g. sample last_name
  --middle-name: string # e.g. sample middle_name
  --outer-carton-label: string # e.g. sample outer_carton_label
  --pallet-lablel: string # e.g. sample pallet_lablel
  --poof-type: string # e.g. sample poof_type
  --postal-code: string # e.g. sample postal_code
  --request-type: string # e.g. sample request_type
  --requested-quantity: int # format: int64, e.g. 1
  --shipment-custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --shipment-request-custom-fields: list # item shape: {date_value?: string, number_value?: any, param_name?: string, string_value?: string}
  --shipping-carrier: string # e.g. sample shipping_carrier
  --shipping-instruction: string # e.g. sample shipping_instruction
  --shpping-method: string # e.g. sample shpping_method
  --spec-ids: string # e.g. sample spec_ids
  --state: string # e.g. sample state
  --work-phone-number: string # e.g. sample work_phone_number
  --workgroup-name: string # e.g. sample workgroup_name
]: any -> record<results: table<location_id: int, shipment_id: int, spec_id: int>, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments"))
  let body = {"address_line1": $address_line1, "address_line2": $address_line2, "address_line3": $address_line3, "batch_label": $batch_label, "city": $city, "company_name": $company_name, "country_iso_code": $country_iso_code, "delivery_date": $delivery_date, "description_or_title": $description_or_title, "email": $email, "first_name": $first_name, "inner_carton_label": $inner_carton_label, "last_name": $last_name, "middle_name": $middle_name, "outer_carton_label": $outer_carton_label, "pallet_lablel": $pallet_lablel, "poof_type": $poof_type, "postal_code": $postal_code, "request_type": $request_type, "requested_quantity": $requested_quantity, "shipment_custom_fields": $shipment_custom_fields, "shipment_request_custom_fields": $shipment_request_custom_fields, "shipping_carrier": $shipping_carrier, "shipping_instruction": $shipping_instruction, "shpping_method": $shpping_method, "spec_ids": $spec_ids, "state": $state, "work_phone_number": $work_phone_number, "workgroup_name": $workgroup_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a specific shipment.
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}
# operationId: getShipment
export def "workgroups-projects-shipments get" [
  workgroup_id: string
  project_id: string
  shipment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<locations: list<record>, locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record<job_id: int, reference_number: string, spec_id: int, spec_name: string>>, resut: record<locations: list<record>, locations_count: int, qty_received: int, qty_requested: int, qty_shipped: int, received_date: string, shipment_id: int, shipment_status: string, shipped_date: string, spec: record<job_id: int, reference_number: string, spec_id: int, spec_name: string>>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, shipment_id: $shipment_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific shipment location
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}/locations/{location_id}
# operationId: putShipmentLocation
export def "workgroups-projects-shipments-locations update" [
  workgroup_id: string
  project_id: string
  shipment_id: string
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --due-date: string # format: date
  --qty-received: int # format: int64, e.g. 1
  --qty-requested: int # format: int64, e.g. 1
  --qty-shipped: int # format: int64, e.g. 1
  --received-date: string # format: date
  --shipped-date: string # format: date
  --shipping-cost: any # Java type: java.math.BigDecimal
  --type: string # e.g. sample type
]: any -> record<status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, shipment_id: $shipment_id, location_id: $location_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/shipments/{shipment_id}/locations/{location_id}"))
  let body = {"due_date": $due_date, "qty_received": $qty_received, "qty_requested": $qty_requested, "qty_shipped": $qty_shipped, "received_date": $received_date, "shipped_date": $shipped_date, "shipping_cost": $shipping_cost, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List specs of project Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/specs
# operationId: getSpecList
export def "workgroups-projects-specs get-spec-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<client_status: string, create_date: string, created_by: record, job_id: int, last_updated: string, reference_number: string, spec_id: int, spec_name: string, spec_options_complete: list, supplier_status: string, uofms: list, user_state: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Spec
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/specs
# operationId: postSpec
# --versions item shape: {description?: string, qty?: int}
export def "workgroups-projects-specs create" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --json-body: oneof<nothing, bool> # e.g. false
  --product-type-id: int # format: int64, e.g. 1
  --quantity-1: int # format: int64, e.g. 1
  --quantity-2: int # format: int64, e.g. 1
  --quantity-3: int # format: int64, e.g. 1
  --quantity-4: int # format: int64, e.g. 1
  --quantity-5: int # format: int64, e.g. 1
  --sku: string # e.g. sample sku
  --spec-name: string # e.g. sample spec_name
  --spec-template-id: int # format: int64, e.g. 1
  --spec-type-id: int # format: int64, e.g. 1
  --versions: list # item shape: {description?: string, qty?: int}
]: any -> record<spec_id: int, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs"))
  let body = {"jsonBody": $json_body, "product_type_id": $product_type_id, "quantity_1": $quantity_1, "quantity_2": $quantity_2, "quantity_3": $quantity_3, "quantity_4": $quantity_4, "quantity_5": $quantity_5, "sku": $sku, "spec_name": $spec_name, "spec_template_id": $spec_template_id, "spec_type_id": $spec_type_id, "versions": $versions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List a specific spec of project Level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
export def "workgroups-projects-specs get" [
  workgroup_id: string
  project_id: string
  spec_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<client_status: string, create_date: string, created_by: record, job_id: int, last_updated: string, reference_number: string, spec_id: int, spec_name: string, spec_options_complete: list, supplier_status: string, uofms: list, user_state: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Spec
#
# PUT /v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}
# --inks_and_paper item shape: {custom_fields?: list, paper_id?: int}
export def "workgroups-projects-specs put" [
  workgroup_id: string
  project_id: string
  spec_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --inks-and-paper: list # item shape: {custom_fields?: list, paper_id?: int}
  --product-type-id: int # format: int64, e.g. 1
  --quantity-1: int # format: int64, e.g. 1
  --quantity-2: int # format: int64, e.g. 1
  --quantity-3: int # format: int64, e.g. 1
  --quantity-4: int # format: int64, e.g. 1
  --quantity-5: int # format: int64, e.g. 1
  --sku: string # e.g. sample sku
  --spec-name: string # e.g. sample spec_name
]: any -> record<spec_id: int, spec_name: string, status_code: int, status_reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, spec_id: $spec_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/specs/{spec_id}"))
  let body = {"inks_and_paper": $inks_and_paper, "product_type_id": $product_type_id, "quantity_1": $quantity_1, "quantity_2": $quantity_2, "quantity_3": $quantity_3, "quantity_4": $quantity_4, "quantity_5": $quantity_5, "sku": $sku, "spec_name": $spec_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get task list of project level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/tasks
# operationId: getTaskListOfProject
export def "workgroups-projects-tasks get-task-list-of" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<actual_end: string, actual_hours: any, actual_start: string, assign_to: record, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, current_duration: any, is_milestone: bool, mod_date: string, plan_end: string, plan_start: string, priority: string, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/tasks"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new task
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/tasks
# operationId: postTaskForProject
export def "workgroups-projects-tasks create-task-for" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --actual-duration: float # format: double, e.g. 1.1
  --actual-duration-hour: float # format: double, e.g. 1.1
  --actual-end-date: string # format: date
  --actual-start-date: string # format: date
  --assign-to-user-id: int # format: int64, e.g. 1
  --comments: string # e.g. sample comments
  --contributors: string # e.g. sample contributors
  --custom-status-id: int # format: int64, e.g. 1
  --description: string # e.g. sample description
  --name: string # e.g. sample name
  --percentage-complete: int # format: int64, e.g. 1
  --priority: int # format: int64, e.g. 1
  --revised-duration: float # format: double, e.g. 1.1
  --revised-duration-hour: float # format: double, e.g. 1.1
  --revised-end-date: string # format: date
  --revised-start-date: string # format: date
  --status-id: int # format: int64, e.g. 1
  --task-id: int # format: int64, e.g. 1
  --task-type-id: int # format: int64, e.g. 1
]: any -> record<status_code: int, status_reason: string, task_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/tasks"))
  let body = {"actual_duration": $actual_duration, "actual_duration_hour": $actual_duration_hour, "actual_end_date": $actual_end_date, "actual_start_date": $actual_start_date, "assign_to_user_id": $assign_to_user_id, "comments": $comments, "contributors": $contributors, "custom_status_id": $custom_status_id, "description": $description, "name": $name, "percentage_complete": $percentage_complete, "priority": $priority, "revised_duration": $revised_duration, "revised_duration_hour": $revised_duration_hour, "revised_end_date": $revised_end_date, "revised_start_date": $revised_start_date, "status_id": $status_id, "task_id": $task_id, "task_type_id": $task_type_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a sepcific task of project level
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/tasks/{task_id}
# operationId: getTaskOfProject
export def "workgroups-projects-tasks get-task-of" [
  workgroup_id: string
  project_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<actual_duration: any, actual_end: string, actual_hours: any, actual_start: string, assign_to: record<email: string, first_name: string, last_name: string, middle_name: string>, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, comments: string, create_date: string, creator_workgroup_name: string, current_duration: any, description: string, is_milestone: bool, last_updated_by: record<email: string, first_name: string, last_name: string, middle_name: string>, mod_date: string, percent_complete: int, plan_duration: any, plan_end: string, plan_start: string, priority: string, requested_by: record<email: string, first_name: string, last_name: string, middle_name: string>, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, task_id: $task_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/tasks/{task_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List team member of client project side.
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/teamMembersOfClientProject
# operationId: getTeamMemberListOfClientProject
export def "workgroups-projects-team-members-of-client-project get-team-member-list" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<company_name: string, name: string, phone: string, role: string, teammember_id: int, user_id: int, workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/teamMembersOfClientProject"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List team member of project.
#
# GET /v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers
# operationId: getTeamMemberListOfProject
export def "workgroups-projects-teammembers get-team-member-list-of" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<company_name: string, name: string, phone: string, role: string, teammember_id: int, user_id: int, workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deprecated, please use 1.1 Version
#
# POST /v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers
export def "workgroups-projects-teammembers post" [
  workgroup_id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  role_id: int # format: int64, e.g. 1
  user_id: int # format: int64, e.g. 1
]: any -> record<status_code: int, status_reason: string, teammember_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers"))
  let body = {"role_id": $role_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a team member for the specific project.
#
# DELETE /v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers/{teammember_id}
# operationId: deleteTeamMemberOfProject
export def "workgroups-projects-teammembers delete-team-member-of" [
  workgroup_id: string
  project_id: string
  teammember_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<status_code: int, status_reason: string, teammember_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, project_id: $project_id, teammember_id: $teammember_id} | format pattern "/v1/workgroups/{workgroup_id}/projects/{project_id}/teammembers/{teammember_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the quote states
#
# GET /v1/workgroups/{workgroup_id}/quoteStates
# operationId: getQuoteStateList
export def "workgroups-quote-states get-quote-state-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<object_state_id: int, object_state_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/quoteStates"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the quotes of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/quotes
export def "workgroups-quotes get" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --quote-state-id-use-filters-quote-state-id-111111: string # Quote Object State Id, use /workgroups/{workgroup_id}/quoteStates to get correct value
]: nothing -> record<currency: string, grand_total: any, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, quote_title: string, rfq: record<received_date: string, rfq_id: int, rfq_title: string, status: string>, status: string, submit_date: string, transactional_currency: string, transactional_grand_total: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_state_id, use filters={"quote_state_id":111111}" $quote_state_id_use_filters_quote_state_id_111111 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/quotes") $qp)
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List received time cards
#
# GET /v1/workgroups/{workgroup_id}/receivedTimeCards
# operationId: getReceivedTimeCardList
export def "workgroups-received-time-cards get-received-time-card-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<is_submit: bool, last_updated_date: string, no_of_workdays: int, submit_date: string, timecard_id: int, total_hours: any, week_beginning: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/receivedTimeCards"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a specific received time cards
#
# GET /v1/workgroups/{workgroup_id}/receivedTimeCards/{timeCard_id}
# operationId: getReceivedTimeCard
export def "workgroups-received-time-cards get" [
  workgroup_id: string
  time_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<billable_hours: any, is_submit: bool, last_updated_date: string, no_of_workdays: int, nonbillable_hours: any, owner: record<email: string, first_name: string, last_name: string, middle_name: string>, submit_date: string, time_card_line: table<activity_name: string, day1_hours_spent: any, day2_hours_spent: any, day3_hours_spent: any, day4_hours_spent: any, day5_hours_spent: any, day6_hours_spent: any, day7_hours_spent: any, project: record, task: record, time_card_line_id: int, total_hours_spent: any>, timecard_id: int, total_hours: any, week_beginning: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, time_card_id: $time_card_id} | format pattern "/v1/workgroups/{workgroup_id}/receivedTimeCards/{time_card_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the sell orders of workgrop
#
# GET /v1/workgroups/{workgroup_id}/sellOrders
# operationId: getSellOrderListOfWorkgroup
export def "workgroups-sell-orders get-sell-order-list-of" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<buyer_workgroup: record, change_orders: list, closing_change_orders: list, comments: string, completion_date: string, currency: string, grand_total: any, grand_total_with_changes: any, last_changed: string, last_status_change: string, order_id: int, order_number: string, order_title: string, payment_reference: string, print_order_ids: list, project: record, status: string, status_comments: string, supplier_reference: string, supplier_workgroup: record, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/sellOrders"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific sell order
#
# GET /v1/workgroups/{workgroup_id}/sellOrders/{order_id}
# operationId: getSellOrderOfWorkgroup
export def "workgroups-sell-orders get-sell-order-of" [
  workgroup_id: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<accepted_date: string, annulled_date: string, approved_date: string, awarded_date: string, budget_type: string, buyer: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, buyer_workgroup: record<workgroup_id: int, workgroup_name: string>, change_orders: list<record>, classification: string, closed_date: string, closing_change_orders: list<record>, comments: string, completion_date: string, creator_user_id: int, currency: string, custom_fields: list<record>, grand_total: any, grand_total_with_changes: any, item_count: int, last_activity_date: string, last_changed: string, last_status_change: string, misc_cost: float, order_id: int, order_items: list<record>, order_number: string, order_title: string, order_total: any, overs_percent: float, parent_order_id: int, payment_reference: string, print_order_ids: list<int>, project: record<project_id: int, project_name: string, project_number: string>, quote_id: int, shipping: any, status: string, status_comments: string, supplier: record<email: string, first_name: string, last_name: string, middle_name: string, user_id: int>, supplier_reference: string, supplier_selection_reason: string, supplier_workgroup: record<workgroup_id: int, workgroup_name: string>, tax: any, transactional_currency: string, transactional_grand_total: any, transactional_grand_total_with_changes: any, transactional_order_total: any, transactional_shipping: any, transactional_tax: any, unders_percent: float>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, order_id: $order_id} | format pattern "/v1/workgroups/{workgroup_id}/sellOrders/{order_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Spec Templates of Workgroup Level 
#
# GET /v1/workgroups/{workgroup_id}/specTemplates
# operationId: getSpecTemplateList
export def "workgroups-spec-templates get-spec-template-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<created_by: record, created_date: string, is_active: bool, is_externally_published: bool, is_locked: bool, last_updated_date: string, spec_template_id: int, spec_template_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/specTemplates"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific Spec Template
#
# GET /v1/workgroups/{workgroup_id}/specTemplates/{spec_template_id}
# operationId: getSpecTemplate
export def "workgroups-spec-templates get" [
  workgroup_id: string
  spec_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<created_by: record<email: string, first_name: string, last_name: string, middle_name: string>, created_date: string, is_active: bool, is_externally_published: bool, is_locked: bool, last_updated_date: string, product_type: string, product_type_info: record<label: string, product_type_id: int>, spec_template_id: int, spec_template_name: string, spec_type: record<spec_type_id: int, spec_type_name: string>>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, spec_template_id: $spec_template_id} | format pattern "/v1/workgroups/{workgroup_id}/specTemplates/{spec_template_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Spec Type Fields
#
# GET /v1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields
export def "workgroups-spec-types-spec-type-fields get" [
  workgroup_id: string
  spec_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<data_type: string, param_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, spec_type_id: $spec_type_id} | format pattern "/v1/workgroups/{workgroup_id}/specTypes/{spec_type_id}/specTypeFields"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List supplier workgroups
#
# GET /v1/workgroups/{workgroup_id}/supplierWorkgroups
# operationId: getSupplierWorkgroupList
export def "workgroups-supplier-workgroups get-supplier-workgroup-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: table<bu_supplier_workgroup_id: int, bu_supplier_workgroup_name: string, client_workgroup_id: int, client_workgroup_name: string, is_approved: bool, supplier_code: string, supplier_workgroup_id: int, supplier_workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/supplierWorkgroups"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the specific supplier of My Group
#
# GET /v1/workgroups/{workgroup_id}/supplierWorkgroups/{bu_supplier_workgroup_id}
# operationId: getSupplierWorkgroupDetail
export def "workgroups-supplier-workgroups get-supplier-workgroup-detail" [
  workgroup_id: string
  bu_supplier_workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<additional_workgroups_contain_same_supplier: list<record>, bu_supplier_workgroup_id: int, bu_supplier_workgroup_name: string, client_workgroup_id: int, client_workgroup_name: string, is_approved: bool, supplier_code: string, supplier_workgroup_id: int, supplier_workgroup_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, bu_supplier_workgroup_id: $bu_supplier_workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/supplierWorkgroups/{bu_supplier_workgroup_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task types of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/taskTypes
# operationId: getTaskTypesOfWorkgroup
export def "workgroups-task-types get-task-types-of" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<task_type: string, task_type_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/taskTypes"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get task list of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/tasks
# operationId: getTaskListOfWorkgroup
export def "workgroups-tasks get-task-list-of" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<actual_end: string, actual_hours: any, actual_start: string, assign_to: record, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, current_duration: any, is_milestone: bool, mod_date: string, plan_end: string, plan_start: string, priority: string, project: record, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/tasks"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sepcific task of workgroup level
#
# GET /v1/workgroups/{workgroup_id}/tasks/{task_id}
# operationId: getTaskOfWorkgroup
export def "workgroups-tasks get-task-of" [
  workgroup_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<actual_duration: any, actual_end: string, actual_hours: any, actual_start: string, assign_to: record<email: string, first_name: string, last_name: string, middle_name: string>, baseline_duration: any, baseline_end_date: string, baseline_start_date: string, comments: string, create_date: string, creator_workgroup_name: string, current_duration: any, description: string, is_milestone: bool, last_updated_by: record<email: string, first_name: string, last_name: string, middle_name: string>, mod_date: string, percent_complete: int, plan_duration: any, plan_end: string, plan_start: string, priority: string, project: record<project_id: int, project_name: string, project_number: string>, requested_by: record<email: string, first_name: string, last_name: string, middle_name: string>, schedule_code: string, status: string, task_id: int, task_name: string, task_type: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, task_id: $task_id} | format pattern "/v1/workgroups/{workgroup_id}/tasks/{task_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List current user's team templates info 
#
# GET /v1/workgroups/{workgroup_id}/teamTemplates
# operationId: getTeamTemplateList
export def "workgroups-team-templates get-team-template-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<team_template_id: int, team_template_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/teamTemplates"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current user's team template detal info 
#
# GET /v1/workgroups/{workgroup_id}/teamTemplates/{team_template_id}
# operationId: getTeamTemplateDetail
export def "workgroups-team-templates get-team-template-detail" [
  workgroup_id: string
  team_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: record<team_teample_item: list<record>, team_template_id: int, team_template_name: string>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, team_template_id: $team_template_id} | format pattern "/v1/workgroups/{workgroup_id}/teamTemplates/{team_template_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the workgroup members
#
# GET /v1/workgroups/{workgroup_id}/workgroupMembers
# operationId: getWorkgroupMemberList
export def "workgroups-workgroup-members get-workgroup-member-list" [
  workgroup_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<results: table<email: string, first_name: string, last_name: string, user_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id} | format pattern "/v1/workgroups/{workgroup_id}/workgroupMembers"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Workgroup Member Info
#
# GET /v1/workgroups/{workgroup_id}/workgroupMembers/{user_id}
# operationId: getWorkgroupMemberInfo
export def "workgroups-workgroup-members get-workgroup-member-info" [
  workgroup_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<result: record<address: any, company_name: string, email: string, fax_number: string, first_name: string, last_name: string, locale: string, middle_name: string, organization: string, phone_number: string, time_zone: string, title: string, user_id: int>, status_code: int, status_reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workgroup_id: $workgroup_id, user_id: $user_id} | format pattern "/v1/workgroups/{workgroup_id}/workgroupMembers/{user_id}"))
  let accept_val = ($accept | default "*/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
