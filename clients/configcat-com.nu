# Auto-generated client for ConfigCat Public Management API vv1
# Source: https://api.apis.guru/v2/specs/configcat.com/v1/openapi.json
# Auth: --token flag or $env.CONFIGCAT_PUBLIC_MANAGEMENT_API_TOKEN

const BASE_URL = "https://api.configcat.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONFIGCAT_PUBLIC_MANAGEMENT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.configcat.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/hal+json" "application/json"] }
def setting-type-completer [] { ["boolean" "double" "int" "string"] }
def access-type-completer [] { ["custom" "full" "readOnly"] }
def new-environment-access-type-completer [] { ["full" "none" "readOnly"] }
def comparator-completer [] { ["contains" "doesNotContain" "isNotOneOf" "isOneOf" "numberDoesNotEqual" "numberEquals" "numberGreater" "numberGreaterOrEquals" "numberLess" "numberLessOrEquals" "semVerGreater" "semVerGreaterOrEquals" "semVerIsNotOneOf" "semVerIsOneOf" "semVerLess" "semVerLessOrEquals" "sensitiveIsNotOneOf" "sensitiveIsOneOf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "code-references create" } } | get name | first)
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

# POST /v1/code-references
#
# --flagReferences item shape: {references: list, settingId: int}
export def "code-references create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-branches: list<string> # The currently active branches of the repository. Each previously uploaded report that belongs to a non-reported active branch is being deleted. (nullable)
  branch: string # The source control branch on where the scan was performed. (Source of the branch selector on the ConfigCat Dashboard)
  --commit-hash: string # The related commit's hash. (Appears on the ConfigCat Dashboard) (nullable)
  --commit-url: string # The related commit's URL. (Appears on the ConfigCat Dashboard) (nullable)
  config_id: string # The Config's identifier the scanning was performed against. (format: uuid)
  --flag-references: list # The actual code reference collection. (nullable) — item shape: {references: list, settingId: int}
  repository: string # The source control repository that contains the scanned code. (Source of the repository selector on the ConfigCat Dashboard)
  --uploader: string # The scanning tool's name. (Appears on the ConfigCat Dashboard) (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/code-references")
  let req_body = {"activeBranches": $active_branches, "branch": $branch, "commitHash": $commit_hash, "commitUrl": $commit_url, "configId": $config_id, "flagReferences": $flag_references, "repository": $repository, "uploader": $uploader} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /v1/code-references/delete-reports
export def "code-references-delete-reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # If it's set, only this branch's reports belonging to the given repository will be deleted. (nullable)
  config_id: string # The Config's identifier from where the reports should be deleted. (format: uuid)
  repository: string # The source control repository which's reports should be deleted.
  --setting-id: int # If it's set, only this setting's reports belonging to the given repository will be deleted. (nullable, format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/code-references/delete-reports")
  let req_body = {"branch": $branch, "configId": $config_id, "repository": $repository, "settingId": $setting_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Config
#
# DELETE /v1/configs/{configId}
# operationId: delete-config
export def "configs delete" [
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id)} | format pattern "/v1/configs/{config_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Config
#
# GET /v1/configs/{configId}
# operationId: get-config
export def "configs get" [
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id)} | format pattern "/v1/configs/{config_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Config
#
# PUT /v1/configs/{configId}
# operationId: update-config
export def "configs update" [
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --name: string # nullable
]: any -> record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id)} | format pattern "/v1/configs/{config_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Deleted Settings
#
# GET /v1/configs/{configId}/deleted-settings
# operationId: get-deleted-settings
export def "configs-deleted-settings get" [
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id)} | format pattern "/v1/configs/{config_id}/deleted-settings"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SDK Key
#
# GET /v1/configs/{configId}/environments/{environmentId}
# operationId: get-sdk-keys
export def "configs-environments get-sdk-keys" [
  config_id: string
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<primary: string, secondary: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id), environment_id: (encode-path-segment $environment_id)} | format pattern "/v1/configs/{config_id}/environments/{environment_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get values
#
# GET /v1/configs/{configId}/environments/{environmentId}/values
# operationId: get-setting-values
export def "configs-environments-values get-setting" [
  config_id: string
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, readOnly: bool, settingValues: table<integrationLinks: list, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, rolloutPercentageItems: list, rolloutRules: list, setting: record, settingTags: list, updatedAt: string, value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id), environment_id: (encode-path-segment $environment_id)} | format pattern "/v1/configs/{config_id}/environments/{environment_id}/values"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Flags
#
# GET /v1/configs/{configId}/settings
# operationId: get-settings
export def "configs-settings get" [
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id)} | format pattern "/v1/configs/{config_id}/settings"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Flag
#
# POST /v1/configs/{configId}/settings
# operationId: create-setting
# --initialValues item shape: {environmentId?: string, value?: any}
export def "configs-settings create" [
  config_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hint: string # A short description for the setting, shown on the Dashboard UI. (nullable)
  --initial-values: list # Optional, initial values of the feature flag or setting in the given Environments. (nullable) — item shape: {environmentId?: string, value?: any}
  key: string # The key of the setting.
  name: string # The name of the setting, shown on the Dashboard UI.
  setting_type: string@setting-type-completer
  --tags: list<int> # The IDs of the tags which are attached to the setting. (nullable)
]: any -> record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({config_id: (encode-path-segment $config_id)} | format pattern "/v1/configs/{config_id}/settings"))
  let req_body = {"hint": $hint, "initialValues": $initial_values, "key": $key, "name": $name, "settingType": $setting_type, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Environment
#
# DELETE /v1/environments/{environmentId}
# operationId: delete-environment
export def "environments delete" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/v1/environments/{environment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Environment
#
# GET /v1/environments/{environmentId}
# operationId: get-environment
export def "environments get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/v1/environments/{environment_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Environment
#
# PUT /v1/environments/{environmentId}
# operationId: update-environment
export def "environments update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --description: string # nullable
  --name: string # nullable
]: any -> record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/v1/environments/{environment_id}"))
  let req_body = {"color": $color, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Integration link
#
# DELETE /v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}
# operationId: delete-integration-link
export def "environments-settings-integration-links delete" [
  environment_id: string
  setting_id: int
  integration_link_type: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<hasRemainingIntegrationLink: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), setting_id: (encode-path-segment $setting_id), integration_link_type: (encode-path-segment $integration_link_type), key: (encode-path-segment $key)} | format pattern "/v1/environments/{environment_id}/settings/{setting_id}/integrationLinks/{integration_link_type}/{key}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add or update Integration link
#
# POST /v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}
# operationId: add-or-update-integration-link
export def "environments-settings-integration-links create-or-update" [
  environment_id: string
  setting_id: int
  integration_link_type: string
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --url: string # nullable
]: any -> record<description: string, integrationLinkType: string, key: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), setting_id: (encode-path-segment $setting_id), integration_link_type: (encode-path-segment $integration_link_type), key: (encode-path-segment $key)} | format pattern "/v1/environments/{environment_id}/settings/{setting_id}/integrationLinks/{integration_link_type}/{key}"))
  let req_body = {"description": $description, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get value
#
# GET /v1/environments/{environmentId}/settings/{settingId}/value
# operationId: get-setting-value
export def "environments-settings-value get" [
  environment_id: string
  setting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), setting_id: (encode-path-segment $setting_id)} | format pattern "/v1/environments/{environment_id}/settings/{setting_id}/value"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update value
