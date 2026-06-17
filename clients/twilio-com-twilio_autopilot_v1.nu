# Auto-generated client for Twilio - Autopilot v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_autopilot_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_AUTOPILOT_TOKEN

const BASE_URL = "https://autopilot.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_AUTOPILOT_TOKEN | default "" }
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

def base-url-completer [] { ["https://autopilot.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "assistants list" } } | get name | first)
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

# GET /v1/Assistants
#
# operationId: ListAssistant
export def "assistants list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<assistants: table<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Assistants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants
#
# operationId: CreateAssistant
export def "assistants create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Reserved.
  --callback-url: string # Reserved. (format: uri)
  --defaults: any # A JSON object that defines the Assistant's [default tasks](https://www.twilio.com/docs/autopilot/api/assistant/defaults) for various scenarios, including initiation actions and fallback tasks.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It is not unique and can be up to 255 characters long.
  --log-queries: oneof<nothing, bool> # Whether queries should be logged and kept after training. Can be: `true` or `false` and defaults to `true`. If `true`, queries are stored for 30 days, and then deleted. If `false`, no queries are stored.
  --style-sheet: any # The JSON string that defines the Assistant's [style sheet](https://www.twilio.com/docs/autopilot/api/assistant/stylesheet)
  --unique-name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base "/v1/Assistants")
  let body = {"CallbackEvents": $callback_events, "CallbackUrl": $callback_url, "Defaults": $defaults, "FriendlyName": $friendly_name, "LogQueries": $log_queries, "StyleSheet": $style_sheet, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/Assistants/Restore
#
# operationId: UpdateRestoreAssistant
export def "assistants-restore update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  assistant: string # The Twilio-provided string that uniquely identifies the Assistant resource to restore.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base "/v1/Assistants/Restore")
  let body = {"Assistant": $assistant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/Defaults
#
# operationId: FetchDefaults
export def "assistants-defaults get" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Defaults"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Defaults
#
# operationId: UpdateDefaults
export def "assistants-defaults update" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaults: any # A JSON string that describes the default task links for the `assistant_initiation`, `collect`, and `fallback` situations.
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Defaults"))
  let body = {"Defaults": $defaults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/Dialogues/{Sid}
#
# operationId: FetchDialogue
export def "assistants-dialogues get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Dialogues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes
#
# operationId: ListFieldType
export def "assistants-field-types list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<field_types: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/FieldTypes
#
# operationId: CreateFieldType
export def "assistants-field-types create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the new resource. It is not unique and can be up to 255 characters long.
  unique_name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes"))
  let body = {"FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# operationId: ListFieldValue
export def "assistants-field-types-field-values list" [
  assistant_sid: string
  field_type_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) tag that specifies the language of the value. Currently supported tags: `en-US`
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<field_values: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "Language" $language "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, field_type_sid: $field_type_sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues
#
# operationId: CreateFieldValue
export def "assistants-field-types-field-values create" [
  assistant_sid: string
  field_type_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) tag that specifies the language of the value. Currently supported tags: `en-US`
  --synonym-of: string # The string value that indicates which word the field value is a synonym of.
  value: string # The Field Value data.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, field_type_sid: $field_type_sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues"))
  let body = {"Language": $language, "SynonymOf": $synonym_of, "Value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: DeleteFieldValue
export def "assistants-field-types-field-values delete" [
  assistant_sid: string
  field_type_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes/{FieldTypeSid}/FieldValues/{Sid}
#
# operationId: FetchFieldValue
export def "assistants-field-types-field-values get" [
  assistant_sid: string
  field_type_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type_sid: string, language: string, sid: string, synonym_of: string, url: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, field_type_sid: $field_type_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{field_type_sid}/FieldValues/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: DeleteFieldType
export def "assistants-field-types delete" [
  assistant_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: FetchFieldType
export def "assistants-field-types get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/FieldTypes/{Sid}
#
# operationId: UpdateFieldType
export def "assistants-field-types update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/FieldTypes/{sid}"))
  let body = {"FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/ModelBuilds
#
# operationId: ListModelBuild
export def "assistants-model-builds list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, model_builds: table<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/ModelBuilds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/ModelBuilds
#
# operationId: CreateModelBuild
export def "assistants-model-builds create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status-callback: string # The URL we should call using a POST method to send status information to your application. (format: uri)
  --unique-name: string # An application-defined string that uniquely identifies the new resource. This value must be a unique string of no more than 64 characters. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/ModelBuilds"))
  let body = {"StatusCallback": $status_callback, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: DeleteModelBuild
export def "assistants-model-builds delete" [
  assistant_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/ModelBuilds/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: FetchModelBuild
export def "assistants-model-builds get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/ModelBuilds/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/ModelBuilds/{Sid}
#
# operationId: UpdateModelBuild
export def "assistants-model-builds update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be a unique string of no more than 64 characters. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, assistant_sid: string, build_duration: int, date_created: string, date_updated: string, error_code: int, sid: string, status: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/ModelBuilds/{sid}"))
  let body = {"UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/Queries
#
# operationId: ListQuery
export def "assistants-queries list-query" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used by the Query resources to read. For example: `en-US`.
  --model-build: string # The SID or unique name of the [Model Build](https://www.twilio.com/docs/autopilot/api/model-build) to be queried.
  --status: string # The status of the resources to read. Can be: `pending-review`, `reviewed`, or `discarded`
  --dialogue-sid: string # The SID of the [Dialogue](https://www.twilio.com/docs/autopilot/api/dialogue).
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, queries: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "Language" $language "scalar") (serialize-qp "ModelBuild" $model_build "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "DialogueSid" $dialogue_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Queries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Queries
#
# operationId: CreateQuery
export def "assistants-queries create-query" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the new query. For example: `en-US`.
  --model-build: string # The SID or unique name of the [Model Build](https://www.twilio.com/docs/autopilot/api/model-build) to be queried.
  query: string # The end-user's natural language input. It can be up to 2048 characters long.
  --tasks: string # The list of tasks to limit the new query to. Tasks are expressed as a comma-separated list of task `unique_name` values. For example, `task-unique_name-1, task-unique_name-2`. Listing specific tasks is useful to constrain the paths that a user can take.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Queries"))
  let body = {"Language": $language, "ModelBuild": $model_build, "Query": $query, "Tasks": $tasks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: DeleteQuery
export def "assistants-queries delete-query" [
  assistant_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Queries/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: FetchQuery
export def "assistants-queries get-query" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Queries/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Queries/{Sid}
#
# operationId: UpdateQuery
export def "assistants-queries update-query" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sample-sid: string # The SID of an optional reference to the [Sample](https://www.twilio.com/docs/autopilot/api/task-sample) created from the query.
  --status: string # The new status of the resource. Can be: `pending-review`, `reviewed`, or `discarded`
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, dialogue_sid: string, language: string, model_build_sid: string, query: string, results: any, sample_sid: string, sid: string, source_channel: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Queries/{sid}"))
  let body = {"SampleSid": $sample_sid, "Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns Style sheet JSON object for the Assistant
#
# GET /v1/Assistants/{AssistantSid}/StyleSheet
# operationId: FetchStyleSheet
export def "assistants-style-sheet get" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/StyleSheet"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the style sheet for an Assistant identified by `assistant_sid`.
#
# POST /v1/Assistants/{AssistantSid}/StyleSheet
# operationId: UpdateStyleSheet
export def "assistants-style-sheet update" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --style-sheet: any # The JSON string that describes the style sheet object.
]: any -> record<account_sid: string, assistant_sid: string, data: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/StyleSheet"))
  let body = {"StyleSheet": $style_sheet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/Tasks
#
# operationId: ListTask
export def "assistants-tasks list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, tasks: table<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Tasks
#
# operationId: CreateTask
export def "assistants-tasks create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON string that specifies the [actions](https://www.twilio.com/docs/autopilot/actions) that instruct the Assistant on how to perform the task. It is optional and not unique.
  --actions-url: string # The URL from which the Assistant can fetch actions. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the new resource. It is not unique and can be up to 255 characters long.
  unique_name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. This value must be unique and 64 characters or less in length.
]: any -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks"))
  let body = {"Actions": $actions, "ActionsUrl": $actions_url, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: DeleteTask
export def "assistants-tasks delete" [
  assistant_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: FetchTask
export def "assistants-tasks get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{Sid}
#
# operationId: UpdateTask
export def "assistants-tasks update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON string that specifies the [actions](https://www.twilio.com/docs/autopilot/actions) that instruct the Assistant on how to perform the task.
  --actions-url: string # The URL from which the Assistant can fetch actions. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --unique-name: string # An application-defined string that uniquely identifies the resource. This value must be 64 characters or less in length and be unique. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, actions_url: string, assistant_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{sid}"))
  let body = {"Actions": $actions, "ActionsUrl": $actions_url, "FriendlyName": $friendly_name, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns JSON actions for the Task.
#
# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# operationId: FetchTaskActions
export def "assistants-tasks-actions get" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the actions of an Task identified by {TaskSid} or {TaskUniqueName}.
#
# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Actions
# operationId: UpdateTaskActions
export def "assistants-tasks-actions update" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actions: any # The JSON string that specifies the [actions](https://www.twilio.com/docs/autopilot/actions) that instruct the Assistant on how to perform the task.
]: any -> record<account_sid: string, assistant_sid: string, data: any, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Actions"))
  let body = {"Actions": $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# operationId: ListField
export def "assistants-tasks-fields list" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<fields: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields
#
# operationId: CreateField
export def "assistants-tasks-fields create" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  field_type: string # The Field Type of the new field. Can be: a [Built-in Field Type](https://www.twilio.com/docs/autopilot/built-in-field-types), the `unique_name`, or the `sid` of a custom Field Type.
  unique_name: string # An application-defined string that uniquely identifies the new resource. This value must be a unique string of no more than 64 characters. It can be used as an alternative to the `sid` in the URL path to address the resource.
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields"))
  let body = {"FieldType": $field_type, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: DeleteField
export def "assistants-tasks-fields delete" [
  assistant_sid: string
  task_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Fields/{Sid}
#
# operationId: FetchField
export def "assistants-tasks-fields get" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, field_type: string, sid: string, task_sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Fields/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# operationId: ListSample
export def "assistants-tasks-samples list" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the sample. For example: `en-US`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, samples: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "Language" $language "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples
#
# operationId: CreateSample
export def "assistants-tasks-samples create" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the new sample. For example: `en-US`.
  --source-channel: string # The communication channel from which the new sample was captured. Can be: `voice`, `sms`, `chat`, `alexa`, `google-assistant`, `slack`, or null if not included.
  tagged_text: string # The text example of how end users might express the task. The sample can contain [Field tag blocks](https://www.twilio.com/docs/autopilot/api/task-sample#field-tagging).
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples"))
  let body = {"Language": $language, "SourceChannel": $source_channel, "TaggedText": $tagged_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: DeleteSample
export def "assistants-tasks-samples delete" [
  assistant_sid: string
  task_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: FetchSample
export def "assistants-tasks-samples get" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Samples/{Sid}
#
# operationId: UpdateSample
export def "assistants-tasks-samples update" [
  assistant_sid: string
  task_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The [ISO language-country](https://docs.oracle.com/cd/E13214_01/wli/docs92/xref/xqisocodes.html) string that specifies the language used for the sample. For example: `en-US`.
  --source-channel: string # The communication channel from which the sample was captured. Can be: `voice`, `sms`, `chat`, `alexa`, `google-assistant`, `slack`, or null if not included.
  --tagged-text: string # The text example of how end users might express the task. The sample can contain [Field tag blocks](https://www.twilio.com/docs/autopilot/api/task-sample#field-tagging).
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, language: string, sid: string, source_channel: string, tagged_text: string, task_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Samples/{sid}"))
  let body = {"Language": $language, "SourceChannel": $source_channel, "TaggedText": $tagged_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Assistants/{AssistantSid}/Tasks/{TaskSid}/Statistics
#
# operationId: FetchTaskStatistics
export def "assistants-tasks-statistics get" [
  assistant_sid: string
  task_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, fields_count: int, samples_count: int, task_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, task_sid: $task_sid} | format pattern "/v1/Assistants/{assistant_sid}/Tasks/{task_sid}/Statistics"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Webhooks
#
# operationId: ListWebhook
export def "assistants-webhooks list" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Webhooks
#
# operationId: CreateWebhook
export def "assistants-webhooks create" [
  assistant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  events: string # The list of space-separated events that this Webhook will subscribe to.
  unique_name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. This value must be unique and 64 characters or less in length.
  --webhook-method: string # The method to be used when calling the webhook's URL.
  webhook_url: string # The URL associated with this Webhook. (format: uri)
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid} | format pattern "/v1/Assistants/{assistant_sid}/Webhooks"))
  let body = {"Events": $events, "UniqueName": $unique_name, "WebhookMethod": $webhook_method, "WebhookUrl": $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{AssistantSid}/Webhooks/{Sid}
#
# operationId: DeleteWebhook
export def "assistants-webhooks delete" [
  assistant_sid: string
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{AssistantSid}/Webhooks/{Sid}
#
# operationId: FetchWebhook
export def "assistants-webhooks get" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{AssistantSid}/Webhooks/{Sid}
#
# operationId: UpdateWebhook
export def "assistants-webhooks update" [
  assistant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: string # The list of space-separated events that this Webhook will subscribe to.
  --unique-name: string # An application-defined string that uniquely identifies the new resource. It can be used as an alternative to the `sid` in the URL path to address the resource. This value must be unique and 64 characters or less in length.
  --webhook-method: string # The method to be used when calling the webhook's URL.
  --webhook-url: string # The URL associated with this Webhook. (format: uri)
]: any -> record<account_sid: string, assistant_sid: string, date_created: string, date_updated: string, events: string, sid: string, unique_name: string, url: string, webhook_method: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({assistant_sid: $assistant_sid, sid: $sid} | format pattern "/v1/Assistants/{assistant_sid}/Webhooks/{sid}"))
  let body = {"Events": $events, "UniqueName": $unique_name, "WebhookMethod": $webhook_method, "WebhookUrl": $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/Assistants/{Sid}
#
# operationId: DeleteAssistant
export def "assistants delete" [
  sid: string
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
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({sid: $sid} | format pattern "/v1/Assistants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Assistants/{Sid}
#
# operationId: FetchAssistant
export def "assistants get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({sid: $sid} | format pattern "/v1/Assistants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Assistants/{Sid}
#
# operationId: UpdateAssistant
export def "assistants update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-events: string # Reserved.
  --callback-url: string # Reserved. (format: uri)
  --defaults: any # A JSON object that defines the Assistant's [default tasks](https://www.twilio.com/docs/autopilot/api/assistant/defaults) for various scenarios, including initiation actions and fallback tasks.
  --development-stage: string # A string describing the state of the assistant.
  --friendly-name: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --log-queries: oneof<nothing, bool> # Whether queries should be logged and kept after training. Can be: `true` or `false` and defaults to `true`. If `true`, queries are stored for 30 days, and then deleted. If `false`, no queries are stored.
  --style-sheet: any # The JSON string that defines the Assistant's [style sheet](https://www.twilio.com/docs/autopilot/api/assistant/stylesheet)
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as an alternative to the `sid` in the URL path to address the resource. The first 64 characters must be unique.
]: any -> record<account_sid: string, callback_events: string, callback_url: string, date_created: string, date_updated: string, development_stage: string, friendly_name: string, latest_model_build_sid: string, links: record, log_queries: bool, needs_model_build: bool, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://autopilot.twilio.com")
  let full_url = (build-url $base ({sid: $sid} | format pattern "/v1/Assistants/{sid}"))
  let body = {"CallbackEvents": $callback_events, "CallbackUrl": $callback_url, "Defaults": $defaults, "DevelopmentStage": $development_stage, "FriendlyName": $friendly_name, "LogQueries": $log_queries, "StyleSheet": $style_sheet, "UniqueName": $unique_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
