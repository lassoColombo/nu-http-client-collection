# Auto-generated client for Prowlarr v1.0.0
# Source: https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/src/Prowlarr.Api.V1/openapi.json
# Auth: --token flag or $env.PROWLARR_TOKEN

const BASE_URL = "http://localhost:9696"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROWLARR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-Api-Key: $token_val}, query: ""} }
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
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

def base-url-completer [] { ["http://localhost:9696" "https://localhost:9696"] }
def auth-scheme-completer [] { ["x-api-key" "query-apikey"] }

# Completers for enum parameters
def syncLevel-completer [] { ["addOnly" "disabled" "fullSync"] }
def applyTags-completer [] { ["add" "remove" "replace"] }
def priority-completer [] { ["high" "low" "normal"] }
def status-completer [] { ["aborted" "cancelled" "completed" "failed" "orphaned" "queued" "started"] }
def trigger-completer [] { ["manual" "scheduled" "unspecified"] }
def protocol-completer [] { ["torrent" "unknown" "usenet"] }
def sortDirection-completer [] { ["ascending" "default" "descending"] }
def eventType-completer [] { ["indexerAuth" "indexerInfo" "indexerQuery" "indexerRss" "releaseGrabbed" "unknown"] }
def authenticationMethod-completer [] { ["basic" "external" "forms" "none"] }
def authenticationRequired-completer [] { ["disabledForLocalAddresses" "enabled"] }
def updateMechanism-completer [] { ["apt" "builtIn" "docker" "external" "script"] }
def proxyType-completer [] { ["http" "socks4" "socks5"] }
def certificateValidation-completer [] { ["disabled" "disabledForLocalAddresses" "enabled"] }
def privacy-completer [] { ["private" "public" "semiPrivate"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-info get" } } | get name | first)
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

# GET /api
export def "api-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<current: string, deprecated: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/applications/{id}
export def "applications get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, syncLevel: string, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/applications/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
export def "applications put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
  --syncLevel: string@syncLevel-completer
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, syncLevel: string, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/applications/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, syncLevel: $syncLevel, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/applications/{id}
export def "applications delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/applications
export def "applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, syncLevel: string, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/applications
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
export def "applications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
  --syncLevel: string@syncLevel-completer
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, syncLevel: string, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/applications" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, syncLevel: $syncLevel, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/applications/bulk
export def "applications-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --syncLevel: string@syncLevel-completer
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, syncLevel: string, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applications/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, syncLevel: $syncLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/applications/bulk
export def "applications-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --syncLevel: string@syncLevel-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applications/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, syncLevel: $syncLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/applications/schema
export def "applications-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, syncLevel: string, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applications/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/applications/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
export def "applications-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
  --syncLevel: string@syncLevel-completer
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/applications/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, syncLevel: $syncLevel, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/applications/testall
export def "applications-testall post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/applications/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/applications/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
export def "applications-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, syncLevel?: "disabled"|"addOnly"|"fullSync", testCommand?: string}
  --syncLevel: string@syncLevel-completer
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/applications/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, syncLevel: $syncLevel, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/appprofile
export def "appprofile post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --name: string # nullable
  --enableRss: oneof<nothing, bool>
  --enableAutomaticSearch: oneof<nothing, bool>
  --enableInteractiveSearch: oneof<nothing, bool>
  --minimumSeeders: int # format: int32
]: any -> record<id: int, name: string, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, minimumSeeders: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/appprofile")
  let body = {id: $id, name: $name, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, minimumSeeders: $minimumSeeders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/appprofile
export def "appprofile list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, minimumSeeders: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/appprofile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/appprofile/{id}
export def "appprofile delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/appprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/appprofile/{id}
export def "appprofile put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --name: string # nullable
  --enableRss: oneof<nothing, bool>
  --enableAutomaticSearch: oneof<nothing, bool>
  --enableInteractiveSearch: oneof<nothing, bool>
  --minimumSeeders: int # format: int32
]: any -> record<id: int, name: string, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, minimumSeeders: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/appprofile/($id)")
  let body = {id: $body_id, name: $name, enableRss: $enableRss, enableAutomaticSearch: $enableAutomaticSearch, enableInteractiveSearch: $enableInteractiveSearch, minimumSeeders: $minimumSeeders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/appprofile/{id}
export def "appprofile get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, minimumSeeders: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/appprofile/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/appprofile/schema
export def "appprofile-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, enableRss: bool, enableAutomaticSearch: bool, enableInteractiveSearch: bool, minimumSeeders: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/appprofile/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /login
export def "login post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --returnUrl: string
  --username: string
  --password: string
  --rememberMe: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "returnUrl" $returnUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/login" $qp)
  let body = {username: $username, password: $password, rememberMe: $rememberMe} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# GET /login
export def "login get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /logout
export def "logout get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/backup
export def "system-backup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, path: string, type: string, size: int, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/backup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/system/backup/{id}
export def "system-backup delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/system/backup/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/backup/restore/{id}
export def "system-backup-restore post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/system/backup/restore/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/backup/restore/upload
export def "system-backup-restore-upload post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/backup/restore/upload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/command/{id}
export def "command get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isTypeExclusive: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/command/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /api/v1/command/{id}
export def "command delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/command/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/command
#
# --body shape: {sendUpdatesToClient?: bool, lastExecutionTime?: string, lastStartTime?: string, trigger?: "unspecified"|"manual"|"scheduled", suppressMessages?: bool, clientUserAgent?: string}
export def "command post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --name: string # nullable
  --commandName: string # nullable
  --message: string # nullable
  --body-body: record # shape: {sendUpdatesToClient?: bool, lastExecutionTime?: string, lastStartTime?: string, trigger?: "unspecified"|"manual"|"scheduled", suppressMessages?: bool, clientUserAgent?: string}
  --priority: string@priority-completer
  --status: string@status-completer
  --queued: string # format: date-time
  --started: string # nullable, format: date-time
  --ended: string # nullable, format: date-time
  --duration: string # nullable, format: date-span
  --exception: string # nullable
  --trigger: string@trigger-completer
  --clientUserAgent: string # nullable
  --stateChangeTime: string # nullable, format: date-time
  --sendUpdatesToClient: oneof<nothing, bool>
  --updateScheduledTask: oneof<nothing, bool>
  --lastExecutionTime: string # nullable, format: date-time
]: any -> record<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isTypeExclusive: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/command")
  let body = {id: $id, name: $name, commandName: $commandName, message: $message, body: $body_body, priority: $priority, status: $status, queued: $queued, started: $started, ended: $ended, duration: $duration, exception: $exception, trigger: $trigger, clientUserAgent: $clientUserAgent, stateChangeTime: $stateChangeTime, sendUpdatesToClient: $sendUpdatesToClient, updateScheduledTask: $updateScheduledTask, lastExecutionTime: $lastExecutionTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/command
export def "command list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, commandName: string, message: string, body: record<sendUpdatesToClient: bool, updateScheduledTask: bool, completionMessage: string, requiresDiskAccess: bool, isExclusive: bool, isTypeExclusive: bool, name: string, lastExecutionTime: string, lastStartTime: string, trigger: string, suppressMessages: bool, clientUserAgent: string>, priority: string, status: string, queued: string, started: string, ended: string, duration: string, exception: string, trigger: string, clientUserAgent: string, stateChangeTime: string, sendUpdatesToClient: bool, updateScheduledTask: bool, lastExecutionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/command")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/customfilter/{id}
export def "customfilter get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, type: string, label: string, filters: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customfilter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/customfilter/{id}
export def "customfilter put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --type: string # nullable
  --label: string # nullable
  --filters: list # nullable
]: any -> record<id: int, type: string, label: string, filters: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customfilter/($id)")
  let body = {id: $body_id, type: $type, label: $label, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/customfilter/{id}
export def "customfilter delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/customfilter/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/customfilter
export def "customfilter list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, type: string, label: string, filters: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customfilter")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/customfilter
export def "customfilter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --type: string # nullable
  --label: string # nullable
  --filters: list # nullable
]: any -> record<id: int, type: string, label: string, filters: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/customfilter")
  let body = {id: $id, type: $type, label: $label, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/config/development/{id}
export def "config-development put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --consoleLogLevel: string # nullable
  --logSql: oneof<nothing, bool>
  --logIndexerResponse: oneof<nothing, bool>
  --logRotate: int # format: int32
  --filterSentryEvents: oneof<nothing, bool>
]: any -> record<id: int, consoleLogLevel: string, logSql: bool, logIndexerResponse: bool, logRotate: int, filterSentryEvents: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/development/($id)")
  let body = {id: $body_id, consoleLogLevel: $consoleLogLevel, logSql: $logSql, logIndexerResponse: $logIndexerResponse, logRotate: $logRotate, filterSentryEvents: $filterSentryEvents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/development/{id}
export def "config-development get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, consoleLogLevel: string, logSql: bool, logIndexerResponse: bool, logRotate: int, filterSentryEvents: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/development/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/development
export def "config-development list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, consoleLogLevel: string, logSql: bool, logIndexerResponse: bool, logRotate: int, filterSentryEvents: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/development")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/downloadclient/{id}
export def "downloadclient get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, categories: table<clientCategory: string, categories: list>, supportsCategories: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/downloadclient/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
# --categories item shape: {clientCategory?: string, categories?: list}
export def "downloadclient put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
  --enable: oneof<nothing, bool>
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --categories: list # nullable — item shape: {clientCategory?: string, categories?: list}
  --supportsCategories: oneof<nothing, bool>
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, categories: table<clientCategory: string, categories: list>, supportsCategories: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/downloadclient/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, categories: $categories, supportsCategories: $supportsCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/downloadclient/{id}
export def "downloadclient delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/downloadclient
export def "downloadclient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, categories: list<record>, supportsCategories: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downloadclient")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/downloadclient
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
# --categories item shape: {clientCategory?: string, categories?: list}
export def "downloadclient post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
  --enable: oneof<nothing, bool>
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --categories: list # nullable — item shape: {clientCategory?: string, categories?: list}
  --supportsCategories: oneof<nothing, bool>
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, categories: table<clientCategory: string, categories: list>, supportsCategories: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/downloadclient" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, categories: $categories, supportsCategories: $supportsCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/downloadclient/bulk
export def "downloadclient-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enable: oneof<nothing, bool> # nullable
  --priority: int # nullable, format: int32
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, categories: table<clientCategory: string, categories: list>, supportsCategories: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downloadclient/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/downloadclient/bulk
export def "downloadclient-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enable: oneof<nothing, bool> # nullable
  --priority: int # nullable, format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downloadclient/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/downloadclient/schema