#
# PATCH /v1/environments/{environmentId}/settings/{settingId}/value
# operationId: update-setting-value
# --operations item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
export def "environments-settings-value update-by-environmentId-settingId" [
  environment_id: string
  setting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), setting_id: (encode-path-segment $setting_id)} | format pattern "/v1/environments/{environment_id}/settings/{setting_id}/value") $qp)
  let req_body = {"operations": $operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Replace value
#
# PUT /v1/environments/{environmentId}/settings/{settingId}/value
# operationId: replace-setting-value
# --rolloutPercentageItems item shape: {percentage: int, value?: any}
# --rolloutRules item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
export def "environments-settings-value update-by-environmentId-settingId-1" [
  environment_id: string
  setting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --rollout-percentage-items: list # The percentage rule collection. (nullable) — item shape: {percentage: int, value?: any}
  --rollout-rules: list # The targeting rule collection. (nullable) — item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
  --value: any # The value to serve. It must respect the setting type. (nullable)
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), setting_id: (encode-path-segment $setting_id)} | format pattern "/v1/environments/{environment_id}/settings/{setting_id}/value") $qp)
  let req_body = {"rolloutPercentageItems": $rollout_percentage_items, "rolloutRules": $rollout_rules, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get Integration link
#
# GET /v1/integrationLink/{integrationLinkType}/{key}/details
# operationId: get-integration-link-details
export def "integration-link-details get" [
  integration_link_type: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<allIntegrationLinkCount: int, details: table<config: record, environment: record, product: record, readOnly: bool, setting: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({integration_link_type: (encode-path-segment $integration_link_type), key: (encode-path-segment $key)} | format pattern "/v1/integrationLink/{integration_link_type}/{key}/details"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /v1/jira/Connect
export def "jira-connect create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_key: string
  jira_jwt_token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jira/Connect")
  let req_body = {"clientKey": $client_key, "jiraJwtToken": $jira_jwt_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# POST /v1/jira/environments/{environmentId}/settings/{settingId}/integrationLinks/{key}
#
# operationId: jira-add-or-update-integration-link
export def "jira-environments-settings-integration-links create-or-update" [
  environment_id: string
  setting_id: int
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
  --accept: string@accept-completer # Response content type
  client_key: string
  --description: string # nullable
  jira_jwt_token: string
  --url: string # nullable
]: any -> record<description: string, integrationLinkType: string, key: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), setting_id: (encode-path-segment $setting_id), key: (encode-path-segment $key)} | format pattern "/v1/jira/environments/{environment_id}/settings/{setting_id}/integrationLinks/{key}"))
  let req_body = {"clientKey": $client_key, "description": $description, "jiraJwtToken": $jira_jwt_token, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get authenticated user details
#
# GET /v1/me
# operationId: get-me
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, fullName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Organizations
#
# GET /v1/organizations
# operationId: get-organizations
export def "organizations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<name: string, organizationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Audit log items for Organization
#
# GET /v1/organizations/{organizationId}/auditlogs
# operationId: get-organization-auditlogs
export def "organizations-auditlogs get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --product-id: string # The identifier of the Product. (format: uuid)
  --config-id: string # The identifier of the Config. (format: uuid)
  --environment-id: string # The identifier of the Environment. (format: uuid)
  --audit-log-type: string # Filter Audit logs by Audit log type. (nullable)
  --from-utc-date-time: string # Filter Audit logs by starting UTC date. (format: date-time)
  --to-utc-date-time: string # Filter Audit logs by ending UTC date. (format: date-time)
]: nothing -> table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $product_id "scalar") (serialize-qp "configId" $config_id "scalar") (serialize-qp "environmentId" $environment_id "scalar") (serialize-qp "auditLogType" $audit_log_type "scalar") (serialize-qp "fromUtcDateTime" $from_utc_date_time "scalar") (serialize-qp "toUtcDateTime" $to_utc_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/v1/organizations/{organization_id}/auditlogs") $qp)
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Organization Members
#
# GET /v1/organizations/{organizationId}/members
# operationId: get-organization-members
export def "organizations-members get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<email: string, fullName: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/v1/organizations/{organization_id}/members"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Member from Organization
#
# DELETE /v1/organizations/{organizationId}/members/{userId}
# operationId: delete-organization-member
export def "organizations-members delete" [
  organization_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), user_id: (encode-path-segment $user_id)} | format pattern "/v1/organizations/{organization_id}/members/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Member Permissions
