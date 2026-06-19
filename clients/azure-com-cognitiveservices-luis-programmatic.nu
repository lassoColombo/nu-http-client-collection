# Auto-generated client for LUIS Programmatic vv2.0
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Programmatic/v2.0/swagger.json
# Auth: --token flag or $env.LUIS_PROGRAMMATIC_TOKEN

const BASE_URL = "https://azure.local/luis/api/v2.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LUIS_PROGRAMMATIC_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://azure.local/luis/api/v2.0"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def accept-completer [] { ["JSON" "application/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps list" } } | get name | first)
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

# Lists all of the user applications.
#
# GET /apps/
# operationId: Apps_List
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Creates a new LUIS app.
#
# POST /apps/
# operationId: Apps_Add
export def "apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  culture: string # The culture for the new application. It is the language that your app understands and speaks. E.g.: "en-us". Note: the culture cannot be changed after the app is created.
  --description: string # Description of the new application. Optional.
  --domain: string # The domain for the new application. Optional. E.g.: Comics.
  --initial-version-id: string # The initial version ID. Optional. Default value is: "0.1"
  name: string # The name for the new application.
  --usage-scenario: string # Defines the scenario for the new application. Optional. E.g.: IoT.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/")
  let req_body = {"culture": $culture, "description": $description, "domain": $domain, "initialVersionId": $initial_version_id, "name": $name, "usageScenario": $usage_scenario} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the endpoint URLs for the prebuilt Cortana applications.
