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

def base-url-completer [] { ["https://api.configcat.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def accept-completer [] { ["application/hal+json" "application/json"] }
def settingType-completer [] { ["boolean" "double" "int" "string"] }
def accessType-completer [] { ["custom" "full" "readOnly"] }
def newEnvironmentAccessType-completer [] { ["full" "none" "readOnly"] }
def comparator-completer [] { ["contains" "doesNotContain" "isNotOneOf" "isOneOf" "numberDoesNotEqual" "numberEquals" "numberGreater" "numberGreaterOrEquals" "numberLess" "numberLessOrEquals" "semVerGreater" "semVerGreaterOrEquals" "semVerIsNotOneOf" "semVerIsOneOf" "semVerLess" "semVerLessOrEquals" "sensitiveIsNotOneOf" "sensitiveIsOneOf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "code-references post" } } | get name | first)
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
export def "code-references post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activeBranches: list # The currently active branches of the repository. Each previously uploaded report that belongs to a non-reported active branch is being deleted. (nullable)
  branch: string # The source control branch on where the scan was performed. (Source of the branch selector on the ConfigCat Dashboard)
  --commitHash: string # The related commit's hash. (Appears on the ConfigCat Dashboard) (nullable)
  --commitUrl: string # The related commit's URL. (Appears on the ConfigCat Dashboard) (nullable)
  configId: string # The Config's identifier the scanning was performed against. (format: uuid)
  --flagReferences: list # The actual code reference collection. (nullable) — item shape: {references: list, settingId: int}
  repository: string # The source control repository that contains the scanned code. (Source of the repository selector on the ConfigCat Dashboard)
  --uploader: string # The scanning tool's name. (Appears on the ConfigCat Dashboard) (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/code-references")
  let body = {activeBranches: $activeBranches, branch: $branch, commitHash: $commitHash, commitUrl: $commitUrl, configId: $configId, flagReferences: $flagReferences, repository: $repository, uploader: $uploader} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/code-references/delete-reports
export def "code-references-delete-reports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch: string # If it's set, only this branch's reports belonging to the given repository will be deleted. (nullable)
  configId: string # The Config's identifier from where the reports should be deleted. (format: uuid)
  repository: string # The source control repository which's reports should be deleted.
  --settingId: int # If it's set, only this setting's reports belonging to the given repository will be deleted. (nullable, format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/code-references/delete-reports")
  let body = {branch: $branch, configId: $configId, repository: $repository, settingId: $settingId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Config
#
# DELETE /v1/configs/{configId}
# operationId: delete-config
export def "configs delete-config" [
  configId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Config
#
# GET /v1/configs/{configId}
# operationId: get-config
export def "configs get-config" [
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Config
#
# PUT /v1/configs/{configId}
# operationId: update-config
export def "configs update-config" [
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --name: string # nullable
]: any -> record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Deleted Settings
#
# GET /v1/configs/{configId}/deleted-settings
# operationId: get-deleted-settings
export def "configs-deleted-settings get-deleted-settings" [
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)/deleted-settings")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SDK Key
#
# GET /v1/configs/{configId}/environments/{environmentId}
# operationId: get-sdk-keys
export def "configs-environments get-sdk-keys" [
  configId: string
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<primary: string, secondary: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)/environments/($environmentId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get values
#
# GET /v1/configs/{configId}/environments/{environmentId}/values
# operationId: get-setting-values
export def "configs-environments-values get-setting-values" [
  configId: string
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, readOnly: bool, settingValues: table<integrationLinks: list, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, rolloutPercentageItems: list, rolloutRules: list, setting: record, settingTags: list, updatedAt: string, value: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)/environments/($environmentId)/values")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Flags
#
# GET /v1/configs/{configId}/settings
# operationId: get-settings
export def "configs-settings get-settings" [
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)/settings")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Flag
#
# POST /v1/configs/{configId}/settings
# operationId: create-setting
# --initialValues item shape: {environmentId?: string, value?: any}
export def "configs-settings create-setting" [
  configId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hint: string # A short description for the setting, shown on the Dashboard UI. (nullable)
  --initialValues: list # Optional, initial values of the feature flag or setting in the given Environments. (nullable) — item shape: {environmentId?: string, value?: any}
  key: string # The key of the setting.
  name: string # The name of the setting, shown on the Dashboard UI.
  settingType: string@settingType-completer
  --tags: list # The IDs of the tags which are attached to the setting. (nullable)
]: any -> record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/configs/($configId)/settings")
  let body = {hint: $hint, initialValues: $initialValues, key: $key, name: $name, settingType: $settingType, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Environment
#
# DELETE /v1/environments/{environmentId}
# operationId: delete-environment
export def "environments delete-environment" [
  environmentId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Environment
#
# GET /v1/environments/{environmentId}
# operationId: get-environment
export def "environments get-environment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Environment
#
# PUT /v1/environments/{environmentId}
# operationId: update-environment
export def "environments update-environment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --description: string # nullable
  --name: string # nullable
]: any -> record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)")
  let body = {color: $color, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Integration link
#
# DELETE /v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}
# operationId: delete-integration-link
export def "environments-settings-integration-links delete-integration-link" [
  environmentId: string
  settingId: int
  integrationLinkType: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<hasRemainingIntegrationLink: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)/settings/($settingId)/integrationLinks/($integrationLinkType)/($key)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or update Integration link
#
# POST /v1/environments/{environmentId}/settings/{settingId}/integrationLinks/{integrationLinkType}/{key}
# operationId: add-or-update-integration-link
export def "environments-settings-integration-links add-or-update-integration-link" [
  environmentId: string
  settingId: int
  integrationLinkType: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --body-url: string # nullable
]: any -> record<description: string, integrationLinkType: string, key: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)/settings/($settingId)/integrationLinks/($integrationLinkType)/($key)")
  let body = {description: $description, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get value
#
# GET /v1/environments/{environmentId}/settings/{settingId}/value
# operationId: get-setting-value
export def "environments-settings-value get-setting-value" [
  environmentId: string
  settingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)/settings/($settingId)/value")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update value
#
# PATCH /v1/environments/{environmentId}/settings/{settingId}/value
# operationId: update-setting-value
# --operations item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
export def "environments-settings-value update-setting-value" [
  environmentId: string
  settingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/environments/($environmentId)/settings/($settingId)/value" $qp)
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace value
#
# PUT /v1/environments/{environmentId}/settings/{settingId}/value
# operationId: replace-setting-value
# --rolloutPercentageItems item shape: {percentage: int, value?: any}
# --rolloutRules item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
export def "environments-settings-value replace-setting-value" [
  environmentId: string
  settingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --rolloutPercentageItems: list # The percentage rule collection. (nullable) — item shape: {percentage: int, value?: any}
  --rolloutRules: list # The targeting rule collection. (nullable) — item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
  --value: any # The value to serve. It must respect the setting type. (nullable)
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/environments/($environmentId)/settings/($settingId)/value" $qp)
  let body = {rolloutPercentageItems: $rolloutPercentageItems, rolloutRules: $rolloutRules, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Integration link
#
# GET /v1/integrationLink/{integrationLinkType}/{key}/details
# operationId: get-integration-link-details
export def "integration-link-details get-integration-link-details" [
  integrationLinkType: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<allIntegrationLinkCount: int, details: table<config: record, environment: record, product: record, readOnly: bool, setting: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrationLink/($integrationLinkType)/($key)/details")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/jira/Connect
export def "jira-connect post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  clientKey: string
  jiraJwtToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/jira/Connect")
  let body = {clientKey: $clientKey, jiraJwtToken: $jiraJwtToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/jira/environments/{environmentId}/settings/{settingId}/integrationLinks/{key}
#
# operationId: jira-add-or-update-integration-link
export def "jira-environments-settings-integration-links jira-add-or-update-integration-link" [
  environmentId: string
  settingId: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  clientKey: string
  --description: string # nullable
  jiraJwtToken: string
  --body-url: string # nullable
]: any -> record<description: string, integrationLinkType: string, key: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/jira/environments/($environmentId)/settings/($settingId)/integrationLinks/($key)")
  let body = {clientKey: $clientKey, description: $description, jiraJwtToken: $jiraJwtToken, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get authenticated user details
#
# GET /v1/me
# operationId: get-me
export def "me get-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<email: string, fullName: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/me")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Organizations
#
# GET /v1/organizations
# operationId: get-organizations
export def "organizations get-organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<name: string, organizationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/organizations")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Audit log items for Organization
#
# GET /v1/organizations/{organizationId}/auditlogs
# operationId: get-organization-auditlogs
export def "organizations-auditlogs get-organization-auditlogs" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --productId: string # The identifier of the Product. (format: uuid)
  --configId: string # The identifier of the Config. (format: uuid)
  --environmentId: string # The identifier of the Environment. (format: uuid)
  --auditLogType: string # Filter Audit logs by Audit log type. (nullable)
  --fromUtcDateTime: string # Filter Audit logs by starting UTC date. (format: date-time)
  --toUtcDateTime: string # Filter Audit logs by ending UTC date. (format: date-time)
]: nothing -> table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "configId" $configId "scalar") (serialize-qp "environmentId" $environmentId "scalar") (serialize-qp "auditLogType" $auditLogType "scalar") (serialize-qp "fromUtcDateTime" $fromUtcDateTime "scalar") (serialize-qp "toUtcDateTime" $toUtcDateTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/organizations/($organizationId)/auditlogs" $qp)
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Organization Members
#
# GET /v1/organizations/{organizationId}/members
# operationId: get-organization-members
export def "organizations-members get-organization-members" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<email: string, fullName: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationId)/members")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Member from Organization
#
# DELETE /v1/organizations/{organizationId}/members/{userId}
# operationId: delete-organization-member
export def "organizations-members delete-organization-member" [
  organizationId: string
  userId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationId)/members/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Member Permissions
#
# POST /v1/organizations/{organizationId}/members/{userId}
# operationId: add-member-to-group
export def "organizations-members add-member-to-group" [
  organizationId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permissionGroupIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationId)/members/($userId)")
  let body = {permissionGroupIds: $permissionGroupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Product
#
# POST /v1/organizations/{organizationId}/products
# operationId: create-product
export def "organizations-products create-product" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  name: string
]: any -> record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/organizations/($organizationId)/products")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Permission Group
#
# DELETE /v1/permissions/{permissionGroupId}
# operationId: delete-permission-group
export def "permissions delete-permission-group" [
  permissionGroupId: int
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/permissions/($permissionGroupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Permission Group
#
# GET /v1/permissions/{permissionGroupId}
# operationId: get-permission-group
export def "permissions get-permission-group" [
  permissionGroupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/permissions/($permissionGroupId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Permission Group
#
# PUT /v1/permissions/{permissionGroupId}
# operationId: update-permission-group
# --environmentAccesses item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
export def "permissions update-permission-group" [
  permissionGroupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accessType: string@accessType-completer
  --canCreateOrUpdateConfig: oneof<nothing, bool> # nullable
  --canCreateOrUpdateEnvironment: oneof<nothing, bool> # nullable
  --canCreateOrUpdateSegments: oneof<nothing, bool> # nullable
  --canCreateOrUpdateSetting: oneof<nothing, bool> # nullable
  --canCreateOrUpdateTag: oneof<nothing, bool> # nullable
  --canDeleteConfig: oneof<nothing, bool> # nullable
  --canDeleteEnvironment: oneof<nothing, bool> # nullable
  --canDeleteSegments: oneof<nothing, bool> # nullable
  --canDeleteSetting: oneof<nothing, bool> # nullable
  --canDeleteTag: oneof<nothing, bool> # nullable
  --canManageIntegrations: oneof<nothing, bool> # nullable
  --canManageMembers: oneof<nothing, bool> # nullable
  --canManageProductPreferences: oneof<nothing, bool> # nullable
  --canManageWebhook: oneof<nothing, bool> # nullable
  --canRotateSdkKey: oneof<nothing, bool> # nullable
  --canTagSetting: oneof<nothing, bool> # nullable
  --canUseExportImport: oneof<nothing, bool> # nullable
  --canViewProductAuditLog: oneof<nothing, bool> # nullable
  --canViewProductStatistics: oneof<nothing, bool> # nullable
  --canViewSdkKey: oneof<nothing, bool> # nullable
  --environmentAccesses: list # nullable — item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
  --name: string # nullable
  --newEnvironmentAccessType: string@newEnvironmentAccessType-completer
]: any -> record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/permissions/($permissionGroupId)")
  let body = {accessType: $accessType, canCreateOrUpdateConfig: $canCreateOrUpdateConfig, canCreateOrUpdateEnvironment: $canCreateOrUpdateEnvironment, canCreateOrUpdateSegments: $canCreateOrUpdateSegments, canCreateOrUpdateSetting: $canCreateOrUpdateSetting, canCreateOrUpdateTag: $canCreateOrUpdateTag, canDeleteConfig: $canDeleteConfig, canDeleteEnvironment: $canDeleteEnvironment, canDeleteSegments: $canDeleteSegments, canDeleteSetting: $canDeleteSetting, canDeleteTag: $canDeleteTag, canManageIntegrations: $canManageIntegrations, canManageMembers: $canManageMembers, canManageProductPreferences: $canManageProductPreferences, canManageWebhook: $canManageWebhook, canRotateSdkKey: $canRotateSdkKey, canTagSetting: $canTagSetting, canUseExportImport: $canUseExportImport, canViewProductAuditLog: $canViewProductAuditLog, canViewProductStatistics: $canViewProductStatistics, canViewSdkKey: $canViewSdkKey, environmentAccesses: $environmentAccesses, name: $name, newEnvironmentAccessType: $newEnvironmentAccessType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Products
#
# GET /v1/products
# operationId: get-products
export def "products get-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Product
#
# DELETE /v1/products/{productId}
# operationId: delete-product
export def "products delete-product" [
  productId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product
#
# GET /v1/products/{productId}
# operationId: get-product
export def "products get-product" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Product
#
# PUT /v1/products/{productId}
# operationId: update-product
export def "products update-product" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --name: string # nullable
]: any -> record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Audit log items for Product
#
# GET /v1/products/{productId}/auditlogs
# operationId: get-auditlogs
export def "products-auditlogs get-auditlogs" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --configId: string # The identifier of the Config. (format: uuid)
  --environmentId: string # The identifier of the Environment. (format: uuid)
  --auditLogType: string # Filter Audit logs by Audit log type. (nullable)
  --fromUtcDateTime: string # Filter Audit logs by starting UTC date. (format: date-time)
  --toUtcDateTime: string # Filter Audit logs by ending UTC date. (format: date-time)
]: nothing -> table<actionTarget: string, auditLogDateTime: string, auditLogId: int, auditLogType: string, auditLogTypeEnum: string, details: string, userEmail: string, userName: string, where: string, why: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configId" $configId "scalar") (serialize-qp "environmentId" $environmentId "scalar") (serialize-qp "auditLogType" $auditLogType "scalar") (serialize-qp "fromUtcDateTime" $fromUtcDateTime "scalar") (serialize-qp "toUtcDateTime" $toUtcDateTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/products/($productId)/auditlogs" $qp)
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Configs
#
# GET /v1/products/{productId}/configs
# operationId: get-configs
export def "products-configs get-configs" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/configs")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Config
#
# POST /v1/products/{productId}/configs
# operationId: create-config
export def "products-configs create-config" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  name: string
]: any -> record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/configs")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Environments
#
# GET /v1/products/{productId}/environments
# operationId: get-environments
export def "products-environments get-environments" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/environments")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Environment
#
# POST /v1/products/{productId}/environments
# operationId: create-environment
export def "products-environments create-environment" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --description: string # nullable
  name: string
]: any -> record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, reasonRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/environments")
  let body = {color: $color, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Product Members
#
# GET /v1/products/{productId}/members
# operationId: get-product-members
export def "products-members get-product-members" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<email: string, fullName: string, permissionGroupId: int, productId: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/members")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite Member
#
# POST /v1/products/{productId}/members/invite
# operationId: invite-member
export def "products-members-invite invite-member" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emails: list
  permissionGroupId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/members/invite")
  let body = {emails: $emails, permissionGroupId: $permissionGroupId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Member from Product
#
# DELETE /v1/products/{productId}/members/{userId}
# operationId: delete-product-member
export def "products-members delete-product-member" [
  productId: string
  userId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/members/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Permission Groups
#
# GET /v1/products/{productId}/permissions
# operationId: get-permission-groups
export def "products-permissions get-permission-groups" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: list<record>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/permissions")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Permission Group
#
# POST /v1/products/{productId}/permissions
# operationId: create-permission-group
# --environmentAccesses item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
export def "products-permissions create-permission-group" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accessType: string@accessType-completer
  --canCreateOrUpdateConfig: oneof<nothing, bool>
  --canCreateOrUpdateEnvironment: oneof<nothing, bool>
  --canCreateOrUpdateSegments: oneof<nothing, bool>
  --canCreateOrUpdateSetting: oneof<nothing, bool>
  --canCreateOrUpdateTag: oneof<nothing, bool>
  --canDeleteConfig: oneof<nothing, bool>
  --canDeleteEnvironment: oneof<nothing, bool>
  --canDeleteSegments: oneof<nothing, bool>
  --canDeleteSetting: oneof<nothing, bool>
  --canDeleteTag: oneof<nothing, bool>
  --canManageIntegrations: oneof<nothing, bool>
  --canManageMembers: oneof<nothing, bool>
  --canManageProductPreferences: oneof<nothing, bool>
  --canManageWebhook: oneof<nothing, bool>
  --canRotateSdkKey: oneof<nothing, bool>
  --canTagSetting: oneof<nothing, bool>
  --canUseExportImport: oneof<nothing, bool>
  --canViewProductAuditLog: oneof<nothing, bool>
  --canViewProductStatistics: oneof<nothing, bool>
  --canViewSdkKey: oneof<nothing, bool>
  --environmentAccesses: list # nullable — item shape: {color?: string, description?: string, environmentAccessType?: "full"|"readOnly"|"none", environmentId?: string, name?: string, order?: int, reasonRequired?: bool}
  name: string
  --newEnvironmentAccessType: string@newEnvironmentAccessType-completer
]: any -> record<accessType: string, canCreateOrUpdateConfig: bool, canCreateOrUpdateEnvironment: bool, canCreateOrUpdateSegments: bool, canCreateOrUpdateSetting: bool, canCreateOrUpdateTag: bool, canDeleteConfig: bool, canDeleteEnvironment: bool, canDeleteSegments: bool, canDeleteSetting: bool, canDeleteTag: bool, canManageIntegrations: bool, canManageMembers: bool, canManageProductPreferences: bool, canManageWebhook: bool, canRotateSdkKey: bool, canTagSetting: bool, canUseExportImport: bool, canViewProductAuditLog: bool, canViewProductStatistics: bool, canViewSdkKey: bool, environmentAccesses: table<color: string, description: string, environmentAccessType: string, environmentId: string, name: string, order: int, reasonRequired: bool>, name: string, newEnvironmentAccessType: string, permissionGroupId: int, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/permissions")
  let body = {accessType: $accessType, canCreateOrUpdateConfig: $canCreateOrUpdateConfig, canCreateOrUpdateEnvironment: $canCreateOrUpdateEnvironment, canCreateOrUpdateSegments: $canCreateOrUpdateSegments, canCreateOrUpdateSetting: $canCreateOrUpdateSetting, canCreateOrUpdateTag: $canCreateOrUpdateTag, canDeleteConfig: $canDeleteConfig, canDeleteEnvironment: $canDeleteEnvironment, canDeleteSegments: $canDeleteSegments, canDeleteSetting: $canDeleteSetting, canDeleteTag: $canDeleteTag, canManageIntegrations: $canManageIntegrations, canManageMembers: $canManageMembers, canManageProductPreferences: $canManageProductPreferences, canManageWebhook: $canManageWebhook, canRotateSdkKey: $canRotateSdkKey, canTagSetting: $canTagSetting, canUseExportImport: $canUseExportImport, canViewProductAuditLog: $canViewProductAuditLog, canViewProductStatistics: $canViewProductStatistics, canViewSdkKey: $canViewSdkKey, environmentAccesses: $environmentAccesses, name: $name, newEnvironmentAccessType: $newEnvironmentAccessType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Segments
#
# GET /v1/products/{productId}/segments
# operationId: get-segments
export def "products-segments get-segments" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string, usage: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/segments")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Segment
#
# POST /v1/products/{productId}/segments
# operationId: create-segment
export def "products-segments create-segment" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  comparator: string@comparator-completer
  comparisonAttribute: string
  comparisonValue: string
  --description: string # nullable
  name: string
]: any -> record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/segments")
  let body = {comparator: $comparator, comparisonAttribute: $comparisonAttribute, comparisonValue: $comparisonValue, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Tags
#
# GET /v1/products/{productId}/tags
# operationId: get-tags
export def "products-tags get-tags" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<color: string, name: string, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, tagId: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/tags")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Tag
#
# POST /v1/products/{productId}/tags
# operationId: create-tag
export def "products-tags create-tag" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  name: string
]: any -> record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($productId)/tags")
  let body = {color: $color, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Segment
#
# DELETE /v1/segments/{segmentId}
# operationId: delete-segment
export def "segments delete-segment" [
  segmentId: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/segments/($segmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Segment
#
# GET /v1/segments/{segmentId}
# operationId: get-segment
export def "segments get-segment" [
  segmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/segments/($segmentId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Segment
#
# PUT /v1/segments/{segmentId}
# operationId: update-segment
export def "segments update-segment" [
  segmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comparator: string@comparator-completer
  --comparisonAttribute: string # nullable
  --comparisonValue: string # nullable
  --description: string # nullable
  --name: string # nullable
]: any -> record<comparator: string, comparisonAttribute: string, comparisonValue: string, createdAt: string, creatorEmail: string, creatorFullName: string, description: string, lastUpdaterEmail: string, lastUpdaterFullName: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, segmentId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/segments/($segmentId)")
  let body = {comparator: $comparator, comparisonAttribute: $comparisonAttribute, comparisonValue: $comparisonValue, description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Flag
#
# DELETE /v1/settings/{settingId}
# operationId: delete-setting
export def "settings delete-setting" [
  settingId: int
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/settings/($settingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flag
#
# GET /v1/settings/{settingId}
# operationId: get-setting
export def "settings get-setting" [
  settingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/settings/($settingId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Flag
#
# PATCH /v1/settings/{settingId}
# operationId: update-setting
# --operations item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
export def "settings update-setting" [
  settingId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> record<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: table<color: string, name: string, product: record, tagId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/settings/($settingId)")
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get value
#
# GET /v1/settings/{settingKeyOrId}/value
# operationId: get-setting-value-by-sdkkey
export def "settings-value get-setting-value-by-sdkkey" [
  settingKeyOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --X-CONFIGCAT-SDKKEY: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
]: nothing -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/settings/($settingKeyOrId)/value")
  let extra_headers = {"X-CONFIGCAT-SDKKEY": $X_CONFIGCAT_SDKKEY} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update value
#
# PATCH /v1/settings/{settingKeyOrId}/value
# operationId: update-setting-value-by-sdkkey
# --operations item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
export def "settings-value update-setting-value-by-sdkkey" [
  settingKeyOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --X-CONFIGCAT-SDKKEY: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
  --operations: list # nullable — item shape: {from?: record, op?: "unknown"|"add"|"remove"|"replace"|"move"|"copy"|"test", path?: record, value?: record}
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/settings/($settingKeyOrId)/value" $qp)
  let body = {operations: $operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-CONFIGCAT-SDKKEY": $X_CONFIGCAT_SDKKEY} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace value
#
# PUT /v1/settings/{settingKeyOrId}/value
# operationId: replace-setting-value-by-sdkkey
# --rolloutPercentageItems item shape: {percentage: int, value?: any}
# --rolloutRules item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
export def "settings-value replace-setting-value-by-sdkkey" [
  settingKeyOrId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # The reason note for the Audit Log if the Product's "Config changes require a reason" preference is turned on.
  --X-CONFIGCAT-SDKKEY: string # The ConfigCat SDK Key. (https://app.configcat.com/sdkkey)
  --rolloutPercentageItems: list # The percentage rule collection. (nullable) — item shape: {percentage: int, value?: any}
  --rolloutRules: list # The targeting rule collection. (nullable) — item shape: {comparator?: "isOneOf"|"isNotOneOf"|"contains"|"doesNotContain"|"semVerIsOneOf"|"semVerIsNotOneOf"|"semVerLess"|"semVerLessOrEquals"|"semVerGreater"|"semVerGreaterOrEquals"|"numberEquals"|"numberDoesNotEqual"|"numberLess"|"numberLessOrEquals"|"numberGreater"|"numberGreaterOrEquals"|"sensitiveIsOneOf"|"sensitiveIsNotOneOf", comparisonAttribute?: string, comparisonValue?: string, segmentComparator?: "isIn"|"isNotIn", segmentId?: string, value?: any}
  --value: any # The value to serve. It must respect the setting type. (nullable)
]: any -> record<config: record<configId: string, description: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>>, environment: record<color: string, description: string, environmentId: string, name: string, order: int, product: record<description: string, name: string, order: int, organization: record, productId: string, reasonRequired: bool>, reasonRequired: bool>, integrationLinks: table<description: string, integrationLinkType: string, key: string, url: string>, lastUpdaterUserEmail: string, lastUpdaterUserFullName: string, readOnly: bool, rolloutPercentageItems: table<percentage: int, value: any>, rolloutRules: table<comparator: string, comparisonAttribute: string, comparisonValue: string, segmentComparator: string, segmentId: string, value: any>, setting: record<createdAt: string, creatorEmail: string, creatorFullName: string, hint: string, isWatching: bool, key: string, name: string, order: int, settingId: int, settingType: string>, settingTags: table<color: string, name: string, settingTagId: int, tagId: int>, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/settings/($settingKeyOrId)/value" $qp)
  let body = {rolloutPercentageItems: $rolloutPercentageItems, rolloutRules: $rolloutRules, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-CONFIGCAT-SDKKEY": $X_CONFIGCAT_SDKKEY} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Tag
#
# DELETE /v1/tags/{tagId}
# operationId: delete-tag
export def "tags delete-tag" [
  tagId: int
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tagId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag
#
# GET /v1/tags/{tagId}
# operationId: get-tag
export def "tags get-tag" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tagId)")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Tag
#
# PUT /v1/tags/{tagId}
# operationId: update-tag
export def "tags update-tag" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --color: string # nullable
  --name: string # nullable
]: any -> record<color: string, name: string, product: record<description: string, name: string, order: int, organization: record<name: string, organizationId: string>, productId: string, reasonRequired: bool>, tagId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tagId)")
  let body = {color: $color, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Settings by Tag
#
# GET /v1/tags/{tagId}/settings
# operationId: get-settings-by-tag
export def "tags-settings get-settings-by-tag" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<configId: string, configName: string, hint: string, key: string, name: string, order: int, settingId: int, settingType: string, tags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/tags/($tagId)/settings")
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
