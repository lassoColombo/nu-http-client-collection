# Auto-generated client for LUIS Authoring Client v3.0-preview
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Authoring/3.0-preview/swagger.json
# Auth: --token flag or $env.LUIS_AUTHORING_CLIENT_TOKEN

const BASE_URL = "https://azure.local"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LUIS_AUTHORING_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://azure.local"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def accept-completer [] { ["JSON" "application/json"] }
def accept-completer-1 [] { ["application/json" "application/octet-stream"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps List" } } | get name | first)
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

# Lists all of the user's applications.
#
# GET /apps/
# operationId: Apps_List
export def "apps List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new LUIS app.
#
# POST /apps/
# operationId: Apps_Add
export def "apps Add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string # The culture for the new application. It is the language that your app understands and speaks. E.g.: "en-us". Note: the culture cannot be changed after the app is created.
  --description: string # Description of the new application. Optional.
  --domain: string # The domain for the new application. Optional. E.g.: Comics.
  --initialVersionId: string # The initial version ID. Optional. Default value is: "0.1"
  name: string # The name for the new application.
  --usageScenario: string # Defines the scenario for the new application. Optional. E.g.: IoT.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/")
  let body = {culture: $culture, description: $description, domain: $domain, initialVersionId: $initialVersionId, name: $name, usageScenario: $usageScenario} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the endpoint URLs for the prebuilt Cortana applications.
#
# GET /apps/assistants
# operationId: Apps_ListCortanaEndpoints
export def "apps-assistants ListCortanaEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpointKeys: list<string>, endpointUrls: record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/assistants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of supported cultures. Cultures are equivalent to the written language and locale. For example,"en-us" represents the U.S. variation of English.
#
# GET /apps/cultures
# operationId: Apps_ListSupportedCultures
export def "apps-cultures ListSupportedCultures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/cultures")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the available custom prebuilt domains for all cultures.
#
# GET /apps/customprebuiltdomains
# operationId: Apps_ListAvailableCustomPrebuiltDomains
export def "apps-customprebuiltdomains ListAvailableCustomPrebuiltDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/customprebuiltdomains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a prebuilt domain along with its intent and entity models as a new application.
#
# POST /apps/customprebuiltdomains
# operationId: Apps_AddCustomPrebuiltDomain
export def "apps-customprebuiltdomains AddCustomPrebuiltDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --culture: string # The culture of the new domain.
  --domainName: string # The domain name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/customprebuiltdomains")
  let body = {culture: $culture, domainName: $domainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all the available prebuilt domains for a specific culture.
#
# GET /apps/customprebuiltdomains/{culture}
# operationId: Apps_ListAvailableCustomPrebuiltDomainsForCulture
export def "apps-customprebuiltdomains ListAvailableCustomPrebuiltDomainsForCulture" [
  culture: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/customprebuiltdomains/($culture)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available application domains.
#
# GET /apps/domains
# operationId: Apps_ListDomains
export def "apps-domains ListDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Imports an application to LUIS, the application's structure is included in the request body.
#
# POST /apps/import
# operationId: Apps_Import
# --closedLists item shape: {name?: string, roles?: list, subLists?: list}
# --composites item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --entities item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --hierarchicals item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --intents item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --patternAnyEntities item shape: {explicitList?: list, name?: string, roles?: list}
# --patterns item shape: {intent?: string, pattern?: string}
# --phraselists item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
# --prebuiltEntities item shape: {name?: string, roles?: list}
# --regex_entities item shape: {name?: string, regexPattern?: string, roles?: list}
# --regex_features item shape: {activated?: bool, name?: string, pattern?: string}
# --utterances item shape: {entities?: list, intent?: string, text?: string}
export def "apps-import Import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appName: string # The application name to create. If not specified, the application name will be read from the imported object. If the application name already exists, an error is returned.
  --closedLists: list # List of list entities. — item shape: {name?: string, roles?: list, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --hierarchicals: list # List of hierarchical entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --intents: list # List of intents. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --name: string # The name of the application.
  --patternAnyEntities: list # List of Pattern.Any entities. — item shape: {explicitList?: list, name?: string, roles?: list}
  --patterns: list # List of patterns. — item shape: {intent?: string, pattern?: string}
  --phraselists: list # List of model features. — item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
  --prebuiltEntities: list # List of prebuilt entities. — item shape: {name?: string, roles?: list}
  --regex-entities: list # List of regular expression entities. — item shape: {name?: string, regexPattern?: string, roles?: list}
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of example utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --versionId: string # The version ID of the application that was exported.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appName" $appName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/import" $qp)
  let body = {closedLists: $closedLists, composites: $composites, culture: $culture, desc: $desc, entities: $entities, hierarchicals: $hierarchicals, intents: $intents, name: $name, patternAnyEntities: $patternAnyEntities, patterns: $patterns, phraselists: $phraselists, prebuiltEntities: $prebuiltEntities, regex_entities: $regex_entities, regex_features: $regex_features, utterances: $utterances, versionId: $versionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the application available usage scenarios.
#
# GET /apps/usagescenarios
# operationId: Apps_ListUsageScenarios
export def "apps-usagescenarios ListUsageScenarios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/usagescenarios")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes an application.
#
# DELETE /apps/{appId}
# operationId: Apps_Delete
export def "apps Delete" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # A flag to indicate whether to force an operation. (default: false)
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the application info.
#
# GET /apps/{appId}
# operationId: Apps_Get
export def "apps Get" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name or description of the application.
#
# PUT /apps/{appId}
# operationId: Apps_Update
export def "apps Update" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The application's new description.
  --name: string # The application's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# apps - Removes an assigned LUIS Azure account from an application
#
# DELETE /apps/{appId}/azureaccounts
# operationId: AzureAccounts_RemoveFromApp
export def "apps-azureaccounts RemoveFromApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
  accountName: string # The Azure account name.
  azureSubscriptionId: string # The id for the Azure subscription.
  resourceGroup: string # The Azure resource group name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/azureaccounts")
  let body = {accountName: $accountName, azureSubscriptionId: $azureSubscriptionId, resourceGroup: $resourceGroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# apps - Get LUIS Azure accounts assigned to the application
#
# GET /apps/{appId}/azureaccounts
# operationId: AzureAccounts_GetAssigned
export def "apps-azureaccounts GetAssigned" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
]: nothing -> table<accountName: string, azureSubscriptionId: string, resourceGroup: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/azureaccounts")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# apps - Assign a LUIS Azure account to an application
#
# POST /apps/{appId}/azureaccounts
# operationId: AzureAccounts_AssignToApp
export def "apps-azureaccounts AssignToApp" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
  accountName: string # The Azure account name.
  azureSubscriptionId: string # The id for the Azure subscription.
  resourceGroup: string # The Azure resource group name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/azureaccounts")
  let body = {accountName: $accountName, azureSubscriptionId: $azureSubscriptionId, resourceGroup: $resourceGroup} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the available endpoint deployment regions and URLs.
#
# GET /apps/{appId}/endpoints
# operationId: Apps_ListEndpoints
export def "apps-endpoints ListEndpoints" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/endpoints")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a user from the allowed list of users to access this LUIS application. Users are removed using their email address.
#
# DELETE /apps/{appId}/permissions
# operationId: Permissions_Delete
export def "apps-permissions Delete" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/permissions")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of user emails that have permissions to access your application.
#
# GET /apps/{appId}/permissions
# operationId: Permissions_List
export def "apps-permissions List" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: list<string>, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a user to the allowed list of users to access this LUIS application. Users are added using their email address.
#
# POST /apps/{appId}/permissions
# operationId: Permissions_Add
export def "apps-permissions Add" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/permissions")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replaces the current user access list with the new list sent in the body. If an empty list is sent, all access to other users will be removed.
#
# PUT /apps/{appId}/permissions
# operationId: Permissions_Update
export def "apps-permissions Update" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list # The email address of the users.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/permissions")
  let body = {emails: $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Publishes a specific version of the application.
#
# POST /apps/{appId}/publish
# operationId: Apps_Publish
export def "apps-publish Publish" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isStaging: oneof<nothing, bool> # Indicates if the staging slot should be used, instead of the Production one. (default: false)
  --versionId: string # The version ID to publish.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/publish")
  let body = {isStaging: $isStaging, versionId: $versionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the application publish settings including 'UseAllTrainingData'.
#
# GET /apps/{appId}/publishsettings
# operationId: Apps_GetPublishSettings
export def "apps-publishsettings GetPublishSettings" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, sentimentAnalysis: bool, speech: bool, spellChecker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/publishsettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the application publish settings including 'UseAllTrainingData'.
#
# PUT /apps/{appId}/publishsettings
# operationId: Apps_UpdatePublishSettings
export def "apps-publishsettings UpdatePublishSettings" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sentimentAnalysis: oneof<nothing, bool> # Setting sentiment analysis as true returns the Sentiment of the input utterance along with the response
  --speech: oneof<nothing, bool> # Setting speech as public enables speech priming in your app
  --spellChecker: oneof<nothing, bool> # Setting spell checker as public enables spell checking the input utterance.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/publishsettings")
  let body = {sentimentAnalysis: $sentimentAnalysis, speech: $speech, spellChecker: $spellChecker} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the logs of the past month's endpoint queries for the application.
#
# GET /apps/{appId}/querylogs
# operationId: Apps_DownloadQueryLogs
export def "apps-querylogs DownloadQueryLogs" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/querylogs")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the application settings including 'UseAllTrainingData'.
#
# GET /apps/{appId}/settings
# operationId: Apps_GetSettings
export def "apps-settings GetSettings" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, public: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the application settings including 'UseAllTrainingData'.
#
# PUT /apps/{appId}/settings
# operationId: Apps_UpdateSettings
export def "apps-settings UpdateSettings" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public: oneof<nothing, bool> # Setting your application as public allows other people to use your application's endpoint using their own keys.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/settings")
  let body = {public: $public} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of versions for this application ID.
#
# GET /apps/{appId}/versions
# operationId: Versions_List
export def "apps-versions List" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Imports a new version into a LUIS application.
#
# POST /apps/{appId}/versions/import
# operationId: Versions_Import
# --closedLists item shape: {name?: string, roles?: list, subLists?: list}
# --composites item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --entities item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --hierarchicals item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --intents item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
# --patternAnyEntities item shape: {explicitList?: list, name?: string, roles?: list}
# --patterns item shape: {intent?: string, pattern?: string}
# --phraselists item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
# --prebuiltEntities item shape: {name?: string, roles?: list}
# --regex_entities item shape: {name?: string, regexPattern?: string, roles?: list}
# --regex_features item shape: {activated?: bool, name?: string, pattern?: string}
# --utterances item shape: {entities?: list, intent?: string, text?: string}
export def "apps-versions-import Import" [
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --versionId: string # The new versionId to import. If not specified, the versionId will be read from the imported object.
  --closedLists: list # List of list entities. — item shape: {name?: string, roles?: list, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --hierarchicals: list # List of hierarchical entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --intents: list # List of intents. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list}
  --name: string # The name of the application.
  --patternAnyEntities: list # List of Pattern.Any entities. — item shape: {explicitList?: list, name?: string, roles?: list}
  --patterns: list # List of patterns. — item shape: {intent?: string, pattern?: string}
  --phraselists: list # List of model features. — item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
  --prebuiltEntities: list # List of prebuilt entities. — item shape: {name?: string, roles?: list}
  --regex-entities: list # List of regular expression entities. — item shape: {name?: string, regexPattern?: string, roles?: list}
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of example utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --versionId: string # The version ID of the application that was exported.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versionId" $versionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/import" $qp)
  let body = {closedLists: $closedLists, composites: $composites, culture: $culture, desc: $desc, entities: $entities, hierarchicals: $hierarchicals, intents: $intents, name: $name, patternAnyEntities: $patternAnyEntities, patterns: $patterns, phraselists: $phraselists, prebuiltEntities: $prebuiltEntities, regex_entities: $regex_entities, regex_features: $regex_features, utterances: $utterances, versionId: $versionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an application version.
#
# DELETE /apps/{appId}/versions/{versionId}/
# operationId: Versions_Delete
export def "apps-versions Delete" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the version information such as date created, last modified date, endpoint URL, count of intents and entities, training and publishing status.
#
# GET /apps/{appId}/versions/{versionId}/
# operationId: Versions_Get
export def "apps-versions Get" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name or description of the application version.
#
# PUT /apps/{appId}/versions/{versionId}/
# operationId: Versions_Update
export def "apps-versions Update" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The new version for the cloned model.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new version from the selected version.
#
# POST /apps/{appId}/versions/{versionId}/clone
# operationId: Versions_Clone
export def "apps-versions-clone Clone" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The new version for the cloned model.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/clone")
  let body = {version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about all the list entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists
# operationId: Model_ListClosedLists
export def "apps-versions-closedlists ListClosedLists" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<subLists: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a list entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists
# operationId: Model_AddClosedList
# --subLists item shape: {canonicalForm?: string, list?: list}
export def "apps-versions-closedlists AddClosedList" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the list entity.
  --subLists: list # Sublists for the feature. — item shape: {canonicalForm?: string, list?: list}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists")
  let body = {name: $name, subLists: $subLists} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a list entity model from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_DeleteClosedList
export def "apps-versions-closedlists DeleteClosedList" [
  appId: string
  versionId: string
  clEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_GetClosedList
export def "apps-versions-closedlists GetClosedList" [
  appId: string
  versionId: string
  clEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<subLists: table<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a batch of sublists to an existing list entity in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_PatchClosedList
# --subLists item shape: {canonicalForm?: string, list?: list}
export def "apps-versions-closedlists PatchClosedList" [
  appId: string
  versionId: string
  clEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subLists: list # Sublists to add. — item shape: {canonicalForm?: string, list?: list}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)")
  let body = {subLists: $subLists} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the list entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_UpdateClosedList
# --subLists item shape: {canonicalForm?: string, list?: list}
export def "apps-versions-closedlists UpdateClosedList" [
  appId: string
  versionId: string
  clEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the list entity.
  --subLists: list # The new sublists for the feature. — item shape: {canonicalForm?: string, list?: list}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)")
  let body = {name: $name, subLists: $subLists} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a sublist to an existing list entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists
# operationId: Model_AddSubList
export def "apps-versions-closedlists-sublists AddSubList" [
  appId: string
  versionId: string
  clEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonicalForm: string # The standard form that the list represents.
  --list: list # List of synonym words.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)/sublists")
  let body = {canonicalForm: $canonicalForm, list: $list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a sublist of a specific list entity model from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}
# operationId: Model_DeleteSubList
export def "apps-versions-closedlists-sublists DeleteSubList" [
  appId: string
  versionId: string
  clEntityId: string
  subListId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)/sublists/($subListId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates one of the list entity's sublists in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}
# operationId: Model_UpdateSubList
export def "apps-versions-closedlists-sublists UpdateSubList" [
  appId: string
  versionId: string
  clEntityId: string
  subListId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonicalForm: string # The standard form that the list represents.
  --list: list # List of synonym words.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($clEntityId)/sublists/($subListId)")
  let body = {canonicalForm: $canonicalForm, list: $list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all roles for a list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles
# operationId: Model_ListClosedListEntityRoles
export def "apps-versions-closedlists-roles ListClosedListEntityRoles" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($entityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for a list entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles
# operationId: Model_CreateClosedListEntityRole
export def "apps-versions-closedlists-roles CreateClosedListEntityRole" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($entityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role for a given list entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# operationId: Model_DeleteClosedListEntityRole
export def "apps-versions-closedlists-roles DeleteClosedListEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# operationId: Model_GetClosedListEntityRole
export def "apps-versions-closedlists-roles GetClosedListEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given list entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# operationId: Model_UpdateClosedListEntityRole
export def "apps-versions-closedlists-roles UpdateClosedListEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/closedlists/($entityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about all the composite entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/compositeentities
# operationId: Model_ListCompositeEntities
export def "apps-versions-compositeentities ListCompositeEntities" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a composite entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# operationId: Model_DeleteCompositeEntity
export def "apps-versions-compositeentities DeleteCompositeEntity" [
  appId: string
  versionId: string
  cEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a composite entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# operationId: Model_GetCompositeEntity
export def "apps-versions-compositeentities GetCompositeEntity" [
  appId: string
  versionId: string
  cEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a composite entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# operationId: Model_UpdateCompositeEntity
export def "apps-versions-compositeentities UpdateCompositeEntity" [
  appId: string
  versionId: string
  cEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list # Child entities.
  --name: string # Entity name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)")
  let body = {children: $children, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a single child in an existing composite entity model in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children
# operationId: Model_AddCompositeEntityChild
export def "apps-versions-compositeentities-children AddCompositeEntityChild" [
  appId: string
  versionId: string
  cEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/children")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a composite entity extractor child from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children/{cChildId}
# operationId: Model_DeleteCompositeEntityChild
export def "apps-versions-compositeentities-children DeleteCompositeEntityChild" [
  appId: string
  versionId: string
  cEntityId: string
  cChildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/children/($cChildId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all roles for a composite entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles
# operationId: Model_ListCompositeEntityRoles
export def "apps-versions-compositeentities-roles ListCompositeEntityRoles" [
  appId: string
  versionId: string
  cEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for a composite entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles
# operationId: Model_CreateCompositeEntityRole
export def "apps-versions-compositeentities-roles CreateCompositeEntityRole" [
  appId: string
  versionId: string
  cEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role for a given composite entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# operationId: Model_DeleteCompositeEntityRole
export def "apps-versions-compositeentities-roles DeleteCompositeEntityRole" [
  appId: string
  versionId: string
  cEntityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given composite entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# operationId: Model_GetCompositeEntityRole
export def "apps-versions-compositeentities-roles GetCompositeEntityRole" [
  appId: string
  versionId: string
  cEntityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given composite entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# operationId: Model_UpdateCompositeEntityRole
export def "apps-versions-compositeentities-roles UpdateCompositeEntityRole" [
  appId: string
  versionId: string
  cEntityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/compositeentities/($cEntityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a customizable prebuilt domain along with all of its intent and entity models in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltdomains
# operationId: Model_AddCustomPrebuiltDomain
export def "apps-versions-customprebuiltdomains AddCustomPrebuiltDomain" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domainName: string # The domain name.
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltdomains")
  let body = {domainName: $domainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a prebuilt domain's models in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/customprebuiltdomains/{domainName}
# operationId: Model_DeleteCustomPrebuiltDomain
export def "apps-versions-customprebuiltdomains DeleteCustomPrebuiltDomain" [
  appId: string
  versionId: string
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltdomains/($domainName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all prebuilt entities used in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities
# operationId: Model_ListCustomPrebuiltEntities
export def "apps-versions-customprebuiltentities ListCustomPrebuiltEntities" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a prebuilt entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltentities
# operationId: Model_AddCustomPrebuiltEntity
export def "apps-versions-customprebuiltentities AddCustomPrebuiltEntity" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domainName: string # The domain name.
  --modelName: string # The intent name or entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities")
  let body = {domainName: $domainName, modelName: $modelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all roles for a prebuilt entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles
# operationId: Model_ListCustomPrebuiltEntityRoles
export def "apps-versions-customprebuiltentities-roles ListCustomPrebuiltEntityRoles" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities/($entityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for a prebuilt entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles
# operationId: Model_CreateCustomPrebuiltEntityRole
export def "apps-versions-customprebuiltentities-roles CreateCustomPrebuiltEntityRole" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities/($entityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role for a given prebuilt entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# operationId: Model_DeleteCustomEntityRole
export def "apps-versions-customprebuiltentities-roles DeleteCustomEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given prebuilt entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# operationId: Model_GetCustomEntityRole
export def "apps-versions-customprebuiltentities-roles GetCustomEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given prebuilt entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# operationId: Model_UpdateCustomPrebuiltEntityRole
export def "apps-versions-customprebuiltentities-roles UpdateCustomPrebuiltEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltentities/($entityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about customizable prebuilt intents added to a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltintents
# operationId: Model_ListCustomPrebuiltIntents
export def "apps-versions-customprebuiltintents ListCustomPrebuiltIntents" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltintents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a customizable prebuilt intent model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltintents
# operationId: Model_AddCustomPrebuiltIntent
export def "apps-versions-customprebuiltintents AddCustomPrebuiltIntent" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domainName: string # The domain name.
  --modelName: string # The intent name or entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltintents")
  let body = {domainName: $domainName, modelName: $modelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all prebuilt intent and entity model information used in a version of this application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltmodels
# operationId: Model_ListCustomPrebuiltModels
export def "apps-versions-customprebuiltmodels ListCustomPrebuiltModels" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, readableType: string, typeId: int, customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/customprebuiltmodels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about all the simple entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities
# operationId: Model_ListEntities
export def "apps-versions-entities ListEntities" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<children: list<record>, customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds an entity extractor to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities
# operationId: Model_AddEntity
# --children item shape: {children?: list, instanceOf?: string, name?: string}
export def "apps-versions-entities AddEntity" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list # Child entities. — item shape: {children?: list, instanceOf?: string, name?: string}
  --name: string # Entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities")
  let body = {children: $children, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an entity or a child from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_DeleteEntity
export def "apps-versions-entities DeleteEntity" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about an entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_GetEntity
export def "apps-versions-entities GetEntity" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name of an entity extractor or the name and instanceOf model of a child entity extractor.
#
# PATCH /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_UpdateEntityChild
export def "apps-versions-entities UpdateEntityChild" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --instanceOf: string # The instance of model name
  --name: string # Entity name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)")
  let body = {instanceOf: $instanceOf, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a single child in an existing entity model hierarchy in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/children
# operationId: Model_AddEntityChild
# --children item shape: {children?: list, instanceOf?: string, name?: string}
export def "apps-versions-entities-children AddEntityChild" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list # Child entities. — item shape: {children?: list, instanceOf?: string, name?: string}
  --instanceOf: string # The instance of model name
  --name: string # Entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/children")
  let body = {children: $children, instanceOf: $instanceOf, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a relation from the feature relations used by the entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Model_DeleteEntityFeature
export def "apps-versions-entities-features DeleteEntityFeature" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --featureName: string # The name of the feature used.
  --modelName: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/features")
  let body = {featureName: $featureName, modelName: $modelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the information of the features used by the entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Model_GetEntityFeatures
export def "apps-versions-entities-features GetEntityFeatures" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<featureName: string, modelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new feature relation to be used by the entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Features_AddEntityFeature
export def "apps-versions-entities-features AddEntityFeature" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --featureName: string # The name of the feature used.
  --modelName: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/features")
  let body = {featureName: $featureName, modelName: $modelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the information of the features used by the entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Model_ReplaceEntityFeatures
export def "apps-versions-entities-features ReplaceEntityFeatures" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/features")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all roles for an entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/roles
# operationId: Model_ListEntityRoles
export def "apps-versions-entities-roles ListEntityRoles" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an entity role in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/roles
# operationId: Model_CreateEntityRole
export def "apps-versions-entities-roles CreateEntityRole" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an entity role in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# operationId: Model_DeleteEntityRole
export def "apps-versions-entities-roles DeleteEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# operationId: Model_GetEntityRole
export def "apps-versions-entities-roles GetEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# operationId: Model_UpdateEntityRole
export def "apps-versions-entities-roles UpdateEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get suggested example utterances that would improve the accuracy of the entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/suggest
# operationId: Model_ListEntitySuggestions
export def "apps-versions-entities-suggest ListEntitySuggestions" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/entities/($entityId)/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a labeled example utterance in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/example
# operationId: Examples_Add
# --entityLabels item shape: {endCharIndex: int, entityName: string, role?: string, startCharIndex: int}
export def "apps-versions-example Add" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entityLabels: list # The identified entities within the example utterance. — item shape: {endCharIndex: int, entityName: string, role?: string, startCharIndex: int}
  --intentName: string # The identified intent representing the example utterance.
  --text: string # The example utterance.
]: any -> record<ExampleId: int, UtteranceText: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/example")
  let body = {entityLabels: $entityLabels, intentName: $intentName, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns example utterances to be reviewed from a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/examples
# operationId: Examples_List
export def "apps-versions-examples List" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<entityLabels: list<record>, entityPredictions: list<record>, id: int, intentLabel: string, intentPredictions: list<record>, text: string, tokenizedText: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a batch of labeled example utterances to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/examples
# operationId: Examples_Batch
export def "apps-versions-examples Batch" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<error: record<code: string, message: string>, hasError: bool, value: record<ExampleId: int, UtteranceText: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/examples")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the labeled example utterances with the specified ID from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/examples/{exampleId}
# operationId: Examples_Delete
export def "apps-versions-examples Delete" [
  appId: string
  versionId: string
  exampleId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/examples/($exampleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports a LUIS application to JSON format.
#
# GET /apps/{appId}/versions/{versionId}/export
# operationId: Versions_Export
export def "apps-versions-export Export" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<closedLists: table<name: string, roles: list, subLists: list>, composites: table<children: list, features: list, inherits: record, name: string, roles: list>, culture: string, desc: string, entities: table<children: list, features: list, inherits: record, name: string, roles: list>, hierarchicals: table<children: list, features: list, inherits: record, name: string, roles: list>, intents: table<children: list, features: list, inherits: record, name: string, roles: list>, name: string, patternAnyEntities: table<explicitList: list, name: string, roles: list>, patterns: table<intent: string, pattern: string>, phraselists: table<activated: bool, enabledForAllModels: bool, mode: bool, name: string, words: string>, prebuiltEntities: table<name: string, roles: list>, regex_entities: table<name: string, regexPattern: string, roles: list>, regex_features: table<activated: bool, name: string, pattern: string>, utterances: table<entities: list, intent: string, text: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the extraction phraselist and pattern features in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/features
# operationId: Features_List
export def "apps-versions-features List" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> record<patternFeatures: table<pattern: string>, phraselistFeatures: table<isExchangeable: bool, phrases: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about all the hierarchical entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities
# operationId: Model_ListHierarchicalEntities
export def "apps-versions-hierarchicalentities ListHierarchicalEntities" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a hierarchical entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# operationId: Model_DeleteHierarchicalEntity
export def "apps-versions-hierarchicalentities DeleteHierarchicalEntity" [
  appId: string
  versionId: string
  hEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a hierarchical entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# operationId: Model_GetHierarchicalEntity
export def "apps-versions-hierarchicalentities GetHierarchicalEntity" [
  appId: string
  versionId: string
  hEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name of a hierarchical entity model in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# operationId: Model_UpdateHierarchicalEntity
export def "apps-versions-hierarchicalentities UpdateHierarchicalEntity" [
  appId: string
  versionId: string
  hEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a hierarchical entity extractor child in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# operationId: Model_DeleteHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children DeleteHierarchicalEntityChild" [
  appId: string
  versionId: string
  hEntityId: string
  hChildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/children/($hChildId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the child's model contained in an hierarchical entity child model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# operationId: Model_GetHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children GetHierarchicalEntityChild" [
  appId: string
  versionId: string
  hEntityId: string
  hChildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<readableType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/children/($hChildId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Renames a single child in an existing hierarchical entity model in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# operationId: Model_UpdateHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children UpdateHierarchicalEntityChild" [
  appId: string
  versionId: string
  hEntityId: string
  hChildId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/children/($hChildId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all roles for a hierarchical entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles
# operationId: Model_ListHierarchicalEntityRoles
export def "apps-versions-hierarchicalentities-roles ListHierarchicalEntityRoles" [
  appId: string
  versionId: string
  hEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for an hierarchical entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles
# operationId: Model_CreateHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles CreateHierarchicalEntityRole" [
  appId: string
  versionId: string
  hEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role for a given hierarchical role in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# operationId: Model_DeleteHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles DeleteHierarchicalEntityRole" [
  appId: string
  versionId: string
  hEntityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given hierarchical entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# operationId: Model_GetHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles GetHierarchicalEntityRole" [
  appId: string
  versionId: string
  hEntityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given hierarchical entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# operationId: Model_UpdateHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles UpdateHierarchicalEntityRole" [
  appId: string
  versionId: string
  hEntityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/hierarchicalentities/($hEntityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about the intent models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents
# operationId: Model_ListIntents
export def "apps-versions-intents ListIntents" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds an intent to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/intents
# operationId: Model_AddIntent
export def "apps-versions-intents AddIntent" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the new entity extractor.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an intent from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/intents/{intentId}
# operationId: Model_DeleteIntent
export def "apps-versions-intents DeleteIntent" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deleteUtterances: oneof<nothing, bool> # If true, deletes the intent's example utterances. If false, moves the example utterances to the None intent. The default value is false. (default: false)
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteUtterances" $deleteUtterances "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the intent model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}
# operationId: Model_GetIntent
export def "apps-versions-intents GetIntent" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name of an intent in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/intents/{intentId}
# operationId: Model_UpdateIntent
export def "apps-versions-intents UpdateIntent" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a relation from the feature relations used by the intent in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Model_DeleteIntentFeature
export def "apps-versions-intents-features DeleteIntentFeature" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --featureName: string # The name of the feature used.
  --modelName: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)/features")
  let body = {featureName: $featureName, modelName: $modelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the information of the features used by the intent in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Model_GetIntentFeatures
export def "apps-versions-intents-features GetIntentFeatures" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<featureName: string, modelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new feature relation to be used by the intent in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Features_AddIntentFeature
export def "apps-versions-intents-features AddIntentFeature" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --featureName: string # The name of the feature used.
  --modelName: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)/features")
  let body = {featureName: $featureName, modelName: $modelName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the information of the features used by the intent in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Model_ReplaceIntentFeatures
export def "apps-versions-intents-features ReplaceIntentFeatures" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)/features")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns patterns for the specific intent in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/patternrules
# operationId: Pattern_ListIntentPatterns
export def "apps-versions-intents-patternrules ListIntentPatterns" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<id: string, intent: string, pattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)/patternrules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suggests example utterances that would improve the accuracy of the intent model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/suggest
# operationId: Model_ListIntentSuggestions
export def "apps-versions-intents-suggest ListIntentSuggestions" [
  appId: string
  versionId: string
  intentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/intents/($intentId)/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the available prebuilt entities in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/listprebuilts
# operationId: Model_ListPrebuiltEntities
export def "apps-versions-listprebuilts ListPrebuiltEntities" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, examples: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/listprebuilts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about all the intent and entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/models
# operationId: Model_ListModels
export def "apps-versions-models ListModels" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<id: string, name: string, readableType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the example utterances for the given intent or entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/models/{modelId}/examples
# operationId: Model_Examples
export def "apps-versions-models-examples Examples" [
  appId: string
  versionId: string
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<id: int, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/models/($modelId)/examples" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about the Pattern.Any entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities
# operationId: Model_ListPatternAnyEntityInfos
export def "apps-versions-patternanyentities ListPatternAnyEntityInfos" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<explicitList: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a pattern.any entity extractor to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities
# operationId: Model_CreatePatternAnyEntityModel
export def "apps-versions-patternanyentities CreatePatternAnyEntityModel" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitList: list # The Pattern.Any explicit list.
  --name: string # The model name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities")
  let body = {explicitList: $explicitList, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a Pattern.Any entity extractor from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# operationId: Model_DeletePatternAnyEntityModel
export def "apps-versions-patternanyentities DeletePatternAnyEntityModel" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the Pattern.Any model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# operationId: Model_GetPatternAnyEntityInfo
export def "apps-versions-patternanyentities GetPatternAnyEntityInfo" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<explicitList: table<explicitListItem: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the name and explicit (exception) list of a Pattern.Any entity model in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# operationId: Model_UpdatePatternAnyEntityModel
export def "apps-versions-patternanyentities UpdatePatternAnyEntityModel" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitList: list # The Pattern.Any explicit list.
  --name: string # The model name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)")
  let body = {explicitList: $explicitList, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the explicit (exception) list of the pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist
# operationId: Model_GetExplicitList
export def "apps-versions-patternanyentities-explicitlist GetExplicitList" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<explicitListItem: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/explicitlist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new exception to the explicit list for the Pattern.Any entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist
# operationId: Model_AddExplicitListItem
export def "apps-versions-patternanyentities-explicitlist AddExplicitListItem" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitListItem: string # The explicit list item.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/explicitlist")
  let body = {explicitListItem: $explicitListItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an item from the explicit (exception) list for a Pattern.any entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# operationId: Model_DeleteExplicitListItem
export def "apps-versions-patternanyentities-explicitlist DeleteExplicitListItem" [
  appId: string
  versionId: string
  entityId: string
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/explicitlist/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the explicit (exception) list of the pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# operationId: Model_GetExplicitListItem
export def "apps-versions-patternanyentities-explicitlist GetExplicitListItem" [
  appId: string
  versionId: string
  entityId: string
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<explicitListItem: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/explicitlist/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an explicit (exception) list item for a Pattern.Any entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# operationId: Model_UpdateExplicitListItem
export def "apps-versions-patternanyentities-explicitlist UpdateExplicitListItem" [
  appId: string
  versionId: string
  entityId: string
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicitListItem: string # The explicit list item.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/explicitlist/($itemId)")
  let body = {explicitListItem: $explicitListItem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all roles for a Pattern.any entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles
# operationId: Model_ListPatternAnyEntityRoles
export def "apps-versions-patternanyentities-roles ListPatternAnyEntityRoles" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for an Pattern.any entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles
# operationId: Model_CreatePatternAnyEntityRole
export def "apps-versions-patternanyentities-roles CreatePatternAnyEntityRole" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role for a given Pattern.any entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# operationId: Model_DeletePatternAnyEntityRole
export def "apps-versions-patternanyentities-roles DeletePatternAnyEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given Pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# operationId: Model_GetPatternAnyEntityRole
export def "apps-versions-patternanyentities-roles GetPatternAnyEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given Pattern.any entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# operationId: Model_UpdatePatternAnyEntityRole
export def "apps-versions-patternanyentities-roles UpdatePatternAnyEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternanyentities/($entityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a pattern to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternrule
# operationId: Pattern_AddPattern
export def "apps-versions-patternrule AddPattern" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --intent: string # The intent's name which the pattern belongs to.
  --pattern: string # The pattern text.
]: any -> record<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrule")
  let body = {intent: $intent, pattern: $pattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a list of patterns in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_DeletePatterns
export def "apps-versions-patternrules DeletePatterns" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets patterns in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_ListPatterns
export def "apps-versions-patternrules ListPatterns" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<id: string, intent: string, pattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a batch of patterns in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_BatchAddPatterns
export def "apps-versions-patternrules BatchAddPatterns" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates patterns in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_UpdatePatterns
export def "apps-versions-patternrules UpdatePatterns" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrules")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the pattern with the specified ID from a version of the application..
#
# DELETE /apps/{appId}/versions/{versionId}/patternrules/{patternId}
# operationId: Pattern_DeletePattern
export def "apps-versions-patternrules DeletePattern" [
  appId: string
  versionId: string
  patternId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrules/($patternId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a pattern in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternrules/{patternId}
# operationId: Pattern_UpdatePattern
export def "apps-versions-patternrules UpdatePattern" [
  appId: string
  versionId: string
  patternId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The pattern ID. (format: uuid)
  --intent: string # The intent's name which the pattern belongs to.
  --pattern: string # The pattern text.
]: any -> record<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/patternrules/($patternId)")
  let body = {id: $id, intent: $intent, pattern: $pattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all the phraselist features in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/phraselists
# operationId: Features_ListPhraseLists
export def "apps-versions-phraselists ListPhraseLists" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<isExchangeable: bool, phrases: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/phraselists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new phraselist feature in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/phraselists
# operationId: Features_AddPhraseList
export def "apps-versions-phraselists AddPhraseList" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabledForAllModels: oneof<nothing, bool> # Indicates if the Phraselist is enabled for all models in the application. (default: true)
  --isExchangeable: oneof<nothing, bool> # An interchangeable phrase list feature serves as a list of synonyms for training. A non-exchangeable phrase list serves as separate features for training. So, if your non-interchangeable phrase list contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-interchangeable phrase list as an additional bag of words to add to LUIS existing vocabulary features. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t.  Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/phraselists")
  let body = {enabledForAllModels: $enabledForAllModels, isExchangeable: $isExchangeable, name: $name, phrases: $phrases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a phraselist feature from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# operationId: Features_DeletePhraseList
export def "apps-versions-phraselists DeletePhraseList" [
  appId: string
  versionId: string
  phraselistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/phraselists/($phraselistId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets phraselist feature info in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# operationId: Features_GetPhraseList
export def "apps-versions-phraselists GetPhraseList" [
  appId: string
  versionId: string
  phraselistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isExchangeable: bool, phrases: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/phraselists/($phraselistId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the phrases, the state and the name of the phraselist feature in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# operationId: Features_UpdatePhraseList
export def "apps-versions-phraselists UpdatePhraseList" [
  appId: string
  versionId: string
  phraselistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabledForAllModels: oneof<nothing, bool> # Indicates if the Phraselist is enabled for all models in the application. (default: true)
  --isActive: oneof<nothing, bool> # Indicates if the Phraselist is enabled. (default: true)
  --isExchangeable: oneof<nothing, bool> # An exchangeable phrase list feature are serves as single feature to the LUIS underlying training algorithm. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t. Think of an exchangeable as a synonyms list. A non-exchangeable phrase list feature has all the phrases in the list serve as separate features to the underlying training algorithm. So, if you your phrase list feature contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-exchangeable phrase list feature as an additional bag of words that you are willing to add to LUIS existing vocabulary features. Think of a non-exchangeable as set of different words. Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/phraselists/($phraselistId)")
  let body = {enabledForAllModels: $enabledForAllModels, isActive: $isActive, isExchangeable: $isExchangeable, name: $name, phrases: $phrases} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets information about all the prebuilt entities in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts
# operationId: Model_ListPrebuilts
export def "apps-versions-prebuilts ListPrebuilts" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a list of prebuilt entities to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/prebuilts
# operationId: Model_AddPrebuilt
export def "apps-versions-prebuilts AddPrebuilt" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a prebuilt entity's roles in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles
# operationId: Model_ListPrebuiltEntityRoles
export def "apps-versions-prebuilts-roles ListPrebuiltEntityRoles" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($entityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for a prebuilt entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles
# operationId: Model_CreatePrebuiltEntityRole
export def "apps-versions-prebuilts-roles CreatePrebuiltEntityRole" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($entityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role in a prebuilt entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# operationId: Model_DeletePrebuiltEntityRole
export def "apps-versions-prebuilts-roles DeletePrebuiltEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given prebuilt entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# operationId: Model_GetPrebuiltEntityRole
export def "apps-versions-prebuilts-roles GetPrebuiltEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given prebuilt entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# operationId: Model_UpdatePrebuiltEntityRole
export def "apps-versions-prebuilts-roles UpdatePrebuiltEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($entityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a prebuilt entity extractor from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}
# operationId: Model_DeletePrebuilt
export def "apps-versions-prebuilts DeletePrebuilt" [
  appId: string
  versionId: string
  prebuiltId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($prebuiltId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a prebuilt entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}
# operationId: Model_GetPrebuilt
export def "apps-versions-prebuilts GetPrebuilt" [
  appId: string
  versionId: string
  prebuiltId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/prebuilts/($prebuiltId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the regular expression entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities
# operationId: Model_ListRegexEntityInfos
export def "apps-versions-regexentities ListRegexEntityInfos" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<regexPattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a regular expression entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/regexentities
# operationId: Model_CreateRegexEntityModel
export def "apps-versions-regexentities CreateRegexEntityModel" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The model name.
  --regexPattern: string # The regular expression entity pattern.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities")
  let body = {name: $name, regexPattern: $regexPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all roles for a regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles
# operationId: Model_ListRegexEntityRoles
export def "apps-versions-regexentities-roles ListRegexEntityRoles" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($entityId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a role for an regular expression entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles
# operationId: Model_CreateRegexEntityRole
export def "apps-versions-regexentities-roles CreateRegexEntityRole" [
  appId: string
  versionId: string
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($entityId)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role for a given regular expression in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# operationId: Model_DeleteRegexEntityRole
export def "apps-versions-regexentities-roles DeleteRegexEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get one role for a given regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# operationId: Model_GetRegexEntityRole
export def "apps-versions-regexentities-roles GetRegexEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($entityId)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role for a given regular expression entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# operationId: Model_UpdateRegexEntityRole
export def "apps-versions-regexentities-roles UpdateRegexEntityRole" [
  appId: string
  versionId: string
  entityId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($entityId)/roles/($roleId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a regular expression entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# operationId: Model_DeleteRegexEntityModel
export def "apps-versions-regexentities DeleteRegexEntityModel" [
  appId: string
  versionId: string
  regexEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($regexEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# operationId: Model_GetRegexEntityEntityInfo
export def "apps-versions-regexentities GetRegexEntityEntityInfo" [
  appId: string
  versionId: string
  regexEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<regexPattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($regexEntityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the regular expression entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# operationId: Model_UpdateRegexEntityModel
export def "apps-versions-regexentities UpdateRegexEntityModel" [
  appId: string
  versionId: string
  regexEntityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The model name.
  --regexPattern: string # The regular expression entity pattern.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/regexentities/($regexEntityId)")
  let body = {name: $name, regexPattern: $regexPattern} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the settings in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/settings
# operationId: Settings_List
export def "apps-versions-settings List" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the settings in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/settings
# operationId: Settings_Update
export def "apps-versions-settings Update" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/settings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deleted an unlabelled utterance in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/suggest
# operationId: Versions_DeleteUnlabelledUtterance
export def "apps-versions-suggest DeleteUnlabelledUtterance" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/suggest")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the training status of all models (intents and entities) for the specified LUIS app. You must call the train API to train the LUIS app before you call this API to get training status. "appID" specifies the LUIS app ID. "versionId" specifies the version number of the LUIS app. For example, "0.1".
#
# GET /apps/{appId}/versions/{versionId}/train
# operationId: Train_GetStatus
export def "apps-versions-train GetStatus" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<details: record<exampleCount: int, failureReason: string, status: string, statusId: int, trainingDateTime: string>, modelId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/train")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a training request for a version of a specified LUIS app. This POST request initiates a request asynchronously. To determine whether the training request is successful, submit a GET request to get training status. Note: The application version is not fully trained unless all the models (intents and entities) are trained successfully or are up to date. To verify training success, get the training status at least once after training is complete.
#
# POST /apps/{appId}/versions/{versionId}/train
# operationId: Train_TrainVersion
export def "apps-versions-train TrainVersion" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, statusId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/apps/($appId)/versions/($versionId)/train")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# user - Get LUIS Azure accounts
#
# GET /azureaccounts
# operationId: AzureAccounts_ListUserLUISAccounts
export def "azureaccounts ListUserLUISAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
]: nothing -> table<accountName: string, azureSubscriptionId: string, resourceGroup: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/azureaccounts")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# package - Gets published LUIS application package in binary stream GZip format
#
# GET /package/{appId}/slot/{slotName}/gzip
# operationId: Apps_PackagePublishedApplicationAsGzip
export def "package-slot-gzip PackagePublishedApplicationAsGzip" [
  appId: string
  slotName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/package/($appId)/slot/($slotName)/gzip")
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# package - Gets trained LUIS application package in binary stream GZip format
#
# GET /package/{appId}/versions/{versionId}/gzip
# operationId: Apps_PackageTrainedApplicationAsGzip
export def "package-versions-gzip PackageTrainedApplicationAsGzip" [
  appId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/package/($appId)/versions/($versionId)/gzip")
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