export def "downloadclient-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, enable: bool, protocol: string, priority: int, categories: list<record>, supportsCategories: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downloadclient/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/downloadclient/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
# --categories item shape: {clientCategory?: string, categories?: list}
export def "downloadclient-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
  --enable: oneof<nothing, bool>
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --categories: list # nullable — item shape: {clientCategory?: string, categories?: list}
  --supportsCategories: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/downloadclient/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, categories: $categories, supportsCategories: $supportsCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/downloadclient/testall
export def "downloadclient-testall post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downloadclient/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/downloadclient/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
# --categories item shape: {clientCategory?: string, categories?: list}
export def "downloadclient-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, enable?: bool, protocol?: "unknown"|"usenet"|"torrent", priority?: int, categories?: list, supportsCategories?: bool}
  --enable: oneof<nothing, bool>
  --protocol: string@protocol-completer
  --priority: int # format: int32
  --categories: list # nullable — item shape: {clientCategory?: string, categories?: list}
  --supportsCategories: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downloadclient/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, enable: $enable, protocol: $protocol, priority: $priority, categories: $categories, supportsCategories: $supportsCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/downloadclient/{id}
export def "config-downloadclient get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/downloadclient/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/downloadclient/{id}
export def "config-downloadclient put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/downloadclient/($id)")
  let body = {id: $body_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/downloadclient
export def "config-downloadclient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/downloadclient")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/filesystem
export def "filesystem get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string
  --includeFiles: oneof<nothing, bool> # default: false
  --allowFoldersWithoutTrailingSlashes: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "includeFiles" $includeFiles "scalar") (serialize-qp "allowFoldersWithoutTrailingSlashes" $allowFoldersWithoutTrailingSlashes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/filesystem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/filesystem/type
export def "filesystem-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --path: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/filesystem/type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, source: string, type: string, message: string, wikiUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/history
export def "history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string@sortDirection-completer
  --eventType: list
  --successful: oneof<nothing, bool>
  --downloadId: string
  --indexerIds: list
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, indexerId: int, date: string, downloadId: string, successful: bool, eventType: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "eventType" $eventType "multi") (serialize-qp "successful" $successful "scalar") (serialize-qp "downloadId" $downloadId "scalar") (serialize-qp "indexerIds" $indexerIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/history/since
export def "history-since get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # format: date-time
  --eventType: string@eventType-completer
]: nothing -> table<id: int, indexerId: int, date: string, downloadId: string, successful: bool, eventType: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "eventType" $eventType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/history/since" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/history/indexer
export def "history-indexer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --indexerId: int # format: int32
  --eventType: string@eventType-completer
  --limit: int # format: int32
]: nothing -> table<id: int, indexerId: int, date: string, downloadId: string, successful: bool, eventType: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexerId" $indexerId "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/history/indexer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/host/{id}
export def "config-host get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, logSizeLimit: int, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, historyCleanupDays: int, trustCgnatIpAddresses: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/host/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/host/{id}
export def "config-host put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --bindAddress: string # nullable
  --port: int # format: int32
  --sslPort: int # format: int32
  --enableSsl: oneof<nothing, bool>
  --launchBrowser: oneof<nothing, bool>
  --authenticationMethod: string@authenticationMethod-completer
  --authenticationRequired: string@authenticationRequired-completer
  --analyticsEnabled: oneof<nothing, bool>
  --username: string # nullable
  --password: string # nullable
  --passwordConfirmation: string # nullable
  --logLevel: string # nullable
  --logSizeLimit: int # format: int32
  --consoleLogLevel: string # nullable
  --branch: string # nullable
  --apiKey: string # nullable
  --sslCertPath: string # nullable
  --sslCertPassword: string # nullable
  --urlBase: string # nullable
  --instanceName: string # nullable
  --applicationUrl: string # nullable
  --updateAutomatically: oneof<nothing, bool>
  --updateMechanism: string@updateMechanism-completer
  --updateScriptPath: string # nullable
  --proxyEnabled: oneof<nothing, bool>
  --proxyType: string@proxyType-completer
  --proxyHostname: string # nullable
  --proxyPort: int # format: int32
  --proxyUsername: string # nullable
  --proxyPassword: string # nullable
  --proxyBypassFilter: string # nullable
  --proxyBypassLocalAddresses: oneof<nothing, bool>
  --certificateValidation: string@certificateValidation-completer
  --backupFolder: string # nullable
  --backupInterval: int # format: int32
  --backupRetention: int # format: int32
  --historyCleanupDays: int # format: int32
  --trustCgnatIpAddresses: oneof<nothing, bool>
]: any -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, logSizeLimit: int, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, historyCleanupDays: int, trustCgnatIpAddresses: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/host/($id)")
  let body = {id: $body_id, bindAddress: $bindAddress, port: $port, sslPort: $sslPort, enableSsl: $enableSsl, launchBrowser: $launchBrowser, authenticationMethod: $authenticationMethod, authenticationRequired: $authenticationRequired, analyticsEnabled: $analyticsEnabled, username: $username, password: $password, passwordConfirmation: $passwordConfirmation, logLevel: $logLevel, logSizeLimit: $logSizeLimit, consoleLogLevel: $consoleLogLevel, branch: $branch, apiKey: $apiKey, sslCertPath: $sslCertPath, sslCertPassword: $sslCertPassword, urlBase: $urlBase, instanceName: $instanceName, applicationUrl: $applicationUrl, updateAutomatically: $updateAutomatically, updateMechanism: $updateMechanism, updateScriptPath: $updateScriptPath, proxyEnabled: $proxyEnabled, proxyType: $proxyType, proxyHostname: $proxyHostname, proxyPort: $proxyPort, proxyUsername: $proxyUsername, proxyPassword: $proxyPassword, proxyBypassFilter: $proxyBypassFilter, proxyBypassLocalAddresses: $proxyBypassLocalAddresses, certificateValidation: $certificateValidation, backupFolder: $backupFolder, backupInterval: $backupInterval, backupRetention: $backupRetention, historyCleanupDays: $historyCleanupDays, trustCgnatIpAddresses: $trustCgnatIpAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/host
export def "config-host list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, bindAddress: string, port: int, sslPort: int, enableSsl: bool, launchBrowser: bool, authenticationMethod: string, authenticationRequired: string, analyticsEnabled: bool, username: string, password: string, passwordConfirmation: string, logLevel: string, logSizeLimit: int, consoleLogLevel: string, branch: string, apiKey: string, sslCertPath: string, sslCertPassword: string, urlBase: string, instanceName: string, applicationUrl: string, updateAutomatically: bool, updateMechanism: string, updateScriptPath: string, proxyEnabled: bool, proxyType: string, proxyHostname: string, proxyPort: int, proxyUsername: string, proxyPassword: string, proxyBypassFilter: string, proxyBypassLocalAddresses: bool, certificateValidation: string, backupFolder: string, backupInterval: int, backupRetention: int, historyCleanupDays: int, trustCgnatIpAddresses: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/host")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexer/{id}
export def "indexer get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, indexerUrls: list<string>, legacyUrls: list<string>, definitionName: string, description: string, language: string, encoding: string, enable: bool, redirect: bool, supportsRss: bool, supportsSearch: bool, supportsRedirect: bool, supportsPagination: bool, appProfileId: int, protocol: string, privacy: string, capabilities: record<id: int, limitsMax: int, limitsDefault: int, categories: list<record>, supportsRawSearch: bool, searchParams: list<string>, tvSearchParams: list<string>, movieSearchParams: list<string>, musicSearchParams: list<string>, bookSearchParams: list<string>>, priority: int, downloadClientId: int, added: string, status: record<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string>, sortName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/indexer/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
# --capabilities shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
# --status shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
export def "indexer put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
  --indexerUrls: list # nullable
  --legacyUrls: list # nullable
  --definitionName: string # nullable
  --description: string # nullable
  --language: string # nullable
  --encoding: string # nullable
  --enable: oneof<nothing, bool>
  --redirect: oneof<nothing, bool>
  --supportsRss: oneof<nothing, bool>
  --supportsSearch: oneof<nothing, bool>
  --supportsRedirect: oneof<nothing, bool>
  --supportsPagination: oneof<nothing, bool>
  --appProfileId: int # format: int32
  --protocol: string@protocol-completer
  --privacy: string@privacy-completer
  --capabilities: record # shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
  --priority: int # format: int32
  --downloadClientId: int # format: int32
  --added: string # format: date-time
  --status: record # shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
  --sortName: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, indexerUrls: list<string>, legacyUrls: list<string>, definitionName: string, description: string, language: string, encoding: string, enable: bool, redirect: bool, supportsRss: bool, supportsSearch: bool, supportsRedirect: bool, supportsPagination: bool, appProfileId: int, protocol: string, privacy: string, capabilities: record<id: int, limitsMax: int, limitsDefault: int, categories: list<record>, supportsRawSearch: bool, searchParams: list<string>, tvSearchParams: list<string>, movieSearchParams: list<string>, musicSearchParams: list<string>, bookSearchParams: list<string>>, priority: int, downloadClientId: int, added: string, status: record<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string>, sortName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/indexer/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, indexerUrls: $indexerUrls, legacyUrls: $legacyUrls, definitionName: $definitionName, description: $description, language: $language, encoding: $encoding, enable: $enable, redirect: $redirect, supportsRss: $supportsRss, supportsSearch: $supportsSearch, supportsRedirect: $supportsRedirect, supportsPagination: $supportsPagination, appProfileId: $appProfileId, protocol: $protocol, privacy: $privacy, capabilities: $capabilities, priority: $priority, downloadClientId: $downloadClientId, added: $added, status: $status, sortName: $sortName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/indexer/{id}