#
# POST /v1/organizations/{organizationId}/members/{userId}
# operationId: add-member-to-group
export def "organizations-members create-to-group" [
  organization_id: string
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
  permission_group_ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id), user_id: (encode-path-segment $user_id)} | format pattern "/v1/organizations/{organization_id}/members/{user_id}"))
  let req_body = {"permissionGroupIds": $permission_group_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create Product
#
# POST /v1/organizations/{organizationId}/products
# operationId: create-product
export def "organizations-products create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  name: string
]: any -> record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: (encode-path-segment $organization_id)} | format pattern "/v1/organizations/{organization_id}/products"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Permission Group
#
# DELETE /v1/permissions/{permissionGroupId}
# operationId: delete-permission-group
export def "permissions delete-group" [
  permission_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_group_id: (encode-path-segment $permission_group_id)} | format pattern "/v1/permissions/{permission_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Permission Group
#
# GET /v1/permissions/{permissionGroupId}
# operationId: get-permission-group
export def "permissions get-group" [
  permission_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_group_id: (encode-path-segment $permission_group_id)} | format pattern "/v1/permissions/{permission_group_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Permission Group
#
# PUT /v1/permissions/{permissionGroupId}
# operationId: update-permission-group
# --environmentAccesses item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
export def "permissions update-group" [
  permission_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access-type: string@access-type-completer
  --can-create-or-update-config: oneof<nothing, bool> # nullable
  --can-create-or-update-environment: oneof<nothing, bool> # nullable
  --can-create-or-update-segments: oneof<nothing, bool> # nullable
  --can-create-or-update-setting: oneof<nothing, bool> # nullable
  --can-create-or-update-tag: oneof<nothing, bool> # nullable
  --can-delete-config: oneof<nothing, bool> # nullable
  --can-delete-environment: oneof<nothing, bool> # nullable
  --can-delete-segments: oneof<nothing, bool> # nullable
  --can-delete-setting: oneof<nothing, bool> # nullable
  --can-delete-tag: oneof<nothing, bool> # nullable
  --can-manage-integrations: oneof<nothing, bool> # nullable
  --can-manage-members: oneof<nothing, bool> # nullable
  --can-manage-product-preferences: oneof<nothing, bool> # nullable
  --can-manage-webhook: oneof<nothing, bool> # nullable
  --can-rotate-sdk-key: oneof<nothing, bool> # nullable
  --can-tag-setting: oneof<nothing, bool> # nullable
  --can-use-export-import: oneof<nothing, bool> # nullable
  --can-view-product-audit-log: oneof<nothing, bool> # nullable
  --can-view-product-statistics: oneof<nothing, bool> # nullable
  --can-view-sdk-key: oneof<nothing, bool> # nullable
  --environment-accesses: list # nullable — item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
  --name: string # nullable
  --new-environment-access-type: string@new-environment-access-type-completer
]: any -> record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_group_id: (encode-path-segment $permission_group_id)} | format pattern "/v1/permissions/{permission_group_id}"))
  let req_body = {"accessType": $access_type, "canCreateOrUpdateConfig": $can_create_or_update_config, "canCreateOrUpdateEnvironment": $can_create_or_update_environment, "canCreateOrUpdateSegments": $can_create_or_update_segments, "canCreateOrUpdateSetting": $can_create_or_update_setting, "canCreateOrUpdateTag": $can_create_or_update_tag, "canDeleteConfig": $can_delete_config, "canDeleteEnvironment": $can_delete_environment, "canDeleteSegments": $can_delete_segments, "canDeleteSetting": $can_delete_setting, "canDeleteTag": $can_delete_tag, "canManageIntegrations": $can_manage_integrations, "canManageMembers": $can_manage_members, "canManageProductPreferences": $can_manage_product_preferences, "canManageWebhook": $can_manage_webhook, "canRotateSdkKey": $can_rotate_sdk_key, "canTagSetting": $can_tag_setting, "canUseExportImport": $can_use_export_import, "canViewProductAuditLog": $can_view_product_audit_log, "canViewProductStatistics": $can_view_product_statistics, "canViewSdkKey": $can_view_sdk_key, "environmentAccesses": $environment_accesses, "name": $name, "newEnvironmentAccessType": $new_environment_access_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Products
#
# GET /v1/products
# operationId: get-products
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Product
#
# DELETE /v1/products/{productId}
# operationId: delete-product
export def "products delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product
#
# GET /v1/products/{productId}
# operationId: get-product
export def "products get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Product
#
# PUT /v1/products/{productId}
# operationId: update-product
export def "products update" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --name: string # nullable
]: any -> record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Audit log items for Product
#
# GET /v1/products/{productId}/auditlogs
# operationId: get-auditlogs
export def "products-auditlogs get" [
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
  --accept: string@accept-completer # Response content type
  --config-id: string # The identifier of the Config. (format: uuid)
  --environment-id: string # The identifier of the Environment. (format: uuid)
  --audit-log-type: string # Filter Audit logs by Audit log type. (nullable)
  --from-utc-date-time: string # Filter Audit logs by starting UTC date. (format: date-time)
  --to-utc-date-time: string # Filter Audit logs by ending UTC date. (format: date-time)
]: nothing -> table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configId" $config_id "scalar") (serialize-qp "environmentId" $environment_id "scalar") (serialize-qp "auditLogType" $audit_log_type "scalar") (serialize-qp "fromUtcDateTime" $from_utc_date_time "scalar") (serialize-qp "toUtcDateTime" $to_utc_date_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/auditlogs") $qp)
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Configs
#
# GET /v1/products/{productId}/configs
# operationId: get-configs
export def "products-configs get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/configs"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Config
#
# POST /v1/products/{productId}/configs
# operationId: create-config
export def "products-configs create" [
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
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  name: string
]: any -> record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/configs"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Environments
#
# GET /v1/products/{productId}/environments
# operationId: get-environments
export def "products-environments get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/environments"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Environment
#
# POST /v1/products/{productId}/environments
# operationId: create-environment
export def "products-environments create" [
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
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --description: string # nullable
  name: string
]: any -> record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/environments"))
  let req_body = {"color": $color, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Product Members
#
# GET /v1/products/{productId}/members
# operationId: get-product-members
export def "products-members get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<email: string, fullName: string, permissionGroupId: int, productId: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/members"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Invite Member
#
# POST /v1/products/{productId}/members/invite
# operationId: invite-member
export def "products-members-invite create" [
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
  emails: list<string>
  permission_group_id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/members/invite"))
  let req_body = {"emails": $emails, "permissionGroupId": $permission_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Member from Product
#
# DELETE /v1/products/{productId}/members/{userId}
# operationId: delete-product-member
export def "products-members delete" [
  product_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), user_id: (encode-path-segment $user_id)} | format pattern "/v1/products/{product_id}/members/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Permission Groups
#
# GET /v1/products/{productId}/permissions
# operationId: get-permission-groups
export def "products-permissions get-groups" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: list<record>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/permissions"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Permission Group
#
# POST /v1/products/{productId}/permissions
# operationId: create-permission-group
# --environmentAccesses item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
export def "products-permissions create-group" [
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
  --accept: string@accept-completer # Response content type
  --access-type: string@access-type-completer
  --can-create-or-update-config: oneof<nothing, bool>
  --can-create-or-update-environment: oneof<nothing, bool>
  --can-create-or-update-segments: oneof<nothing, bool>
  --can-create-or-update-setting: oneof<nothing, bool>
  --can-create-or-update-tag: oneof<nothing, bool>
  --can-delete-config: oneof<nothing, bool>
  --can-delete-environment: oneof<nothing, bool>
  --can-delete-segments: oneof<nothing, bool>
  --can-delete-setting: oneof<nothing, bool>
  --can-delete-tag: oneof<nothing, bool>
  --can-manage-integrations: oneof<nothing, bool>
  --can-manage-members: oneof<nothing, bool>
  --can-manage-product-preferences: oneof<nothing, bool>
  --can-manage-webhook: oneof<nothing, bool>
  --can-rotate-sdk-key: oneof<nothing, bool>
  --can-tag-setting: oneof<nothing, bool>
  --can-use-export-import: oneof<nothing, bool>
  --can-view-product-audit-log: oneof<nothing, bool>
  --can-view-product-statistics: oneof<nothing, bool>
  --can-view-sdk-key: oneof<nothing, bool>
  --environment-accesses: list # nullable — item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
  name: string
  --new-environment-access-type: string@new-environment-access-type-completer
]: any -> record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/permissions"))
  let req_body = {"accessType": $access_type, "canCreateOrUpdateConfig": $can_create_or_update_config, "canCreateOrUpdateEnvironment": $can_create_or_update_environment, "canCreateOrUpdateSegments": $can_create_or_update_segments, "canCreateOrUpdateSetting": $can_create_or_update_setting, "canCreateOrUpdateTag": $can_create_or_update_tag, "canDeleteConfig": $can_delete_config, "canDeleteEnvironment": $can_delete_environment, "canDeleteSegments": $can_delete_segments, "canDeleteSetting": $can_delete_setting, "canDeleteTag": $can_delete_tag, "canManageIntegrations": $can_manage_integrations, "canManageMembers": $can_manage_members, "canManageProductPreferences": $can_manage_product_preferences, "canManageWebhook": $can_manage_webhook, "canRotateSdkKey": $can_rotate_sdk_key, "canTagSetting": $can_tag_setting, "canUseExportImport": $can_use_export_import, "canViewProductAuditLog": $can_view_product_audit_log, "canViewProductStatistics": $can_view_product_statistics, "canViewSdkKey": $can_view_sdk_key, "environmentAccesses": $environment_accesses, "name": $name, "newEnvironmentAccessType": $new_environment_access_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Segments
#
# GET /v1/products/{productId}/segments
# operationId: get-segments
export def "products-segments get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string, usage: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/segments"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Segment
#
# POST /v1/products/{productId}/segments
# operationId: create-segment
export def "products-segments create" [
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
  --accept: string@accept-completer # Response content type
  comparator: string@comparator-completer
  comparison_attribute: string
  comparison_value: string
  --description: string # nullable
  name: string
]: any -> record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/segments"))
  let req_body = {"comparator": $comparator, "comparisonAttribute": $comparison_attribute, "comparisonValue": $comparison_value, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Tags
#
# GET /v1/products/{productId}/tags
# operationId: get-tags
export def "products-tags get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<color: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, tagId: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/tags"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Tag
#
# POST /v1/products/{productId}/tags
# operationId: create-tag
export def "products-tags create" [
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
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  name: string
]: any -> record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/v1/products/{product_id}/tags"))
  let req_body = {"color": $color, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Segment
#
# DELETE /v1/segments/{segmentId}
# operationId: delete-segment
export def "segments delete" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/segments/{segment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Segment
#
# GET /v1/segments/{segmentId}
# operationId: get-segment
export def "segments get" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/segments/{segment_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Segment
#
# PUT /v1/segments/{segmentId}
# operationId: update-segment
export def "segments update" [
  segment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comparator: string@comparator-completer
  --comparison-attribute: string # nullable
  --comparison-value: string # nullable
  --description: string # nullable
  --name: string # nullable
]: any -> record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({segment_id: (encode-path-segment $segment_id)} | format pattern "/v1/segments/{segment_id}"))
  let req_body = {"comparator": $comparator, "comparisonAttribute": $comparison_attribute, "comparisonValue": $comparison_value, "description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Flag
#
# DELETE /v1/settings/{settingId}
# operationId: delete-setting
export def "settings delete" [
  setting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({setting_id: (encode-path-segment $setting_id)} | format pattern "/v1/settings/{setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Flag
#
# GET /v1/settings/{settingId}
# operationId: get-setting
export def "settings get" [
  setting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({setting_id: (encode-path-segment $setting_id)} | format pattern "/v1/settings/{setting_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Flag
#
# PATCH /v1/settings/{settingId}
# operationId: update-setting
# --operations item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
export def "settings update" [
  setting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({setting_id: (encode-path-segment $setting_id)} | format pattern "/v1/settings/{setting_id}"))
  let req_body = {"operations": $operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get value
#
# GET /v1/settings/{settingKeyOrId}/value
# operationId: get-setting-value-by-sdkkey
export def "settings-value get-by-sdkkey" [
  setting_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-configcat-sdkkey: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
]: nothing -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({setting_key_or_id: (encode-path-segment $setting_key_or_id)} | format pattern "/v1/settings/{setting_key_or_id}/value"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-CONFIGCAT-SDKKEY": $x_configcat_sdkkey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update value
#
# PATCH /v1/settings/{settingKeyOrId}/value
# operationId: update-setting-value-by-sdkkey
# --operations item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
export def "settings-value update-by-sdkkey-by-settingKeyOrId" [
  setting_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --x-configcat-sdkkey: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({setting_key_or_id: (encode-path-segment $setting_key_or_id)} | format pattern "/v1/settings/{setting_key_or_id}/value") $qp)
  let req_body = {"operations": $operations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-CONFIGCAT-SDKKEY": $x_configcat_sdkkey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Replace value
#
# PUT /v1/settings/{settingKeyOrId}/value
# operationId: replace-setting-value-by-sdkkey
# --rolloutPercentageItems item shape: {percentage: int, value?: any}
# --rolloutRules item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
export def "settings-value update-by-sdkkey-by-settingKeyOrId-1" [
  setting_key_or_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --x-configcat-sdkkey: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
  --rollout-percentage-items: list # The percentage rule collection. (nullable) — item shape: {percentage: int, value?: any}
  --rollout-rules: list # The targeting rule collection. (nullable) — item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
  --value: any # The value to serve. It must respect the setting type. (nullable)
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({setting_key_or_id: (encode-path-segment $setting_key_or_id)} | format pattern "/v1/settings/{setting_key_or_id}/value") $qp)
  let req_body = {"rolloutPercentageItems": $rollout_percentage_items, "rolloutRules": $rollout_rules, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-CONFIGCAT-SDKKEY": $x_configcat_sdkkey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Tag
#
# DELETE /v1/tags/{tagId}
# operationId: delete-tag
export def "tags delete" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v1/tags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Tag
#
# GET /v1/tags/{tagId}
# operationId: get-tag
export def "tags get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v1/tags/{tag_id}"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Tag
#
# PUT /v1/tags/{tagId}
# operationId: update-tag
export def "tags update" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --name: string # nullable
]: any -> record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v1/tags/{tag_id}"))
  let req_body = {"color": $color, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List Settings by Tag
#
# GET /v1/tags/{tagId}/settings
# operationId: get-settings-by-tag
export def "tags-settings get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/v1/tags/{tag_id}/settings"))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
