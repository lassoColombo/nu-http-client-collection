# Auto-generated client for Records v8.0
# Source: https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/record.json
# Auth: --token flag or $env.RECORDS_TOKEN

const BASE_URL = "https://zohoapis.com/crm/v8"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RECORDS_TOKEN | default "" }
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

def base-url-completer [] { ["https://zohoapis.com/crm/v8" "https://zohoapis.eu/crm/v8" "https://zohoapis.in/crm/v8" "https://zohoapis.cn/crm/v8" "https://zohoapis.au/crm/v8"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-order-completer [] { ["asc" "desc"] }
def sort-by-completer [] { ["Created_Time" "Modified_Time" "id"] }
def converted-completer [] { ["both" "false" "true"] }
def type-completer [] { ["all" "permanent" "recycle"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api list" } } | get name | first)
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

# Get Records for a specific module
#
# GET /{module}
# operationId: getRecords
export def "api list" [
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: string # Specify the API names of the fields you want to retrieve when fetching the records.
  --territory-id: string # Specify the territory ID to get the list of records that belongs to a specific territory (format: int64)
  --ids: string # To retrieve specific records based on their unique ID.
  --cvid: string # Specify the custom view ID to get the list of records based on custom views (format: int64)
  --per-page: int # Specify how many records to return per page (format: int32)
  --page: int # To get the list of records from the respective pages (format: int32)
  --page-token: string # To fetch more than 2000 records, you must include the "page_token" param in the request
  --sort-order: string@sort-order-completer # To sort the available list of records in either ascending or descending order
  --sort-by: string@sort-by-completer # To sort the records based on the fields id, Created_Time, and Modified_Time. The default value is 'id'
  --converted: string@converted-completer # To get the list of converted records
  --include-child: oneof<nothing, bool> # To include records from the child territories
]: nothing -> record<data: table<id: string, Owner: record, Created_Time: string, Modified_Time: string, Created_By: record, Modified_By: record>, info: record<page: int, call: bool, per_page: int, count: int, more_records: bool, email: bool, sort_by: string, sort_order: string, next_page_token: string, previous_page_token: string, page_token_expiry: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "territory_id" $territory_id "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "cvid" $cvid "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "converted" $converted "scalar") (serialize-qp "include_child" $include_child "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($module)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Record in a specific module
#
# POST /{module}
# operationId: createRecords
# --data item shape: {id?: string, $append_values?: string}
export def "api createRecords" [
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # Request body containing one or more records to be created or updated. — item shape: {id?: string, $append_values?: string}
  --apply-feature-execution: list # List of features that should be executed on demand during record processing.
  --skip-feature-execution: list # List of features that should be skipped during record processing.
  --trigger: list # List of automation triggers to invoke during the record operation.
]: any -> record<data: table<code: string, message: string, status: string, details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)")
  let body = {data: $data, apply_feature_execution: $apply_feature_execution, skip_feature_execution: $skip_feature_execution, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# To update existing entities or records in a specified module
#
# PUT /{module}
# operationId: updateRecords
# --data item shape: {id?: string, $append_values?: string}
export def "api updateRecords" [
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # Request body containing one or more records to be created or updated. — item shape: {id?: string, $append_values?: string}
  --apply-feature-execution: list # List of features that should be executed on demand during record processing.
  --skip-feature-execution: list # List of features that should be skipped during record processing.
  --trigger: list # List of automation triggers to invoke during the record operation.
]: any -> record<data: table<code: string, message: string, status: string, details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)")
  let body = {data: $data, apply_feature_execution: $apply_feature_execution, skip_feature_execution: $skip_feature_execution, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete multiple records from a module
#
# DELETE /{module}
# operationId: deleteRecords
export def "api delete-by-module" [
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # To retrieve specific records based on their unique ID.
]: nothing -> record<data: table<code: string, details: record, message: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($module)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Record for a specific module with RecordId
#
# GET /{module}/{recordID}
# operationId: getRecord
export def "api get" [
  recordID: string
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: string, Owner: record, Created_Time: string, Modified_Time: string, Created_By: record, Modified_By: record>, info: record<page: int, call: bool, per_page: int, count: int, more_records: bool, email: bool, sort_by: string, sort_order: string, next_page_token: string, previous_page_token: string, page_token_expiry: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)/($recordID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# To update existing entities or records in a specified module with the recordID
#
# PUT /{module}/{recordID}
# operationId: updateRecord
# --data item shape: {id?: string, $append_values?: string}
export def "api updateRecord" [
  module: string
  recordID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # Request body containing one or more records to be created or updated. — item shape: {id?: string, $append_values?: string}
  --apply-feature-execution: list # List of features that should be executed on demand during record processing.
  --skip-feature-execution: list # List of features that should be skipped during record processing.
  --trigger: list # List of automation triggers to invoke during the record operation.
]: any -> record<data: table<code: string, message: string, status: string, details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)/($recordID)")
  let body = {data: $data, apply_feature_execution: $apply_feature_execution, skip_feature_execution: $skip_feature_execution, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a single record by ID
#
# DELETE /{module}/{recordID}
# operationId: deleteRecord
export def "api delete-by-module-recordID" [
  module: string
  recordID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<code: string, message: string, status: string, details: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)/($recordID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# To insert a new or update an existing record based on duplicate check field
#
# POST /{module}/upsert
# operationId: upsertRecords
# --data item shape: {id?: string}
export def "upsert upsertRecords" [
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # List of records to be created or updated using the upsert operation. — item shape: {id?: string}
  --trigger: list # List of automation triggers to be executed during the upsert operation.
  --duplicate-check-fields: list # Defines the ordered list of fields used to detect duplicate records during upsert.
  --wf-trigger: string # Workflow trigger identifier to be executed as part of the upsert operation. (nullable)
  --lar-id: string # Layout assignment rule identifier used to determine record layout during upsert. (nullable)
]: any -> record<data: table<code: string, message: string, status: string, details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)/upsert")
  let body = {data: $data, trigger: $trigger, duplicate_check_fields: $duplicate_check_fields, wf_trigger: $wf_trigger, lar_id: $lar_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get deleted records from a module
#
# GET /{module}/deleted
# operationId: getDeletedRecords
export def "deleted get" [
  module: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # Specifies the type of deleted records to retrieve. Use 'all' to get all deleted records, 'recycle' for records in recycle bin, or 'permanent' for permanently deleted records. (default: all)
  --page: int # To get the list of records from the respective pages. Default value for page is 1. (format: int32, default: 1)
  --per-page: int # To get the list of records available per page. The default and the maximum possible value is 200. (format: int32, default: 200)
]: nothing -> record<data: table<id: string, display_name: string, type: string, deleted_time: string, deleted_by: record, created_by: record>, info: record<per_page: int, count: int, page: int, more_records: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($module)/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# To clone a record in a module
#
# POST /{module}/{recordID}/actions/clone
# operationId: cloneRecord
# --data item shape: {id?: string, $append_values?: string}
export def "actions-clone cloneRecord" [
  module: string
  recordID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: list # Request body containing one or more records to be created or updated. — item shape: {id?: string, $append_values?: string}
  --apply-feature-execution: list # List of features that should be executed on demand during record processing.
  --skip-feature-execution: list # List of features that should be skipped during record processing.
  --trigger: list # List of automation triggers to invoke during the record operation.
]: any -> record<data: table<code: string, message: string, status: string, details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($module)/($recordID)/actions/clone")
  let body = {data: $data, apply_feature_execution: $apply_feature_execution, skip_feature_execution: $skip_feature_execution, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