export def "indexer delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexer/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexer
export def "indexer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, indexerUrls: list<string>, legacyUrls: list<string>, definitionName: string, description: string, language: string, encoding: string, enable: bool, redirect: bool, supportsRss: bool, supportsSearch: bool, supportsRedirect: bool, supportsPagination: bool, appProfileId: int, protocol: string, privacy: string, capabilities: record<id: int, limitsMax: int, limitsDefault: int, categories: list, supportsRawSearch: bool, searchParams: list, tvSearchParams: list, movieSearchParams: list, musicSearchParams: list, bookSearchParams: list>, priority: int, downloadClientId: int, added: string, status: record<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string>, sortName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexer
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
# --capabilities shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
# --status shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
export def "indexer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
  --indexerUrls: list # nullable
  --legacyUrls: list # nullable
  --definitionName: string # nullable
  --description: string # nullable
  --language: string # nullable
  --encoding: string # nullable
  --enable: oneof<nothing, bool>
  --redirect: oneof<nothing, bool>
  --supportsRss: oneof<nothing, bool>
  --supportsSearch: oneof<nothing, bool>
  --supportsRedirect: oneof<nothing, bool>
  --supportsPagination: oneof<nothing, bool>
  --appProfileId: int # format: int32
  --protocol: string@protocol-completer
  --privacy: string@privacy-completer
  --capabilities: record # shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
  --priority: int # format: int32
  --downloadClientId: int # format: int32
  --added: string # format: date-time
  --status: record # shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
  --sortName: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, indexerUrls: list<string>, legacyUrls: list<string>, definitionName: string, description: string, language: string, encoding: string, enable: bool, redirect: bool, supportsRss: bool, supportsSearch: bool, supportsRedirect: bool, supportsPagination: bool, appProfileId: int, protocol: string, privacy: string, capabilities: record<id: int, limitsMax: int, limitsDefault: int, categories: list<record>, supportsRawSearch: bool, searchParams: list<string>, tvSearchParams: list<string>, movieSearchParams: list<string>, musicSearchParams: list<string>, bookSearchParams: list<string>>, priority: int, downloadClientId: int, added: string, status: record<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string>, sortName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexer" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, indexerUrls: $indexerUrls, legacyUrls: $legacyUrls, definitionName: $definitionName, description: $description, language: $language, encoding: $encoding, enable: $enable, redirect: $redirect, supportsRss: $supportsRss, supportsSearch: $supportsSearch, supportsRedirect: $supportsRedirect, supportsPagination: $supportsPagination, appProfileId: $appProfileId, protocol: $protocol, privacy: $privacy, capabilities: $capabilities, priority: $priority, downloadClientId: $downloadClientId, added: $added, status: $status, sortName: $sortName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/indexer/bulk