#
# GET /apps/assistants
# operationId: Apps_ListCortanaEndpoints
export def "apps-assistants list-cortana-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endpointKeys: list<string>, endpointUrls: record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/assistants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the supported application cultures.
#
# GET /apps/cultures
# operationId: Apps_ListSupportedCultures
export def "apps-cultures list-supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/cultures")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all the available custom prebuilt domains for all cultures.
#
# GET /apps/customprebuiltdomains
# operationId: Apps_ListAvailableCustomPrebuiltDomains
export def "apps-customprebuiltdomains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/customprebuiltdomains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a prebuilt domain along with its models as a new application.
#
# POST /apps/customprebuiltdomains
# operationId: Apps_AddCustomPrebuiltDomain
export def "apps-customprebuiltdomains create-custom-prebuilt-domain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --culture: string # The culture of the new domain.
  --domain-name: string # The domain name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/customprebuiltdomains")
  let req_body = {"culture": $culture, "domainName": $domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all the available custom prebuilt domains for a specific culture.
#
# GET /apps/customprebuiltdomains/{culture}
# operationId: Apps_ListAvailableCustomPrebuiltDomainsForCulture
export def "apps-customprebuiltdomains list-available-custom-prebuilt-domains" [
  culture: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<culture: string, description: string, entities: list<record>, examples: string, intents: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($culture | is-empty) { error make --unspanned { msg: "path parameter 'culture' must be non-empty" } }
  let full_url = (build-url $base ({culture: (encode-path-segment $culture)} | format pattern "/apps/customprebuiltdomains/{culture}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the available application domains.
#
# GET /apps/domains
# operationId: Apps_ListDomains
export def "apps-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Imports an application to LUIS, the application's structure should be included in in the request body.
#
# POST /apps/import
# operationId: Apps_Import
# --closedLists item shape: {name?: string, subLists?: list}
# --composites item shape: {children?: list<string>, name?: string}
# --entities item shape: {children?: list<string>, name?: string}
# --intents item shape: {children?: list<string>, name?: string}
# --model_features item shape: {activated?: bool, mode?: bool, name?: string, words?: string}
# --regex_features item shape: {activated?: bool, name?: string, pattern?: string}
# --utterances item shape: {entities?: list, intent?: string, text?: string}
export def "apps-import import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-name: string # The application name to create. If not specified, the application name will be read from the imported object.
  --bing-entities: list<string> # List of prebuilt intents.
  --closed-lists: list # List of closed lists. — item shape: {name?: string, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list<string>, name?: string}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list<string>, name?: string}
  --intents: list # List of intents. — item shape: {children?: list<string>, name?: string}
  --model-features: list # List of model features. — item shape: {activated?: bool, mode?: bool, name?: string, words?: string}
  --name: string # The name of the application.
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of sample utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --version-id: string # The version ID of the application that was exported.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appName" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/import" $qp)
  let req_body = {"bing_entities": $bing_entities, "closedLists": $closed_lists, "composites": $composites, "culture": $culture, "desc": $desc, "entities": $entities, "intents": $intents, "model_features": $model_features, "name": $name, "regex_features": $regex_features, "utterances": $utterances, "versionId": $version_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"appName": $app_name} | compact), body: $req_body}
}

# Gets the application available usage scenarios.
#
# GET /apps/usagescenarios
# operationId: Apps_ListUsageScenarios
export def "apps-usagescenarios list-usage-scenarios" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apps/usagescenarios")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes an application.
#
# DELETE /apps/{appId}
# operationId: Apps_Delete
export def "apps delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the application info.
#
# GET /apps/{appId}
# operationId: Apps_Get
export def "apps get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activeVersion: string, createdDateTime: string, culture: string, description: string, domain: string, endpointHitsCount: int, endpoints: record, id: string, name: string, usageScenario: string, versionsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the name or description of the application.
#
# PUT /apps/{appId}
# operationId: Apps_Update
export def "apps update" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The application's new description.
  --name: string # The application's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}"))
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the available endpoint deployment regions and URLs.
#
# GET /apps/{appId}/endpoints
# operationId: Apps_ListEndpoints
export def "apps-endpoints list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/endpoints"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes a user from the allowed list of users to access this LUIS application. Users are removed using their email address.
#
# DELETE /apps/{appId}/permissions
# operationId: Permissions_Delete
export def "apps-permissions delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/permissions"))
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the list of user emails that have permissions to access your application.
#
# GET /apps/{appId}/permissions
# operationId: Permissions_List
export def "apps-permissions list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: list<string>, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a user to the allowed list of users to access this LUIS application. Users are added using their email address.
#
# POST /apps/{appId}/permissions
# operationId: Permissions_Add
export def "apps-permissions create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email address of the user.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/permissions"))
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Replaces the current users access list with the one sent in the body. If an empty list is sent, all access to other users will be removed.
#
# PUT /apps/{appId}/permissions
# operationId: Permissions_Update
export def "apps-permissions update" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string> # The email address of the users.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/permissions"))
  let req_body = {"emails": $emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Publishes a specific version of the application.
#
# POST /apps/{appId}/publish
# operationId: Apps_Publish
export def "apps-publish publish" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-staging: oneof<nothing, bool> # Indicates if the staging slot should be used, instead of the Production one. (default: false)
  --region: string # The target region that the application is published to.
  --version-id: string # The version ID to publish.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/publish"))
  let req_body = {"isStaging": $is_staging, "region": $region, "versionId": $version_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the query logs of the past month for the application.
#
# GET /apps/{appId}/querylogs
# operationId: Apps_DownloadQueryLogs
export def "apps-querylogs download-list-logs" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/querylogs"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the application settings.
#
# GET /apps/{appId}/settings
# operationId: Apps_GetSettings
export def "apps-settings get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, public: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the application settings.
#
# PUT /apps/{appId}/settings
# operationId: Apps_UpdateSettings
export def "apps-settings update" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public: oneof<nothing, bool> # Setting your application as public allows other people to use your application's endpoint using their own keys.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/settings"))
  let req_body = {"public": $public} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the application versions info.
#
# GET /apps/{appId}/versions
# operationId: Versions_List
export def "apps-versions list" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Imports a new version into a LUIS application.
#
# POST /apps/{appId}/versions/import
# operationId: Versions_Import
# --closedLists item shape: {name?: string, subLists?: list}
# --composites item shape: {children?: list<string>, name?: string}
# --entities item shape: {children?: list<string>, name?: string}
# --intents item shape: {children?: list<string>, name?: string}
# --model_features item shape: {activated?: bool, mode?: bool, name?: string, words?: string}
# --regex_features item shape: {activated?: bool, name?: string, pattern?: string}
# --utterances item shape: {entities?: list, intent?: string, text?: string}
export def "apps-versions-import import" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version-id: string # The new versionId to import. If not specified, the versionId will be read from the imported object.
  --bing-entities: list<string> # List of prebuilt intents.
  --closed-lists: list # List of closed lists. — item shape: {name?: string, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list<string>, name?: string}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list<string>, name?: string}
  --intents: list # List of intents. — item shape: {children?: list<string>, name?: string}
  --model-features: list # List of model features. — item shape: {activated?: bool, mode?: bool, name?: string, words?: string}
  --name: string # The name of the application.
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of sample utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --version-id-body: string # The version ID of the application that was exported. (body field)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let qp = [(serialize-qp "versionId" $version_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/versions/import") $qp)
  let req_body = {"bing_entities": $bing_entities, "closedLists": $closed_lists, "composites": $composites, "culture": $culture, "desc": $desc, "entities": $entities, "intents": $intents, "model_features": $model_features, "name": $name, "regex_features": $regex_features, "utterances": $utterances, "versionId": $version_id_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"versionId": $version_id} | compact), body: $req_body}
}

