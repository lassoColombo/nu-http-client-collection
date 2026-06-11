# Auto-generated client for Fields API v8
# Source: https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/fields.json
# Auth: --token flag or $env.FIELDS_API_TOKEN

const BASE_URL = "https://zohoapis.com/crm/v8"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FIELDS_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://zohoapis.com/crm/v8" "https://zohoapis.eu/crm/v8" "https://zohoapis.in/crm/v8" "https://zohoapis.cn/crm/v8" "https://zohoapis.au/crm/v8"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def include-completer [] { ["allowed_permissions_to_update" "skip_field_permissionz"] }
def type-completer [] { ["all" "unused" "used"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "settings-fields list" } } | get name | first)
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

# Get Fields
#
# GET /settings/fields
# operationId: getFields
export def "settings-fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-module: string # The API name of the module to which the field belongs.
  --include: string@include-completer # To include additional information about the field's permissions to update.
  --type: string@type-completer # The usage type of the field.
]: nothing -> record<fields: table<associated_module: any, webhook: bool, operation_type: record, colour_code_enabled_by_system: bool, field_label: string, tooltip: any, display_format_properties: any, type: string, field_read_only: bool, customizable_properties: any, display_label: string, read_only: bool, association_details: any, businesscard_supported: bool, multi_module_lookup: any, id: string, created_time: any, filterable: bool, visible: bool, profiles: list, view_type: record, separator: bool, searchable: bool, history_tracking_enabled: bool, external: any, api_name: string, parent_field: any, unique: record, enable_colour_code: bool, child_fields: any, pick_list_values: any, system_mandatory: bool, private: any, virtual_field: bool, json_type: string, crypt: any, range: any, created_source: string, display_type: float, ui_type: float, modified_time: any, public: bool, email_parser: record, currency: any, custom_field: bool, lookup: any, hipaa_compliance: any, convert_mapping: record, address: any, rollup_summary: any, length: float, column_name: string, display_field: bool, pick_list_values_sorted_lexically: bool, sortable: bool, global_picklist: any, display_format: any, history_tracking: any, data_type: string, formula: any, additional_column: any, hipaa_compliance_enabled: bool, decimal_place: any, mass_update: bool, multiselectlookup: any, auto_number: any, layout_associations: list, quick_sequence_number: string, blueprint_supported: bool, textarea: record, sharing_properties: record, multiuserlookup: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "module" $qp_module "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settings/fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Fields
#
# POST /settings/fields
# operationId: postFields
# --fields item shape: {field_label: string, data_type: "text"|"textarea"|"email"|"phone"|"picklist"|"multiselectpicklist"|"date"|"datetime"|"integer"|"autonumber"|"currency"|"percent"|"bigint"|"double"|"website"|"boolean"|"fileupload"|"imageupload"|"lookup"|"userlookup"|"multiselectlookup"|"multiuserlookup"|"formula"|"rollup_summary"|"address", length?: int, filterable?: bool, tooltip?: record, profiles?: list, external?: record, crypt?: any, encrypt_case?: "uppercase"|"lowercase", textarea?: record, unique?: any, hipaa_compliance_enabled?: bool, private?: record, pick_list_values?: list, enable_record_state?: bool, default_value?: string, pick_list_values_sorted_lexically?: bool, enable_colour_code?: bool, global_picklist?: record, history_tracking_enabled?: bool, history_tracking?: record, separator?: bool, auto_number?: record, _update_existing_records?: bool, formula?: record, decimal_place?: float, number_separator?: bool, currency?: record, rollup_summary?: record, lookup?: record, multiselectlookup?: record}
export def "settings-fields post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-module: string # The API name of the module to which the field belongs.
  --body-fields: list # List of fields to be created — item shape: {field_label: string, data_type: "text"|"textarea"|"email"|"phone"|"picklist"|"multiselectpicklist"|"date"|"datetime"|"integer"|"autonumber"|"currency"|"percent"|"bigint"|"double"|"website"|"boolean"|"fileupload"|"imageupload"|"lookup"|"userlookup"|"multiselectlookup"|"multiuserlookup"|"formula"|"rollup_summary"|"address", length?: int, filterable?: bool, tooltip?: record, profiles?: list, external?: record, crypt?: any, encrypt_case?: "uppercase"|"lowercase", textarea?: record, unique?: any, hipaa_compliance_enabled?: bool, private?: record, pick_list_values?: list, enable_record_state?: bool, default_value?: string, pick_list_values_sorted_lexically?: bool, enable_colour_code?: bool, global_picklist?: record, history_tracking_enabled?: bool, history_tracking?: record, separator?: bool, auto_number?: record, _update_existing_records?: bool, formula?: record, decimal_place?: float, number_separator?: bool, currency?: record, rollup_summary?: record, lookup?: record, multiselectlookup?: record}
]: any -> record<fields: table<code: string, details: record, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "module" $qp_module "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settings/fields" $qp)
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Fields
#
# PATCH /settings/fields
# operationId: patchFields
# --fields item shape: {field_label?: string, id?: string, length?: int, profiles?: list, unique?: any, lookup?: record, pick_list_values?: list, global_picklist?: any, sharing_properties?: record, history_tracking_enabled?: bool, history_tracking?: record, formula?: record, decimal_place?: float, currency?: record, rollup_summary?: record}
export def "settings-fields patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-module: string # The API name of the module to which the field belongs.
  --body-fields: list # List of fields to be created — item shape: {field_label?: string, id?: string, length?: int, profiles?: list, unique?: any, lookup?: record, pick_list_values?: list, global_picklist?: any, sharing_properties?: record, history_tracking_enabled?: bool, history_tracking?: record, formula?: record, decimal_place?: float, currency?: record, rollup_summary?: record}
]: any -> record<fields: table<code: string, details: record, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "module" $qp_module "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settings/fields" $qp)
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Field by ID
#
# GET /settings/fields/{fieldId}
# operationId: getFieldsWithID
export def "settings-fields get" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-module: string # The API name of the module to which the field belongs.
  --include: string@include-completer # To include additional information about the field's permissions to update.
  --type: string@type-completer # The usage type of the field.
]: nothing -> record<fields: table<associated_module: any, webhook: bool, operation_type: record, colour_code_enabled_by_system: bool, field_label: string, tooltip: any, display_format_properties: any, type: string, field_read_only: bool, customizable_properties: any, display_label: string, read_only: bool, association_details: any, businesscard_supported: bool, multi_module_lookup: any, id: string, created_time: any, filterable: bool, visible: bool, profiles: list, view_type: record, separator: bool, searchable: bool, history_tracking_enabled: bool, external: any, api_name: string, parent_field: any, unique: record, enable_colour_code: bool, child_fields: any, pick_list_values: any, system_mandatory: bool, private: any, virtual_field: bool, json_type: string, crypt: any, range: any, created_source: string, display_type: float, ui_type: float, modified_time: any, public: bool, email_parser: record, currency: any, custom_field: bool, lookup: any, hipaa_compliance: any, convert_mapping: record, address: any, rollup_summary: any, length: float, column_name: string, display_field: bool, pick_list_values_sorted_lexically: bool, sortable: bool, global_picklist: any, display_format: any, history_tracking: any, data_type: string, formula: any, additional_column: any, hipaa_compliance_enabled: bool, decimal_place: any, mass_update: bool, multiselectlookup: any, auto_number: any, layout_associations: list, quick_sequence_number: string, blueprint_supported: bool, textarea: record, sharing_properties: record, multiuserlookup: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "module" $qp_module "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/settings/fields/($fieldId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Field by ID
#
# PATCH /settings/fields/{fieldId}
# operationId: putFieldsWithId
# --fields item shape: {field_label?: string, id?: string, length?: int, profiles?: list, unique?: any, lookup?: record, pick_list_values?: list, global_picklist?: any, sharing_properties?: record, history_tracking_enabled?: bool, history_tracking?: record, formula?: record, decimal_place?: float, currency?: record, rollup_summary?: record}
export def "settings-fields patch-by-fieldId" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-module: string # The API name of the module to which the field belongs.
  --body-fields: list # List of fields to be created — item shape: {field_label?: string, id?: string, length?: int, profiles?: list, unique?: any, lookup?: record, pick_list_values?: list, global_picklist?: any, sharing_properties?: record, history_tracking_enabled?: bool, history_tracking?: record, formula?: record, decimal_place?: float, currency?: record, rollup_summary?: record}
]: any -> record<fields: table<code: string, details: record, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "module" $qp_module "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/settings/fields/($fieldId)" $qp)
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Custom Field
#
# DELETE /settings/fields/{fieldId}
# operationId: deleteCustomField
export def "settings-fields delete" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-module: string # The API name of the module to which the field belongs.
]: nothing -> record<fields: table<code: string, details: record, message: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "module" $qp_module "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/settings/fields/($fieldId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