export def "indexer-bulk put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enable: oneof<nothing, bool> # nullable
  --appProfileId: int # nullable, format: int32
  --priority: int # nullable, format: int32
  --minimumSeeders: int # nullable, format: int32
  --seedRatio: float # nullable, format: double
  --seedTime: int # nullable, format: int32
  --packSeedTime: int # nullable, format: int32
  --preferMagnetUrl: oneof<nothing, bool> # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, indexerUrls: list<string>, legacyUrls: list<string>, definitionName: string, description: string, language: string, encoding: string, enable: bool, redirect: bool, supportsRss: bool, supportsSearch: bool, supportsRedirect: bool, supportsPagination: bool, appProfileId: int, protocol: string, privacy: string, capabilities: record<id: int, limitsMax: int, limitsDefault: int, categories: list<record>, supportsRawSearch: bool, searchParams: list<string>, tvSearchParams: list<string>, movieSearchParams: list<string>, musicSearchParams: list<string>, bookSearchParams: list<string>>, priority: int, downloadClientId: int, added: string, status: record<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string>, sortName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, appProfileId: $appProfileId, priority: $priority, minimumSeeders: $minimumSeeders, seedRatio: $seedRatio, seedTime: $seedTime, packSeedTime: $packSeedTime, preferMagnetUrl: $preferMagnetUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/indexer/bulk