# Deletes an application version.
#
# DELETE /apps/{appId}/versions/{versionId}/
# operationId: Versions_Delete
export def "apps-versions delete" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the version info.
#
# GET /apps/{appId}/versions/{versionId}/
# operationId: Versions_Get
export def "apps-versions get" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignedEndpointKey: record, createdDateTime: string, endpointHitsCount: int, endpointUrl: string, entitiesCount: int, externalApiKeys: record, intentsCount: int, lastModifiedDateTime: string, lastPublishedDateTime: string, lastTrainedDateTime: string, trainingStatus: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the name or description of the application version.
#
# PUT /apps/{appId}/versions/{versionId}/
# operationId: Versions_Update
export def "apps-versions update" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The new version for the cloned model.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a new version using the current snapshot of the selected application version.
#
# POST /apps/{appId}/versions/{versionId}/clone
# operationId: Versions_Clone
export def "apps-versions-clone clone" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The new version for the cloned model.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/clone"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the closedlist models.
#
# GET /apps/{appId}/versions/{versionId}/closedlists
# operationId: Model_ListClosedLists
export def "apps-versions-closedlists list-model-closed-lists" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<subLists: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a closed list model to the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists
# operationId: Model_AddClosedList
# --subLists item shape: {canonicalForm?: string, list?: list<string>}
export def "apps-versions-closedlists create-model-closed-list" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the closed list feature.
  --sub-lists: list # Sublists for the feature. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists"))
  let req_body = {"name": $name, "subLists": $sub_lists} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a closed list model from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_DeleteClosedList
export def "apps-versions-closedlists delete-model-closed-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information of a closed list model.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_GetClosedList
export def "apps-versions-closedlists get-model-closed-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<subLists: table<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a batch of sublists to an existing closedlist.
#
# PATCH /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_PatchClosedList
# --subLists item shape: {canonicalForm?: string, list?: list<string>}
export def "apps-versions-closedlists update-model-closed-list-by-app-id-version-id-cl-entity-id" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sub-lists: list # Sublists to add. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}"))
  let req_body = {"subLists": $sub_lists} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the closed list model.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}
# operationId: Model_UpdateClosedList
# --subLists item shape: {canonicalForm?: string, list?: list<string>}
export def "apps-versions-closedlists update-model-closed-list-by-app-id-version-id-cl-entity-id-1" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new name of the closed list feature.
  --sub-lists: list # The new sublists for the feature. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}"))
  let req_body = {"name": $name, "subLists": $sub_lists} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds a list to an existing closed list.
#
# POST /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists
# operationId: Model_AddSubList
export def "apps-versions-closedlists-sublists create-model-sub-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-form: string # The standard form that the list represents.
  --list: list<string> # List of synonym words.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}/sublists"))
  let req_body = {"canonicalForm": $canonical_form, "list": $list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a sublist of a specific closed list model.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}
# operationId: Model_DeleteSubList
export def "apps-versions-closedlists-sublists delete-model-sub-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  sub_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  if ($sub_list_id | is-empty) { error make --unspanned { msg: "path parameter 'subListId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id), sub_list_id: (encode-path-segment $sub_list_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}/sublists/{sub_list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates one of the closed list's sublists.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{clEntityId}/sublists/{subListId}
# operationId: Model_UpdateSubList
export def "apps-versions-closedlists-sublists update-model-sub-list" [
  app_id: string
  version_id: string
  cl_entity_id: string
  sub_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --canonical-form: string # The standard form that the list represents.
  --list: list<string> # List of synonym words.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($cl_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'clEntityId' must be non-empty" } }
  if ($sub_list_id | is-empty) { error make --unspanned { msg: "path parameter 'subListId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), cl_entity_id: (encode-path-segment $cl_entity_id), sub_list_id: (encode-path-segment $sub_list_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{cl_entity_id}/sublists/{sub_list_id}"))
  let req_body = {"canonicalForm": $canonical_form, "list": $list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the composite entity models.
#
# GET /apps/{appId}/versions/{versionId}/compositeentities
# operationId: Model_ListCompositeEntities
export def "apps-versions-compositeentities list-model-composite-entities" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a composite entity extractor to the application.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities
# operationId: Model_AddCompositeEntity
export def "apps-versions-compositeentities create-model-composite-entity" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list<string> # Child entities.
  --name: string # Entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities"))
  let req_body = {"children": $children, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a composite entity extractor from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# operationId: Model_DeleteCompositeEntity
export def "apps-versions-compositeentities delete-model-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the composite entity model.
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# operationId: Model_GetCompositeEntity
export def "apps-versions-compositeentities get-model-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the composite entity extractor.
#
# PUT /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}
# operationId: Model_UpdateCompositeEntity
export def "apps-versions-compositeentities update-model-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list<string> # Child entities.
  --name: string # Entity name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}"))
  let req_body = {"children": $children, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a single child in an existing composite entity model.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children
# operationId: Model_AddCompositeEntityChild
export def "apps-versions-compositeentities-children create-model-composite-entity-child" [
  app_id: string
  version_id: string
  c_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/children"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a composite entity extractor child from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/children/{cChildId}
# operationId: Model_DeleteCompositeEntityChild
export def "apps-versions-compositeentities-children delete-model-composite-entity-child" [
  app_id: string
  version_id: string
  c_entity_id: string
  c_child_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  if ($c_child_id | is-empty) { error make --unspanned { msg: "path parameter 'cChildId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id), c_child_id: (encode-path-segment $c_child_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/children/{c_child_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a customizable prebuilt domain along with all of its models to this application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltdomains
# operationId: Model_AddCustomPrebuiltDomain
export def "apps-versions-customprebuiltdomains create-model-custom-prebuilt-domain" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltdomains"))
  let req_body = {"domainName": $domain_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a prebuilt domain's models from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/customprebuiltdomains/{domainName}
# operationId: Model_DeleteCustomPrebuiltDomain
export def "apps-versions-customprebuiltdomains delete-model-custom-prebuilt-domain" [
  app_id: string
  version_id: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($domain_name | is-empty) { error make --unspanned { msg: "path parameter 'domainName' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltdomains/{domain_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all custom prebuilt entities information of this application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities
# operationId: Model_ListCustomPrebuiltEntities
export def "apps-versions-customprebuiltentities list-model-custom-prebuilt-entities" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a custom prebuilt entity model to the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltentities
# operationId: Model_AddCustomPrebuiltEntity
export def "apps-versions-customprebuiltentities create-model-custom-prebuilt-entity" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --model-name: string # The intent name or entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities"))
  let req_body = {"domainName": $domain_name, "modelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets custom prebuilt intents information of this application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltintents
# operationId: Model_ListCustomPrebuiltIntents
export def "apps-versions-customprebuiltintents list-model-custom-prebuilt-intents" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltintents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a custom prebuilt intent model to the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltintents
# operationId: Model_AddCustomPrebuiltIntent
export def "apps-versions-customprebuiltintents create-model-custom-prebuilt-intent" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain-name: string # The domain name.
  --model-name: string # The intent name or entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltintents"))
  let req_body = {"domainName": $domain_name, "modelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all custom prebuilt models information of this application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltmodels
# operationId: Model_ListCustomPrebuiltModels
export def "apps-versions-customprebuiltmodels list-model-custom-prebuilt-models" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string, readableType: string, typeId: int, customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltmodels"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the entity models.
#
# GET /apps/{appId}/versions/{versionId}/entities
# operationId: Model_ListEntities
export def "apps-versions-entities list-model" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds an entity extractor to the application.
#
# POST /apps/{appId}/versions/{versionId}/entities
# operationId: Model_AddEntity
export def "apps-versions-entities create-model-entity" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the new entity extractor.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an entity extractor from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_DeleteEntity
export def "apps-versions-entities delete-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the entity model.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_GetEntity
export def "apps-versions-entities get-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the name of an entity extractor.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_UpdateEntity
export def "apps-versions-entities update-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get suggestion examples that would improve the accuracy of the entity model.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/suggest
# operationId: Model_GetEntitySuggestions
export def "apps-versions-entities-suggest get-model-entity-suggestions" [
  app_id: string
  version_id: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let qp = [(serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/suggest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"take": $take} | compact), body: null}
}

# Adds a labeled example to the application.
#
# POST /apps/{appId}/versions/{versionId}/example
# operationId: Examples_Add
# --entityLabels item shape: {endCharIndex: int, entityName: string, startCharIndex: int}
export def "apps-versions-example create" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-labels: list # The idenfied entities within the utterance. — item shape: {endCharIndex: int, entityName: string, startCharIndex: int}
  --intent-name: string # The idenfitied intent representing the utterance.
  --text: string # The sample's utterance.
]: any -> record<ExampleId: int, UtteranceText: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/example"))
  let req_body = {"entityLabels": $entity_labels, "intentName": $intent_name, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns examples to be reviewed.
#
# GET /apps/{appId}/versions/{versionId}/examples
# operationId: Examples_List
export def "apps-versions-examples list" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<entityLabels: list<record>, entityPredictions: list<record>, id: int, intentLabel: string, intentPredictions: list<record>, text: string, tokenizedText: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/examples") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a batch of labeled examples to the application.
#
# POST /apps/{appId}/versions/{versionId}/examples
# operationId: Examples_Batch
export def "apps-versions-examples create-batch" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<error: record<code: string, message: string>, hasError: bool, value: record<ExampleId: int, UtteranceText: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/examples"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the labeled example with the specified ID.
#
# DELETE /apps/{appId}/versions/{versionId}/examples/{exampleId}
# operationId: Examples_Delete
export def "apps-versions-examples delete" [
  app_id: string
  version_id: string
  example_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($example_id | is-empty) { error make --unspanned { msg: "path parameter 'exampleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), example_id: (encode-path-segment $example_id)} | format pattern "/apps/{app_id}/versions/{version_id}/examples/{example_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Exports a LUIS application to JSON format.
#
# GET /apps/{appId}/versions/{versionId}/export
# operationId: Versions_Export
export def "apps-versions-export export" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bing_entities: list<string>, closedLists: table<name: string, subLists: list>, composites: table<children: list, name: string>, culture: string, desc: string, entities: table<children: list, name: string>, intents: table<children: list, name: string>, model_features: table<activated: bool, mode: bool, name: string, words: string>, name: string, regex_features: table<activated: bool, name: string, pattern: string>, utterances: table<entities: list, intent: string, text: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/export"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all the extraction features for the specified application version.
#
# GET /apps/{appId}/versions/{versionId}/features
# operationId: Features_List
export def "apps-versions-features list" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> record<patternFeatures: table<pattern: string>, phraselistFeatures: table<isExchangeable: bool, phrases: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/features") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Gets information about the hierarchical entity models.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities
# operationId: Model_ListHierarchicalEntities
export def "apps-versions-hierarchicalentities list-model-hierarchical-entities" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<children: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a hierarchical entity extractor to the application version.
#
# POST /apps/{appId}/versions/{versionId}/hierarchicalentities
# operationId: Model_AddHierarchicalEntity
export def "apps-versions-hierarchicalentities create-model-hierarchical-entity" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list<string> # Child entities.
  --name: string # Entity name.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities"))
  let req_body = {"children": $children, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a hierarchical entity extractor from the application version.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# operationId: Model_DeleteHierarchicalEntity
export def "apps-versions-hierarchicalentities delete-model-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the hierarchical entity model.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# operationId: Model_GetHierarchicalEntity
export def "apps-versions-hierarchicalentities get-model-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the name and children of a hierarchical entity model.
#
# PUT /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
# operationId: Model_UpdateHierarchicalEntity
export def "apps-versions-hierarchicalentities update-model-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --children: list<string> # Child entities.
  --name: string # Entity name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}"))
  let req_body = {"children": $children, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a single child in an existing hierarchical entity model.
#
# POST /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children
# operationId: Model_AddHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children create-model-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/children"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a hierarchical entity extractor child from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# operationId: Model_DeleteHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children delete-model-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  h_child_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  if ($h_child_id | is-empty) { error make --unspanned { msg: "path parameter 'hChildId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id), h_child_id: (encode-path-segment $h_child_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/children/{h_child_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the hierarchical entity child model.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# operationId: Model_GetHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children get-model-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  h_child_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<readableType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  if ($h_child_id | is-empty) { error make --unspanned { msg: "path parameter 'hChildId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id), h_child_id: (encode-path-segment $h_child_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/children/{h_child_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Renames a single child in an existing hierarchical entity model.
#
# PUT /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
# operationId: Model_UpdateHierarchicalEntityChild
export def "apps-versions-hierarchicalentities-children update-model-hierarchical-entity-child" [
  app_id: string
  version_id: string
  h_entity_id: string
  h_child_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  if ($h_child_id | is-empty) { error make --unspanned { msg: "path parameter 'hChildId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id), h_child_id: (encode-path-segment $h_child_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/children/{h_child_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the intent models.
#
# GET /apps/{appId}/versions/{versionId}/intents
# operationId: Model_ListIntents
export def "apps-versions-intents list-model" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds an intent classifier to the application.
#
# POST /apps/{appId}/versions/{versionId}/intents
# operationId: Model_AddIntent
export def "apps-versions-intents create-model" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the new entity extractor.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an intent classifier from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/intents/{intentId}
# operationId: Model_DeleteIntent
export def "apps-versions-intents delete-model" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-utterances: oneof<nothing, bool> # Also delete the intent's utterances (true). Or move the utterances to the None intent (false - the default value). (default: false)
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let qp = [(serialize-qp "deleteUtterances" $delete_utterances "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"deleteUtterances": $delete_utterances} | compact), body: null}
}

# Gets information about the intent model.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}
# operationId: Model_GetIntent
export def "apps-versions-intents get-model" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customPrebuiltDomainName: string, customPrebuiltModelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the name of an intent classifier.
#
# PUT /apps/{appId}/versions/{versionId}/intents/{intentId}
# operationId: Model_UpdateIntent
export def "apps-versions-intents update-model" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Suggests examples that would improve the accuracy of the intent model.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/suggest
# operationId: Model_GetIntentSuggestions
export def "apps-versions-intents-suggest get-model-suggestions" [
  app_id: string
  version_id: string
  intent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<entityPredictions: list<record>, intentPredictions: list<record>, text: string, tokenizedText: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let qp = [(serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}/suggest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"take": $take} | compact), body: null}
}

# Gets all the available prebuilt entity extractors for the application.
#
# GET /apps/{appId}/versions/{versionId}/listprebuilts
# operationId: Model_ListPrebuiltEntities
export def "apps-versions-listprebuilts list-model-prebuilt-entities" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<description: string, examples: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/listprebuilts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the application version models.
#
# GET /apps/{appId}/versions/{versionId}/models
# operationId: Model_ListModels
export def "apps-versions-models list" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<id: string, name: string, readableType: string, typeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# [DEPRECATED NOTICE: This operation will soon be removed] Gets all the pattern features.
#
# GET /apps/{appId}/versions/{versionId}/patterns
# DEPRECATED
# operationId: Features_GetApplicationVersionPatternFeatures
@deprecated
export def "apps-versions-patterns get-features-application-features" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<pattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patterns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# [DEPRECATED NOTICE: This operation will soon be removed] Creates a new pattern feature.
#
# POST /apps/{appId}/versions/{versionId}/patterns
# DEPRECATED
# operationId: Features_CreatePatternFeature
@deprecated
export def "apps-versions-patterns create-features-feature" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the feature.
  --pattern: string # The Regular Expression to match.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patterns"))
  let req_body = {"name": $name, "pattern": $pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# [DEPRECATED NOTICE: This operation will soon be removed] Deletes a pattern feature.
#
# DELETE /apps/{appId}/versions/{versionId}/patterns/{patternId}
# DEPRECATED
# operationId: Features_DeletePatternFeature
@deprecated
export def "apps-versions-patterns delete-features-feature" [
  app_id: string
  version_id: string
  pattern_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($pattern_id | is-empty) { error make --unspanned { msg: "path parameter 'patternId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), pattern_id: (encode-path-segment $pattern_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patterns/{pattern_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# [DEPRECATED NOTICE: This operation will soon be removed] Gets the specified pattern feature's info.
#
# GET /apps/{appId}/versions/{versionId}/patterns/{patternId}
# DEPRECATED
# operationId: Features_GetPatternFeatureInfo
@deprecated
export def "apps-versions-patterns get-features-feature" [
  app_id: string
  version_id: string
  pattern_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($pattern_id | is-empty) { error make --unspanned { msg: "path parameter 'patternId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), pattern_id: (encode-path-segment $pattern_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patterns/{pattern_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# [DEPRECATED NOTICE: This operation will soon be removed] Updates the pattern, the name and the state of the pattern feature.
#
# PUT /apps/{appId}/versions/{versionId}/patterns/{patternId}
# DEPRECATED
# operationId: Features_UpdatePatternFeature
@deprecated
export def "apps-versions-patterns update-features-feature" [
  app_id: string
  version_id: string
  pattern_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-active: oneof<nothing, bool> # Indicates if the Pattern feature is enabled. (default: true)
  --name: string # Name of the feature.
  --pattern: string # The Regular Expression to match.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($pattern_id | is-empty) { error make --unspanned { msg: "path parameter 'patternId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), pattern_id: (encode-path-segment $pattern_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patterns/{pattern_id}"))
  let req_body = {"isActive": $is_active, "name": $name, "pattern": $pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all the phraselist features.
#
# GET /apps/{appId}/versions/{versionId}/phraselists
# operationId: Features_ListPhraseLists
export def "apps-versions-phraselists list-features-phrase-lists" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<isExchangeable: bool, phrases: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/phraselists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Creates a new phraselist feature.
#
# POST /apps/{appId}/versions/{versionId}/phraselists
# operationId: Features_AddPhraseList
export def "apps-versions-phraselists create-features-phrase-list" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-exchangeable: oneof<nothing, bool> # An exchangeable phrase list feature are serves as single feature to the LUIS underlying training algorithm. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t. Think of an exchangeable as a synonyms list. A non-exchangeable phrase list feature has all the phrases in the list serve as separate features to the underlying training algorithm. So, if you your phrase list feature contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-exchangeable phrase list feature as an additional bag of words that you are willing to add to LUIS existing vocabulary features. Think of a non-exchangeable as set of different words. Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/phraselists"))
  let req_body = {"isExchangeable": $is_exchangeable, "name": $name, "phrases": $phrases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a phraselist feature.
#
# DELETE /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# operationId: Features_DeletePhraseList
export def "apps-versions-phraselists delete-features-phrase-list" [
  app_id: string
  version_id: string
  phraselist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($phraselist_id | is-empty) { error make --unspanned { msg: "path parameter 'phraselistId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), phraselist_id: (encode-path-segment $phraselist_id)} | format pattern "/apps/{app_id}/versions/{version_id}/phraselists/{phraselist_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets phraselist feature info.
#
# GET /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# operationId: Features_GetPhraseList
export def "apps-versions-phraselists get-features-phrase-list" [
  app_id: string
  version_id: string
  phraselist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isExchangeable: bool, phrases: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($phraselist_id | is-empty) { error make --unspanned { msg: "path parameter 'phraselistId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), phraselist_id: (encode-path-segment $phraselist_id)} | format pattern "/apps/{app_id}/versions/{version_id}/phraselists/{phraselist_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the phrases, the state and the name of the phraselist feature.
#
# PUT /apps/{appId}/versions/{versionId}/phraselists/{phraselistId}
# operationId: Features_UpdatePhraseList
export def "apps-versions-phraselists update-features-phrase-list" [
  app_id: string
  version_id: string
  phraselist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-active: oneof<nothing, bool> # Indicates if the Phraselist is enabled. (default: true)
  --is-exchangeable: oneof<nothing, bool> # An exchangeable phrase list feature are serves as single feature to the LUIS underlying training algorithm. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t. Think of an exchangeable as a synonyms list. A non-exchangeable phrase list feature has all the phrases in the list serve as separate features to the underlying training algorithm. So, if you your phrase list feature contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-exchangeable phrase list feature as an additional bag of words that you are willing to add to LUIS existing vocabulary features. Think of a non-exchangeable as set of different words. Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($phraselist_id | is-empty) { error make --unspanned { msg: "path parameter 'phraselistId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), phraselist_id: (encode-path-segment $phraselist_id)} | format pattern "/apps/{app_id}/versions/{version_id}/phraselists/{phraselist_id}"))
  let req_body = {"isActive": $is_active, "isExchangeable": $is_exchangeable, "name": $name, "phrases": $phrases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the prebuilt entity models.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts
# operationId: Model_ListPrebuilts
export def "apps-versions-prebuilts list-model" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a list of prebuilt entity extractors to the application.
#
# POST /apps/{appId}/versions/{versionId}/prebuilts
# operationId: Model_AddPrebuilt
export def "apps-versions-prebuilts create-model" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a prebuilt entity extractor from the application.
#
# DELETE /apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}
# operationId: Model_DeletePrebuilt
export def "apps-versions-prebuilts delete-model" [
  app_id: string
  version_id: string
  prebuilt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($prebuilt_id | is-empty) { error make --unspanned { msg: "path parameter 'prebuiltId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), prebuilt_id: (encode-path-segment $prebuilt_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{prebuilt_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the prebuilt entity model.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{prebuiltId}
# operationId: Model_GetPrebuilt
export def "apps-versions-prebuilts get-model" [
  app_id: string
  version_id: string
  prebuilt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($prebuilt_id | is-empty) { error make --unspanned { msg: "path parameter 'prebuiltId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), prebuilt_id: (encode-path-segment $prebuilt_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{prebuilt_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deleted an unlabelled utterance.
#
# DELETE /apps/{appId}/versions/{versionId}/suggest
# operationId: Versions_DeleteUnlabelledUtterance
export def "apps-versions-suggest delete-unlabelled-utterance" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/suggest"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the training status of all models (intents and entities) for the specified LUIS app. You must call the train API to train the LUIS app before you call this API to get training status. "appID" specifies the LUIS app ID. "versionId" specifies the version number of the LUIS app. For example, "0.1".
#
# GET /apps/{appId}/versions/{versionId}/train
# operationId: Train_GetStatus
export def "apps-versions-train get-status" [
  app_id: string
  version_id: string
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
]: nothing -> table<details: record<exampleCount: int, failureReason: string, status: string, statusId: int, trainingDateTime: string>, modelId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/train"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sends a training request for a version of a specified LUIS app. This POST request initiates a request asynchronously. To determine whether the training request is successful, submit a GET request to get training status. Note: The application version is not fully trained unless all the models (intents and entities) are trained successfully or are up to date. To verify training success, get the training status at least once after training is complete.
#
# POST /apps/{appId}/versions/{versionId}/train
# operationId: Train_TrainVersion
export def "apps-versions-train version" [
  app_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, statusId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/train"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