export def "indexer-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # nullable
  --tags: list # nullable
  --applyTags: string@applyTags-completer
  --enable: oneof<nothing, bool> # nullable
  --appProfileId: int # nullable, format: int32
  --priority: int # nullable, format: int32
  --minimumSeeders: int # nullable, format: int32
  --seedRatio: float # nullable, format: double
  --seedTime: int # nullable, format: int32
  --packSeedTime: int # nullable, format: int32
  --preferMagnetUrl: oneof<nothing, bool> # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/bulk")
  let body = {ids: $ids, tags: $tags, applyTags: $applyTags, enable: $enable, appProfileId: $appProfileId, priority: $priority, minimumSeeders: $minimumSeeders, seedRatio: $seedRatio, seedTime: $seedTime, packSeedTime: $packSeedTime, preferMagnetUrl: $preferMagnetUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/indexer/schema
export def "indexer-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, indexerUrls: list<string>, legacyUrls: list<string>, definitionName: string, description: string, language: string, encoding: string, enable: bool, redirect: bool, supportsRss: bool, supportsSearch: bool, supportsRedirect: bool, supportsPagination: bool, appProfileId: int, protocol: string, privacy: string, capabilities: record<id: int, limitsMax: int, limitsDefault: int, categories: list, supportsRawSearch: bool, searchParams: list, tvSearchParams: list, movieSearchParams: list, musicSearchParams: list, bookSearchParams: list>, priority: int, downloadClientId: int, added: string, status: record<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string>, sortName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexer/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
# --capabilities shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
# --status shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
export def "indexer-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
  --indexerUrls: list # nullable
  --legacyUrls: list # nullable
  --definitionName: string # nullable
  --description: string # nullable
  --language: string # nullable
  --encoding: string # nullable
  --enable: oneof<nothing, bool>
  --redirect: oneof<nothing, bool>
  --supportsRss: oneof<nothing, bool>
  --supportsSearch: oneof<nothing, bool>
  --supportsRedirect: oneof<nothing, bool>
  --supportsPagination: oneof<nothing, bool>
  --appProfileId: int # format: int32
  --protocol: string@protocol-completer
  --privacy: string@privacy-completer
  --capabilities: record # shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
  --priority: int # format: int32
  --downloadClientId: int # format: int32
  --added: string # format: date-time
  --status: record # shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
  --sortName: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexer/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, indexerUrls: $indexerUrls, legacyUrls: $legacyUrls, definitionName: $definitionName, description: $description, language: $language, encoding: $encoding, enable: $enable, redirect: $redirect, supportsRss: $supportsRss, supportsSearch: $supportsSearch, supportsRedirect: $supportsRedirect, supportsPagination: $supportsPagination, appProfileId: $appProfileId, protocol: $protocol, privacy: $privacy, capabilities: $capabilities, priority: $priority, downloadClientId: $downloadClientId, added: $added, status: $status, sortName: $sortName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/indexer/testall
export def "indexer-testall post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexer/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
# --capabilities shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
# --status shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
export def "indexer-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, indexerUrls?: list, legacyUrls?: list, definitionName?: string, description?: string, language?: string, encoding?: string, enable?: bool, redirect?: bool, supportsRss?: bool, supportsSearch?: bool, supportsRedirect?: bool, supportsPagination?: bool, appProfileId?: int, protocol?: "unknown"|"usenet"|"torrent", privacy?: "public"|"semiPrivate"|"private", capabilities?: record, priority?: int, downloadClientId?: int, added?: string, status?: record, sortName?: string}
  --indexerUrls: list # nullable
  --legacyUrls: list # nullable
  --definitionName: string # nullable
  --description: string # nullable
  --language: string # nullable
  --encoding: string # nullable
  --enable: oneof<nothing, bool>
  --redirect: oneof<nothing, bool>
  --supportsRss: oneof<nothing, bool>
  --supportsSearch: oneof<nothing, bool>
  --supportsRedirect: oneof<nothing, bool>
  --supportsPagination: oneof<nothing, bool>
  --appProfileId: int # format: int32
  --protocol: string@protocol-completer
  --privacy: string@privacy-completer
  --capabilities: record # shape: {id?: int, limitsMax?: int, limitsDefault?: int, categories?: list, supportsRawSearch?: bool, searchParams?: list, tvSearchParams?: list, movieSearchParams?: list, musicSearchParams?: list, bookSearchParams?: list}
  --priority: int # format: int32
  --downloadClientId: int # format: int32
  --added: string # format: date-time
  --status: record # shape: {id?: int, indexerId?: int, disabledTill?: string, mostRecentFailure?: string, initialFailure?: string}
  --sortName: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexer/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, indexerUrls: $indexerUrls, legacyUrls: $legacyUrls, definitionName: $definitionName, description: $description, language: $language, encoding: $encoding, enable: $enable, redirect: $redirect, supportsRss: $supportsRss, supportsSearch: $supportsSearch, supportsRedirect: $supportsRedirect, supportsPagination: $supportsPagination, appProfileId: $appProfileId, protocol: $protocol, privacy: $privacy, capabilities: $capabilities, priority: $priority, downloadClientId: $downloadClientId, added: $added, status: $status, sortName: $sortName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/indexer/categories
export def "indexer-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, description: string, subCategories: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexer/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexerproxy/{id}
export def "indexerproxy get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onHealthIssue: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexerproxy/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/indexerproxy/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
export def "indexerproxy put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
  --link: string # nullable
  --onHealthIssue: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onHealthIssue: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/indexerproxy/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onHealthIssue: $onHealthIssue, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/indexerproxy/{id}
export def "indexerproxy delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexerproxy/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexerproxy
export def "indexerproxy list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onHealthIssue: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexerproxy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexerproxy
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
export def "indexerproxy post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
  --link: string # nullable
  --onHealthIssue: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onHealthIssue: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexerproxy" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onHealthIssue: $onHealthIssue, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/indexerproxy/schema
export def "indexerproxy-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onHealthIssue: bool, supportsOnHealthIssue: bool, includeHealthWarnings: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexerproxy/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexerproxy/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
export def "indexerproxy-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
  --link: string # nullable
  --onHealthIssue: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexerproxy/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onHealthIssue: $onHealthIssue, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/indexerproxy/testall
export def "indexerproxy-testall post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexerproxy/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/indexerproxy/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
export def "indexerproxy-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onHealthIssue?: bool, supportsOnHealthIssue?: bool, includeHealthWarnings?: bool, testCommand?: string}
  --link: string # nullable
  --onHealthIssue: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/indexerproxy/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onHealthIssue: $onHealthIssue, supportsOnHealthIssue: $supportsOnHealthIssue, includeHealthWarnings: $includeHealthWarnings, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/indexerstats
export def "indexerstats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startDate: string # format: date-time
  --endDate: string # format: date-time
  --indexers: string
  --protocols: string
  --tags: string
]: nothing -> record<id: int, indexers: table<indexerId: int, indexerName: string, averageResponseTime: int, averageGrabResponseTime: int, numberOfQueries: int, numberOfGrabs: int, numberOfRssQueries: int, numberOfAuthQueries: int, numberOfFailedQueries: int, numberOfFailedGrabs: int, numberOfFailedRssQueries: int, numberOfFailedAuthQueries: int>, userAgents: table<userAgent: string, numberOfQueries: int, numberOfGrabs: int>, hosts: table<host: string, numberOfQueries: int, numberOfGrabs: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "indexers" $indexers "scalar") (serialize-qp "protocols" $protocols "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/indexerstats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexerstatus
export def "indexerstatus get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, indexerId: int, disabledTill: string, mostRecentFailure: string, initialFailure: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/indexerstatus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/localization
export def "localization get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/localization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/localization/options
export def "localization-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/localization/options")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log
export def "log get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # format: int32, default: 1
  --pageSize: int # format: int32, default: 10
  --sortKey: string
  --sortDirection: string@sortDirection-completer
  --level: string
]: nothing -> record<page: int, pageSize: int, sortKey: string, sortDirection: string, totalRecords: int, records: table<id: int, time: string, exception: string, exceptionType: string, level: string, logger: string, message: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sortKey" $sortKey "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "level" $level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file
export def "log-file list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, filename: string, lastWriteTime: string, contentsUrl: string, downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/log/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file/{filename}
export def "log-file get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/log/file/($filename)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexer/{id}/newznab
export def "indexer-newznab get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --t: string
  --q: string
  --cat: string
  --imdbid: string
  --tmdbid: int # format: int32
  --extended: string
  --limit: int # format: int32
  --offset: int # format: int32
  --minage: int # format: int32
  --maxage: int # format: int32
  --minsize: int # format: int64
  --maxsize: int # format: int64
  --rid: int # format: int32
  --tvmazeid: int # format: int32
  --traktid: int # format: int32
  --tvdbid: int # format: int32
  --doubanid: int # format: int32
  --season: int # format: int32
  --ep: string
  --album: string
  --artist: string
  --label: string
  --track: string
  --year: int # format: int32
  --genre: string
  --author: string
  --title: string
  --publisher: string
  --configured: string
  --qp-source: string
  --host: string
  --server: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "cat" $cat "scalar") (serialize-qp "imdbid" $imdbid "scalar") (serialize-qp "tmdbid" $tmdbid "scalar") (serialize-qp "extended" $extended "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "minage" $minage "scalar") (serialize-qp "maxage" $maxage "scalar") (serialize-qp "minsize" $minsize "scalar") (serialize-qp "maxsize" $maxsize "scalar") (serialize-qp "rid" $rid "scalar") (serialize-qp "tvmazeid" $tvmazeid "scalar") (serialize-qp "traktid" $traktid "scalar") (serialize-qp "tvdbid" $tvdbid "scalar") (serialize-qp "doubanid" $doubanid "scalar") (serialize-qp "season" $season "scalar") (serialize-qp "ep" $ep "scalar") (serialize-qp "album" $album "scalar") (serialize-qp "artist" $artist "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "track" $track "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "genre" $genre "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "publisher" $publisher "scalar") (serialize-qp "configured" $configured "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "server" $server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/indexer/($id)/newznab" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /{id}/api
export def "newznab get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --t: string
  --q: string
  --cat: string
  --imdbid: string
  --tmdbid: int # format: int32
  --extended: string
  --limit: int # format: int32
  --offset: int # format: int32
  --minage: int # format: int32
  --maxage: int # format: int32
  --minsize: int # format: int64
  --maxsize: int # format: int64
  --rid: int # format: int32
  --tvmazeid: int # format: int32
  --traktid: int # format: int32
  --tvdbid: int # format: int32
  --doubanid: int # format: int32
  --season: int # format: int32
  --ep: string
  --album: string
  --artist: string
  --label: string
  --track: string
  --year: int # format: int32
  --genre: string
  --author: string
  --title: string
  --publisher: string
  --configured: string
  --qp-source: string
  --host: string
  --server: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "t" $t "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "cat" $cat "scalar") (serialize-qp "imdbid" $imdbid "scalar") (serialize-qp "tmdbid" $tmdbid "scalar") (serialize-qp "extended" $extended "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "minage" $minage "scalar") (serialize-qp "maxage" $maxage "scalar") (serialize-qp "minsize" $minsize "scalar") (serialize-qp "maxsize" $maxsize "scalar") (serialize-qp "rid" $rid "scalar") (serialize-qp "tvmazeid" $tvmazeid "scalar") (serialize-qp "traktid" $traktid "scalar") (serialize-qp "tvdbid" $tvdbid "scalar") (serialize-qp "doubanid" $doubanid "scalar") (serialize-qp "season" $season "scalar") (serialize-qp "ep" $ep "scalar") (serialize-qp "album" $album "scalar") (serialize-qp "artist" $artist "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "track" $track "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "genre" $genre "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "publisher" $publisher "scalar") (serialize-qp "configured" $configured "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "server" $server "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($id)/api" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/indexer/{id}/download
export def "indexer-download get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --link: string
  --file: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "link" $link "scalar") (serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/indexer/($id)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /{id}/download
export def "download get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --link: string
  --file: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "link" $link "scalar") (serialize-qp "file" $file "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($id)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/notification/{id}
export def "notification get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onHealthIssue: bool, onHealthRestored: bool, onApplicationUpdate: bool, supportsOnGrab: bool, includeManualGrabs: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, includeHealthWarnings: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/notification/{id}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
export def "notification put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --body-id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: oneof<nothing, bool>
  --onHealthIssue: oneof<nothing, bool>
  --onHealthRestored: oneof<nothing, bool>
  --onApplicationUpdate: oneof<nothing, bool>
  --supportsOnGrab: oneof<nothing, bool>
  --includeManualGrabs: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --supportsOnHealthRestored: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --supportsOnApplicationUpdate: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onHealthIssue: bool, onHealthRestored: bool, onApplicationUpdate: bool, supportsOnGrab: bool, includeManualGrabs: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, includeHealthWarnings: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/notification/($id)" $qp)
  let body = {id: $body_id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onHealthIssue: $onHealthIssue, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, includeManualGrabs: $includeManualGrabs, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, includeHealthWarnings: $includeHealthWarnings, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/notification/{id}
export def "notification delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/notification
export def "notification list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onHealthIssue: bool, onHealthRestored: bool, onApplicationUpdate: bool, supportsOnGrab: bool, includeManualGrabs: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, includeHealthWarnings: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/notification
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
export def "notification post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceSave: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: oneof<nothing, bool>
  --onHealthIssue: oneof<nothing, bool>
  --onHealthRestored: oneof<nothing, bool>
  --onApplicationUpdate: oneof<nothing, bool>
  --supportsOnGrab: oneof<nothing, bool>
  --includeManualGrabs: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --supportsOnHealthRestored: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --supportsOnApplicationUpdate: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> record<id: int, name: string, fields: table<order: int, name: string, label: string, unit: string, helpText: string, helpTextWarning: string, helpLink: string, value: any, type: string, advanced: bool, selectOptions: list, selectOptionsProviderAction: string, section: string, hidden: string, privacy: string, placeholder: string, isFloat: bool>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onHealthIssue: bool, onHealthRestored: bool, onApplicationUpdate: bool, supportsOnGrab: bool, includeManualGrabs: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, includeHealthWarnings: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceSave" $forceSave "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notification" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onHealthIssue: $onHealthIssue, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, includeManualGrabs: $includeManualGrabs, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, includeHealthWarnings: $includeHealthWarnings, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/notification/schema
export def "notification-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, fields: list<record>, implementationName: string, implementation: string, configContract: string, infoLink: string, message: record<message: string, type: string>, tags: list<int>, presets: list<any>, link: string, onGrab: bool, onHealthIssue: bool, onHealthRestored: bool, onApplicationUpdate: bool, supportsOnGrab: bool, includeManualGrabs: bool, supportsOnHealthIssue: bool, supportsOnHealthRestored: bool, includeHealthWarnings: bool, supportsOnApplicationUpdate: bool, testCommand: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notification/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/notification/test
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
export def "notification-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --forceTest: oneof<nothing, bool> # default: false
  --id: int # format: int32
  --name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: oneof<nothing, bool>
  --onHealthIssue: oneof<nothing, bool>
  --onHealthRestored: oneof<nothing, bool>
  --onApplicationUpdate: oneof<nothing, bool>
  --supportsOnGrab: oneof<nothing, bool>
  --includeManualGrabs: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --supportsOnHealthRestored: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --supportsOnApplicationUpdate: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceTest" $forceTest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/notification/test" $qp)
  let body = {id: $id, name: $name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onHealthIssue: $onHealthIssue, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, includeManualGrabs: $includeManualGrabs, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, includeHealthWarnings: $includeHealthWarnings, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/v1/notification/testall
export def "notification-testall post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/notification/testall")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/notification/action/{name}
#
# --fields item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
# --message shape: {message?: string, type?: "info"|"warning"|"error"}
# --presets item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
export def "notification-action post" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --body-name: string # nullable
  --body-fields: list # nullable — item shape: {order?: int, name?: string, label?: string, unit?: string, helpText?: string, helpTextWarning?: string, helpLink?: string, value?: any, type?: string, advanced?: bool, selectOptions?: list, selectOptionsProviderAction?: string, section?: string, hidden?: string, privacy?: "normal"|"password"|"apiKey"|"userName", placeholder?: string, isFloat?: bool}
  --implementationName: string # nullable
  --implementation: string # nullable
  --configContract: string # nullable
  --infoLink: string # nullable
  --message: record # shape: {message?: string, type?: "info"|"warning"|"error"}
  --tags: list # nullable
  --presets: list # nullable — item shape: {id?: int, name?: string, fields?: list, implementationName?: string, implementation?: string, configContract?: string, infoLink?: string, message?: record, tags?: list, presets?: list, link?: string, onGrab?: bool, onHealthIssue?: bool, onHealthRestored?: bool, onApplicationUpdate?: bool, supportsOnGrab?: bool, includeManualGrabs?: bool, supportsOnHealthIssue?: bool, supportsOnHealthRestored?: bool, includeHealthWarnings?: bool, supportsOnApplicationUpdate?: bool, testCommand?: string}
  --link: string # nullable
  --onGrab: oneof<nothing, bool>
  --onHealthIssue: oneof<nothing, bool>
  --onHealthRestored: oneof<nothing, bool>
  --onApplicationUpdate: oneof<nothing, bool>
  --supportsOnGrab: oneof<nothing, bool>
  --includeManualGrabs: oneof<nothing, bool>
  --supportsOnHealthIssue: oneof<nothing, bool>
  --supportsOnHealthRestored: oneof<nothing, bool>
  --includeHealthWarnings: oneof<nothing, bool>
  --supportsOnApplicationUpdate: oneof<nothing, bool>
  --testCommand: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/notification/action/($name)")
  let body = {id: $id, name: $body_name, fields: $body_fields, implementationName: $implementationName, implementation: $implementation, configContract: $configContract, infoLink: $infoLink, message: $message, tags: $tags, presets: $presets, link: $link, onGrab: $onGrab, onHealthIssue: $onHealthIssue, onHealthRestored: $onHealthRestored, onApplicationUpdate: $onApplicationUpdate, supportsOnGrab: $supportsOnGrab, includeManualGrabs: $includeManualGrabs, supportsOnHealthIssue: $supportsOnHealthIssue, supportsOnHealthRestored: $supportsOnHealthRestored, includeHealthWarnings: $includeHealthWarnings, supportsOnApplicationUpdate: $supportsOnApplicationUpdate, testCommand: $testCommand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /ping
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# HEAD /ping
export def "ping head" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/search
#
# --categories item shape: {id?: int, name?: string, description?: string}
export def "search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --guid: string # nullable
  --age: int # format: int32
  --ageHours: float # format: double
  --ageMinutes: float # format: double
  --size: int # format: int64
  --files: int # nullable, format: int32
  --grabs: int # nullable, format: int32
  --indexerId: int # format: int32
  --indexer: string # nullable
  --subGroup: string # nullable
  --releaseHash: string # nullable
  --title: string # nullable
  --sortTitle: string # nullable
  --imdbId: int # format: int32
  --tmdbId: int # format: int32
  --tvdbId: int # format: int32
  --tvMazeId: int # format: int32
  --publishDate: string # format: date-time
  --commentUrl: string # nullable
  --downloadUrl: string # nullable
  --infoUrl: string # nullable
  --posterUrl: string # nullable
  --indexerFlags: list # nullable
  --categories: list # nullable — item shape: {id?: int, name?: string, description?: string}
  --magnetUrl: string # nullable
  --infoHash: string # nullable
  --seeders: int # nullable, format: int32
  --leechers: int # nullable, format: int32
  --protocol: string@protocol-completer
  --downloadClientId: int # nullable, format: int32
]: any -> record<id: int, guid: string, age: int, ageHours: float, ageMinutes: float, size: int, files: int, grabs: int, indexerId: int, indexer: string, subGroup: string, releaseHash: string, title: string, sortTitle: string, imdbId: int, tmdbId: int, tvdbId: int, tvMazeId: int, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, posterUrl: string, indexerFlags: list<string>, categories: table<id: int, name: string, description: string, subCategories: list>, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, fileName: string, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/search")
  let body = {id: $id, guid: $guid, age: $age, ageHours: $ageHours, ageMinutes: $ageMinutes, size: $size, files: $files, grabs: $grabs, indexerId: $indexerId, indexer: $indexer, subGroup: $subGroup, releaseHash: $releaseHash, title: $title, sortTitle: $sortTitle, imdbId: $imdbId, tmdbId: $tmdbId, tvdbId: $tvdbId, tvMazeId: $tvMazeId, publishDate: $publishDate, commentUrl: $commentUrl, downloadUrl: $downloadUrl, infoUrl: $infoUrl, posterUrl: $posterUrl, indexerFlags: $indexerFlags, categories: $categories, magnetUrl: $magnetUrl, infoHash: $infoHash, seeders: $seeders, leechers: $leechers, protocol: $protocol, downloadClientId: $downloadClientId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --type: string
  --indexerIds: list
  --categories: list
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> table<id: int, guid: string, age: int, ageHours: float, ageMinutes: float, size: int, files: int, grabs: int, indexerId: int, indexer: string, subGroup: string, releaseHash: string, title: string, sortTitle: string, imdbId: int, tmdbId: int, tvdbId: int, tvMazeId: int, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, posterUrl: string, indexerFlags: list<string>, categories: list<record>, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, fileName: string, downloadClientId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "indexerIds" $indexerIds "multi") (serialize-qp "categories" $categories "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/search/bulk
export def "search-bulk post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, guid: string, age: int, ageHours: float, ageMinutes: float, size: int, files: int, grabs: int, indexerId: int, indexer: string, subGroup: string, releaseHash: string, title: string, sortTitle: string, imdbId: int, tmdbId: int, tvdbId: int, tvMazeId: int, publishDate: string, commentUrl: string, downloadUrl: string, infoUrl: string, posterUrl: string, indexerFlags: list<string>, categories: table<id: int, name: string, description: string, subCategories: list>, magnetUrl: string, infoHash: string, seeders: int, leechers: int, protocol: string, fileName: string, downloadClientId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/search/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /content/{path}
export def "content get" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/content/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /
export def "static-resource get-by-path" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /{path}
export def "static-resource get-by-path-1" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/status
export def "system-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<appName: string, instanceName: string, version: string, buildTime: string, isDebug: bool, isProduction: bool, isAdmin: bool, isUserInteractive: bool, startupPath: string, appData: string, osName: string, osVersion: string, isNetCore: bool, isLinux: bool, isOsx: bool, isWindows: bool, isDocker: bool, mode: string, branch: string, databaseType: string, databaseVersion: string, authentication: string, migrationVersion: int, urlBase: string, runtimeVersion: string, runtimeName: string, startTime: string, packageVersion: string, packageAuthor: string, packageUpdateMechanism: string, packageUpdateMechanismMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/routes
export def "system-routes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/routes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/routes/duplicate
export def "system-routes-duplicate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/routes/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/shutdown
export def "system-shutdown post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/system/restart
export def "system-restart post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/restart")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag/{id}
export def "tag get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tag/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/tag/{id}
export def "tag put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --label: string # nullable
]: any -> record<id: int, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tag/($id)")
  let body = {id: $body_id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/tag/{id}
export def "tag delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tag/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag
export def "tag list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/v1/tag
export def "tag post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # format: int32
  --label: string # nullable
]: any -> record<id: int, label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tag")
  let body = {id: $id, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/tag/detail/{id}
export def "tag-detail get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, label: string, notificationIds: list<int>, indexerIds: list<int>, indexerProxyIds: list<int>, applicationIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tag/detail/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/tag/detail
export def "tag-detail list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, label: string, notificationIds: list<int>, indexerIds: list<int>, indexerProxyIds: list<int>, applicationIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tag/detail")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/task
export def "system-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, name: string, taskName: string, interval: int, lastExecution: string, lastStartTime: string, nextExecution: string, lastDuration: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/task")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/system/task/{id}
export def "system-task get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, taskName: string, interval: int, lastExecution: string, lastStartTime: string, nextExecution: string, lastDuration: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/system/task/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /api/v1/config/ui/{id}
export def "config-ui put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: int # format: int32
  --firstDayOfWeek: int # format: int32
  --calendarWeekColumnHeader: string # nullable
  --shortDateFormat: string # nullable
  --longDateFormat: string # nullable
  --timeFormat: string # nullable
  --showRelativeDates: oneof<nothing, bool>
  --enableColorImpairedMode: oneof<nothing, bool>
  --uiLanguage: string # nullable
  --theme: string # nullable
]: any -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, uiLanguage: string, theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/ui/($id)")
  let body = {id: $body_id, firstDayOfWeek: $firstDayOfWeek, calendarWeekColumnHeader: $calendarWeekColumnHeader, shortDateFormat: $shortDateFormat, longDateFormat: $longDateFormat, timeFormat: $timeFormat, showRelativeDates: $showRelativeDates, enableColorImpairedMode: $enableColorImpairedMode, uiLanguage: $uiLanguage, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/config/ui/{id}
export def "config-ui get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, uiLanguage: string, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/ui/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/config/ui
export def "config-ui list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, firstDayOfWeek: int, calendarWeekColumnHeader: string, shortDateFormat: string, longDateFormat: string, timeFormat: string, showRelativeDates: bool, enableColorImpairedMode: bool, uiLanguage: string, theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/ui")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/update
export def "update get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, version: string, branch: string, releaseDate: string, fileName: string, url: string, installed: bool, installedOn: string, installable: bool, latest: bool, changes: record<new: list, fixed: list>, hash: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file/update
export def "log-file-update list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, filename: string, lastWriteTime: string, contentsUrl: string, downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/log/file/update")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/v1/log/file/update/{filename}
export def "log-file-update get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/log/file/update/($filename)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
