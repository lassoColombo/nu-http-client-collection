# Auto-generated client for LUIS Authoring Client v3.0-preview
# Source: https://api.apis.guru/v2/specs/azure.com/cognitiveservices-LUIS-Authoring/3.0-preview/swagger.json
# Auth: --token flag or $env.LUIS_AUTHORING_CLIENT_TOKEN

const BASE_URL = "{Endpoint}/luis/authoring/v3.0-preview"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LUIS_AUTHORING_CLIENT_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["{Endpoint}/luis/authoring/v3.0-preview"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def accept-completer [] { ["JSON" "application/json"] }
def accept-completer-1 [] { ["application/json" "application/octet-stream"] }

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

# Lists all of the user's applications.
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
]: any -> oneof<string, record, nothing> {
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

# Gets a list of supported cultures. Cultures are equivalent to the written language and locale. For example,"en-us" represents the U.S. variation of English.
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

# Adds a prebuilt domain along with its intent and entity models as a new application.
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
]: any -> oneof<string, record, nothing> {
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

# Gets all the available prebuilt domains for a specific culture.
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

# Imports an application to LUIS, the application's structure is included in the request body.
#
# POST /apps/import
# operationId: Apps_Import
# --closedLists item shape: {name?: string, roles?: list<string>, subLists?: list}
# --composites item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --entities item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --hierarchicals item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --intents item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --patternAnyEntities item shape: {explicitList?: list<string>, name?: string, roles?: list<string>}
# --patterns item shape: {intent?: string, pattern?: string}
# --phraselists item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
# --prebuiltEntities item shape: {name?: string, roles?: list<string>}
# --regex_entities item shape: {name?: string, regexPattern?: string, roles?: list<string>}
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
  --app-name: string # The application name to create. If not specified, the application name will be read from the imported object. If the application name already exists, an error is returned.
  --closed-lists: list # List of list entities. — item shape: {name?: string, roles?: list<string>, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --hierarchicals: list # List of hierarchical entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --intents: list # List of intents. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --name: string # The name of the application.
  --pattern-any-entities: list # List of Pattern.Any entities. — item shape: {explicitList?: list<string>, name?: string, roles?: list<string>}
  --patterns: list # List of patterns. — item shape: {intent?: string, pattern?: string}
  --phraselists: list # List of model features. — item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
  --prebuilt-entities: list # List of prebuilt entities. — item shape: {name?: string, roles?: list<string>}
  --regex-entities: list # List of regular expression entities. — item shape: {name?: string, regexPattern?: string, roles?: list<string>}
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of example utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --version-id: string # The version ID of the application that was exported.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appName" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/import" $qp)
  let req_body = {"closedLists": $closed_lists, "composites": $composites, "culture": $culture, "desc": $desc, "entities": $entities, "hierarchicals": $hierarchicals, "intents": $intents, "name": $name, "patternAnyEntities": $pattern_any_entities, "patterns": $patterns, "phraselists": $phraselists, "prebuiltEntities": $prebuilt_entities, "regex_entities": $regex_entities, "regex_features": $regex_features, "utterances": $utterances, "versionId": $version_id} | compact
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
  --force: oneof<nothing, bool> # A flag to indicate whether to force an operation. (default: false)
]: nothing -> record<code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"force": $force} | compact), body: null}
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

# apps - Removes an assigned LUIS Azure account from an application
#
# DELETE /apps/{appId}/azureaccounts
# operationId: AzureAccounts_RemoveFromApp
export def "apps-azureaccounts delete-azure-accounts" [
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
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
  account_name: string # The Azure account name.
  azure_subscription_id: string # The id for the Azure subscription.
  resource_group: string # The Azure resource group name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/azureaccounts"))
  let req_body = {"accountName": $account_name, "azureSubscriptionId": $azure_subscription_id, "resourceGroup": $resource_group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# apps - Get LUIS Azure accounts assigned to the application
#
# GET /apps/{appId}/azureaccounts
# operationId: AzureAccounts_GetAssigned
export def "apps-azureaccounts get-azure-accounts-assigned" [
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
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
]: nothing -> table<accountName: string, azureSubscriptionId: string, resourceGroup: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/azureaccounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# apps - Assign a LUIS Azure account to an application
#
# POST /apps/{appId}/azureaccounts
# operationId: AzureAccounts_AssignToApp
export def "apps-azureaccounts assign-azure-accounts" [
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
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
  account_name: string # The Azure account name.
  azure_subscription_id: string # The id for the Azure subscription.
  resource_group: string # The Azure resource group name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/azureaccounts"))
  let req_body = {"accountName": $account_name, "azureSubscriptionId": $azure_subscription_id, "resourceGroup": $resource_group} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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

# Replaces the current user access list with the new list sent in the body. If an empty list is sent, all access to other users will be removed.
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
  --version-id: string # The version ID to publish.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/publish"))
  let req_body = {"isStaging": $is_staging, "versionId": $version_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the application publish settings including 'UseAllTrainingData'.
#
# GET /apps/{appId}/publishsettings
# operationId: Apps_GetPublishSettings
export def "apps-publishsettings get-publish-settings" [
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
]: nothing -> record<id: string, sentimentAnalysis: bool, speech: bool, spellChecker: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/publishsettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the application publish settings including 'UseAllTrainingData'.
#
# PUT /apps/{appId}/publishsettings
# operationId: Apps_UpdatePublishSettings
export def "apps-publishsettings update-publish-settings" [
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
  --sentiment-analysis: oneof<nothing, bool> # Setting sentiment analysis as true returns the Sentiment of the input utterance along with the response
  --speech: oneof<nothing, bool> # Setting speech as public enables speech priming in your app
  --spell-checker: oneof<nothing, bool> # Setting spell checker as public enables spell checking the input utterance.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/publishsettings"))
  let req_body = {"sentimentAnalysis": $sentiment_analysis, "speech": $speech, "spellChecker": $spell_checker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the logs of the past month's endpoint queries for the application.
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

# Get the application settings including 'UseAllTrainingData'.
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

# Updates the application settings including 'UseAllTrainingData'.
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

# Gets a list of versions for this application ID.
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
# --closedLists item shape: {name?: string, roles?: list<string>, subLists?: list}
# --composites item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --entities item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --hierarchicals item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --intents item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
# --patternAnyEntities item shape: {explicitList?: list<string>, name?: string, roles?: list<string>}
# --patterns item shape: {intent?: string, pattern?: string}
# --phraselists item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
# --prebuiltEntities item shape: {name?: string, roles?: list<string>}
# --regex_entities item shape: {name?: string, regexPattern?: string, roles?: list<string>}
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
  --closed-lists: list # List of list entities. — item shape: {name?: string, roles?: list<string>, subLists?: list}
  --composites: list # List of composite entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --culture: string # The culture of the application. E.g.: en-us.
  --desc: string # The description of the application.
  --entities: list # List of entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --hierarchicals: list # List of hierarchical entities. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --intents: list # List of intents. — item shape: {children?: list, features?: list, inherits?: record, name?: string, roles?: list<string>}
  --name: string # The name of the application.
  --pattern-any-entities: list # List of Pattern.Any entities. — item shape: {explicitList?: list<string>, name?: string, roles?: list<string>}
  --patterns: list # List of patterns. — item shape: {intent?: string, pattern?: string}
  --phraselists: list # List of model features. — item shape: {activated?: bool, enabledForAllModels?: bool, mode?: bool, name?: string, words?: string}
  --prebuilt-entities: list # List of prebuilt entities. — item shape: {name?: string, roles?: list<string>}
  --regex-entities: list # List of regular expression entities. — item shape: {name?: string, regexPattern?: string, roles?: list<string>}
  --regex-features: list # List of pattern features. — item shape: {activated?: bool, name?: string, pattern?: string}
  --utterances: list # List of example utterances. — item shape: {entities?: list, intent?: string, text?: string}
  --version-id-body: string # The version ID of the application that was exported. (body field)
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  let qp = [(serialize-qp "versionId" $version_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/versions/import") $qp)
  let req_body = {"closedLists": $closed_lists, "composites": $composites, "culture": $culture, "desc": $desc, "entities": $entities, "hierarchicals": $hierarchicals, "intents": $intents, "name": $name, "patternAnyEntities": $pattern_any_entities, "patterns": $patterns, "phraselists": $phraselists, "prebuiltEntities": $prebuilt_entities, "regex_entities": $regex_entities, "regex_features": $regex_features, "utterances": $utterances, "versionId": $version_id_body} | compact
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

# Gets the version information such as date created, last modified date, endpoint URL, count of intents and entities, training and publishing status.
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

# Creates a new version from the selected version.
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
]: any -> oneof<string, record, nothing> {
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

# Gets information about all the list entity models in a version of the application.
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

# Adds a list entity model to a version of the application.
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
  --name: string # Name of the list entity.
  --sub-lists: list # Sublists for the feature. — item shape: {canonicalForm?: string, list?: list<string>}
]: any -> oneof<string, record, nothing> {
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

# Deletes a list entity model from a version of the application.
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

# Gets information about a list entity in a version of the application.
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

# Adds a batch of sublists to an existing list entity in a version of the application.
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

# Updates the list entity in a version of the application.
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
  --name: string # The new name of the list entity.
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

# Adds a sublist to an existing list entity in a version of the application.
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
]: any -> oneof<int, string, record, nothing> {
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

# Deletes a sublist of a specific list entity model from a version of the application.
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

# Updates one of the list entity's sublists in a version of the application.
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

# Get all roles for a list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles
# operationId: Model_ListClosedListEntityRoles
export def "apps-versions-closedlists-roles list-model-closed-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for a list entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles
# operationId: Model_CreateClosedListEntityRole
export def "apps-versions-closedlists-roles create-model-closed-list-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role for a given list entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# operationId: Model_DeleteClosedListEntityRole
export def "apps-versions-closedlists-roles delete-model-closed-list-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given list entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# operationId: Model_GetClosedListEntityRole
export def "apps-versions-closedlists-roles get-model-closed-list-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given list entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/closedlists/{entityId}/roles/{roleId}
# operationId: Model_UpdateClosedListEntityRole
export def "apps-versions-closedlists-roles update-model-closed-list-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/closedlists/{entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about all the composite entity models in a version of the application.
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

# Deletes a composite entity from a version of the application.
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

# Gets information about a composite entity in a version of the application.
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
]: nothing -> record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>> {
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

# Updates a composite entity in a version of the application.
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

# Creates a single child in an existing composite entity model in a version of the application.
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
]: any -> oneof<string, record, nothing> {
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

# Deletes a composite entity extractor child from a version of the application.
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

# Get all roles for a composite entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles
# operationId: Model_ListCompositeEntityRoles
export def "apps-versions-compositeentities-roles list-model-composite-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for a composite entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles
# operationId: Model_CreateCompositeEntityRole
export def "apps-versions-compositeentities-roles create-model-composite-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role for a given composite entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# operationId: Model_DeleteCompositeEntityRole
export def "apps-versions-compositeentities-roles delete-model-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given composite entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# operationId: Model_GetCompositeEntityRole
export def "apps-versions-compositeentities-roles get-model-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given composite entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/compositeentities/{cEntityId}/roles/{roleId}
# operationId: Model_UpdateCompositeEntityRole
export def "apps-versions-compositeentities-roles update-model-composite-entity" [
  app_id: string
  version_id: string
  c_entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($c_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'cEntityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), c_entity_id: (encode-path-segment $c_entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/compositeentities/{c_entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds a customizable prebuilt domain along with all of its intent and entity models in a version of the application.
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

# Deletes a prebuilt domain's models in a version of the application.
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

# Gets all prebuilt entities used in a version of the application.
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

# Adds a prebuilt entity model to a version of the application.
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
]: any -> oneof<string, record, nothing> {
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

# Get all roles for a prebuilt entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles
# operationId: Model_ListCustomPrebuiltEntityRoles
export def "apps-versions-customprebuiltentities-roles list-model-custom-prebuilt-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities/{entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for a prebuilt entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles
# operationId: Model_CreateCustomPrebuiltEntityRole
export def "apps-versions-customprebuiltentities-roles create-model-custom-prebuilt-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities/{entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role for a given prebuilt entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# operationId: Model_DeleteCustomEntityRole
export def "apps-versions-customprebuiltentities-roles delete-model-custom-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given prebuilt entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# operationId: Model_GetCustomEntityRole
export def "apps-versions-customprebuiltentities-roles get-model-custom-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given prebuilt entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/customprebuiltentities/{entityId}/roles/{roleId}
# operationId: Model_UpdateCustomPrebuiltEntityRole
export def "apps-versions-customprebuiltentities-roles update-model-custom-prebuilt-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/customprebuiltentities/{entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about customizable prebuilt intents added to a version of the application.
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

# Adds a customizable prebuilt intent model to a version of the application.
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
]: any -> oneof<string, record, nothing> {
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

# Gets all prebuilt intent and entity model information used in a version of this application.
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

# Gets information about all the simple entity models in a version of the application.
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
]: nothing -> table<children: list<record>, customPrebuiltDomainName: string, customPrebuiltModelName: string> {
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

# Adds an entity extractor to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities
# operationId: Model_AddEntity
# --children item shape: {children?: list, instanceOf?: string, name?: string}
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
  --children: list # Child entities. — item shape: {children?: list, instanceOf?: string, name?: string}
  --name: string # Entity name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities"))
  let req_body = {"children": $children, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an entity or a child from a version of the application.
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

# Gets information about an entity model in a version of the application.
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
]: nothing -> record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>, customPrebuiltDomainName: string, customPrebuiltModelName: string> {
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

# Updates the name of an entity extractor or the name and instanceOf model of a child entity extractor.
#
# PATCH /apps/{appId}/versions/{versionId}/entities/{entityId}
# operationId: Model_UpdateEntityChild
export def "apps-versions-entities update-model-entity-child" [
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
  --instance-of: string # The instance of model name
  --name: string # Entity name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}"))
  let req_body = {"instanceOf": $instance_of, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates a single child in an existing entity model hierarchy in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/children
# operationId: Model_AddEntityChild
# --children item shape: {children?: list, instanceOf?: string, name?: string}
export def "apps-versions-entities-children create-model-entity-child" [
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
  --children: list # Child entities. — item shape: {children?: list, instanceOf?: string, name?: string}
  --instance-of: string # The instance of model name
  --name: string # Entity name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/children"))
  let req_body = {"children": $children, "instanceOf": $instance_of, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a relation from the feature relations used by the entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Model_DeleteEntityFeature
export def "apps-versions-entities-features delete-model-entity" [
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
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/features"))
  let req_body = {"featureName": $feature_name, "modelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the information of the features used by the entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Model_GetEntityFeatures
export def "apps-versions-entities-features get-model-entity" [
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
]: nothing -> table<featureName: string, modelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/features"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a new feature relation to be used by the entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Features_AddEntityFeature
export def "apps-versions-entities-features create-entity" [
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
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/features"))
  let req_body = {"featureName": $feature_name, "modelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the information of the features used by the entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}/features
# operationId: Model_ReplaceEntityFeatures
export def "apps-versions-entities-features update-model-entity" [
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
  --body: list
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/features"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all roles for an entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/roles
# operationId: Model_ListEntityRoles
export def "apps-versions-entities-roles list-model-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an entity role in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/entities/{entityId}/roles
# operationId: Model_CreateEntityRole
export def "apps-versions-entities-roles create-model-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an entity role in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# operationId: Model_DeleteEntityRole
export def "apps-versions-entities-roles delete-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# operationId: Model_GetEntityRole
export def "apps-versions-entities-roles get-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/entities/{entityId}/roles/{roleId}
# operationId: Model_UpdateEntityRole
export def "apps-versions-entities-roles update-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/entities/{entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get suggested example utterances that would improve the accuracy of the entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/entities/{entityId}/suggest
# operationId: Model_ListEntitySuggestions
export def "apps-versions-entities-suggest list-model-entity-suggestions" [
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

# Adds a labeled example utterance in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/example
# operationId: Examples_Add
# --entityLabels item shape: {endCharIndex: int, entityName: string, role?: string, startCharIndex: int}
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
  --entity-labels: list # The identified entities within the example utterance. — item shape: {endCharIndex: int, entityName: string, role?: string, startCharIndex: int}
  --intent-name: string # The identified intent representing the example utterance.
  --text: string # The example utterance.
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

# Returns example utterances to be reviewed from a version of the application.
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

# Adds a batch of labeled example utterances to a version of the application.
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

# Deletes the labeled example utterances with the specified ID from a version of the application.
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
]: nothing -> record<closedLists: table<name: string, roles: list, subLists: list>, composites: table<children: list, features: list, inherits: record, name: string, roles: list>, culture: string, desc: string, entities: table<children: list, features: list, inherits: record, name: string, roles: list>, hierarchicals: table<children: list, features: list, inherits: record, name: string, roles: list>, intents: table<children: list, features: list, inherits: record, name: string, roles: list>, name: string, patternAnyEntities: table<explicitList: list, name: string, roles: list>, patterns: table<intent: string, pattern: string>, phraselists: table<activated: bool, enabledForAllModels: bool, mode: bool, name: string, words: string>, prebuiltEntities: table<name: string, roles: list>, regex_entities: table<name: string, regexPattern: string, roles: list>, regex_features: table<activated: bool, name: string, pattern: string>, utterances: table<entities: list, intent: string, text: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/export"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all the extraction phraselist and pattern features in a version of the application.
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

# Gets information about all the hierarchical entity models in a version of the application.
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

# Deletes a hierarchical entity from a version of the application.
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

# Gets information about a hierarchical entity in a version of the application.
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
]: nothing -> record<children: table<children: list, id: string, instanceOf: string, name: string, readableType: string, typeId: int>> {
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

# Updates the name of a hierarchical entity model in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}
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
  --name: string # The entity's new name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a hierarchical entity extractor child in a version of the application.
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

# Gets information about the child's model contained in an hierarchical entity child model in a version of the application.
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

# Renames a single child in an existing hierarchical entity model in a version of the application.
#
# PATCH /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/children/{hChildId}
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
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all roles for a hierarchical entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles
# operationId: Model_ListHierarchicalEntityRoles
export def "apps-versions-hierarchicalentities-roles list-model-hierarchical-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for an hierarchical entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles
# operationId: Model_CreateHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles create-model-hierarchical-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role for a given hierarchical role in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# operationId: Model_DeleteHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles delete-model-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given hierarchical entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# operationId: Model_GetHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles get-model-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given hierarchical entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/hierarchicalentities/{hEntityId}/roles/{roleId}
# operationId: Model_UpdateHierarchicalEntityRole
export def "apps-versions-hierarchicalentities-roles update-model-hierarchical-entity" [
  app_id: string
  version_id: string
  h_entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($h_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'hEntityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), h_entity_id: (encode-path-segment $h_entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/hierarchicalentities/{h_entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about the intent models in a version of the application.
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

# Adds an intent to a version of the application.
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
]: any -> oneof<string, record, nothing> {
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

# Deletes an intent from a version of the application.
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
  --delete-utterances: oneof<nothing, bool> # If true, deletes the intent's example utterances. If false, moves the example utterances to the None intent. The default value is false. (default: false)
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

# Gets information about the intent model in a version of the application.
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

# Updates the name of an intent in a version of the application.
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

# Deletes a relation from the feature relations used by the intent in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Model_DeleteIntentFeature
export def "apps-versions-intents-features delete-model" [
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
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}/features"))
  let req_body = {"featureName": $feature_name, "modelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the information of the features used by the intent in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Model_GetIntentFeatures
export def "apps-versions-intents-features get-model" [
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
]: nothing -> table<featureName: string, modelName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}/features"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Adds a new feature relation to be used by the intent in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Features_AddIntentFeature
export def "apps-versions-intents-features create" [
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
  --feature-name: string # The name of the feature used.
  --model-name: string # The name of the model used.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}/features"))
  let req_body = {"featureName": $feature_name, "modelName": $model_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates the information of the features used by the intent in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/intents/{intentId}/features
# operationId: Model_ReplaceIntentFeatures
export def "apps-versions-intents-features update-model" [
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
  --body: list
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}/features"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns patterns for the specific intent in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/patternrules
# operationId: Pattern_ListIntentPatterns
export def "apps-versions-intents-patternrules list-pattern-patterns" [
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
  --skip: int # The number of entries to skip. Default value is 0. (default: 0)
  --take: int # The number of entries to return. Maximum page size is 500. Default is 100. (default: 100)
]: nothing -> table<id: string, intent: string, pattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($intent_id | is-empty) { error make --unspanned { msg: "path parameter 'intentId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), intent_id: (encode-path-segment $intent_id)} | format pattern "/apps/{app_id}/versions/{version_id}/intents/{intent_id}/patternrules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Suggests example utterances that would improve the accuracy of the intent model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/intents/{intentId}/suggest
# operationId: Model_ListIntentSuggestions
export def "apps-versions-intents-suggest list-model-suggestions" [
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

# Gets all the available prebuilt entities in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/listprebuilts
# operationId: Model_ListPrebuiltEntities
export def "apps-versions-list-prebuilts list-model-entities" [
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

# Gets information about all the intent and entity models in a version of the application.
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

# Gets the example utterances for the given intent or entity model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/models/{modelId}/examples
# operationId: Model_Examples
export def "apps-versions-models-examples get" [
  app_id: string
  version_id: string
  model_id: string
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
]: nothing -> table<id: int, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), model_id: (encode-path-segment $model_id)} | format pattern "/apps/{app_id}/versions/{version_id}/models/{model_id}/examples") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Get information about the Pattern.Any entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities
# operationId: Model_ListPatternAnyEntityInfos
export def "apps-versions-patternanyentities list-model-pattern-any-entity-infos" [
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
]: nothing -> table<explicitList: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a pattern.any entity extractor to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities
# operationId: Model_CreatePatternAnyEntityModel
export def "apps-versions-patternanyentities create-model-pattern-any-entity-model" [
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
  --explicit-list: list<string> # The Pattern.Any explicit list.
  --name: string # The model name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities"))
  let req_body = {"explicitList": $explicit_list, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Pattern.Any entity extractor from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# operationId: Model_DeletePatternAnyEntityModel
export def "apps-versions-patternanyentities delete-model-pattern-any-entity-model" [
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about the Pattern.Any model in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# operationId: Model_GetPatternAnyEntityInfo
export def "apps-versions-patternanyentities get-model-pattern-any-entity" [
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
]: nothing -> record<explicitList: table<explicitListItem: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the name and explicit (exception) list of a Pattern.Any entity model in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}
# operationId: Model_UpdatePatternAnyEntityModel
export def "apps-versions-patternanyentities update-model-pattern-any-entity-model" [
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
  --explicit-list: list<string> # The Pattern.Any explicit list.
  --name: string # The model name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}"))
  let req_body = {"explicitList": $explicit_list, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the explicit (exception) list of the pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist
# operationId: Model_GetExplicitList
export def "apps-versions-patternanyentities-explicitlist get-model-explicit-list" [
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
]: nothing -> table<explicitListItem: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/explicitlist"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new exception to the explicit list for the Pattern.Any entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist
# operationId: Model_AddExplicitListItem
export def "apps-versions-patternanyentities-explicitlist create-model-explicit-list-item" [
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
  --explicit-list-item: string # The explicit list item.
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/explicitlist"))
  let req_body = {"explicitListItem": $explicit_list_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an item from the explicit (exception) list for a Pattern.any entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# operationId: Model_DeleteExplicitListItem
export def "apps-versions-patternanyentities-explicitlist delete-model-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  item_id: int
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
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), item_id: (encode-path-segment $item_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/explicitlist/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the explicit (exception) list of the pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# operationId: Model_GetExplicitListItem
export def "apps-versions-patternanyentities-explicitlist get-model-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<explicitListItem: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), item_id: (encode-path-segment $item_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/explicitlist/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an explicit (exception) list item for a Pattern.Any entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/explicitlist/{itemId}
# operationId: Model_UpdateExplicitListItem
export def "apps-versions-patternanyentities-explicitlist update-model-explicit-list-item" [
  app_id: string
  version_id: string
  entity_id: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --explicit-list-item: string # The explicit list item.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), item_id: (encode-path-segment $item_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/explicitlist/{item_id}"))
  let req_body = {"explicitListItem": $explicit_list_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all roles for a Pattern.any entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles
# operationId: Model_ListPatternAnyEntityRoles
export def "apps-versions-patternanyentities-roles list-model-pattern-any-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for an Pattern.any entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles
# operationId: Model_CreatePatternAnyEntityRole
export def "apps-versions-patternanyentities-roles create-model-pattern-any-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role for a given Pattern.any entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# operationId: Model_DeletePatternAnyEntityRole
export def "apps-versions-patternanyentities-roles delete-model-pattern-any-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given Pattern.any entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# operationId: Model_GetPatternAnyEntityRole
export def "apps-versions-patternanyentities-roles get-model-pattern-any-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given Pattern.any entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternanyentities/{entityId}/roles/{roleId}
# operationId: Model_UpdatePatternAnyEntityRole
export def "apps-versions-patternanyentities-roles update-model-pattern-any-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternanyentities/{entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Adds a pattern to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternrule
# operationId: Pattern_AddPattern
export def "apps-versions-patternrule create-pattern-pattern" [
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
  --intent: string # The intent's name which the pattern belongs to.
  --pattern: string # The pattern text.
]: any -> record<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrule"))
  let req_body = {"intent": $intent, "pattern": $pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a list of patterns in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_DeletePatterns
export def "apps-versions-patternrules delete-pattern-patterns" [
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
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrules"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets patterns in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_ListPatterns
export def "apps-versions-patternrules list-pattern-patterns" [
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
]: nothing -> table<id: string, intent: string, pattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrules") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a batch of patterns in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_BatchAddPatterns
export def "apps-versions-patternrules create-pattern-batch-patterns" [
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
]: any -> table<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrules"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Updates patterns in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternrules
# operationId: Pattern_UpdatePatterns
export def "apps-versions-patternrules update-pattern-patterns" [
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
]: any -> table<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrules"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes the pattern with the specified ID from a version of the application..
#
# DELETE /apps/{appId}/versions/{versionId}/patternrules/{patternId}
# operationId: Pattern_DeletePattern
export def "apps-versions-patternrules delete-pattern-pattern" [
  app_id: string
  version_id: string
  pattern_id: string
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
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), pattern_id: (encode-path-segment $pattern_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrules/{pattern_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates a pattern in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/patternrules/{patternId}
# operationId: Pattern_UpdatePattern
export def "apps-versions-patternrules update-pattern-pattern" [
  app_id: string
  version_id: string
  pattern_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The pattern ID. (format: uuid)
  --intent: string # The intent's name which the pattern belongs to.
  --pattern: string # The pattern text.
]: any -> record<id: string, intent: string, pattern: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($pattern_id | is-empty) { error make --unspanned { msg: "path parameter 'patternId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), pattern_id: (encode-path-segment $pattern_id)} | format pattern "/apps/{app_id}/versions/{version_id}/patternrules/{pattern_id}"))
  let req_body = {"id": $id, "intent": $intent, "pattern": $pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets all the phraselist features in a version of the application.
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

# Creates a new phraselist feature in a version of the application.
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
  --enabled-for-all-models: oneof<nothing, bool> # Indicates if the Phraselist is enabled for all models in the application. (default: true)
  --is-exchangeable: oneof<nothing, bool> # An interchangeable phrase list feature serves as a list of synonyms for training. A non-exchangeable phrase list serves as separate features for training. So, if your non-interchangeable phrase list contains 5 phrases, they will be mapped to 5 separate features. You can think of the non-interchangeable phrase list as an additional bag of words to add to LUIS existing vocabulary features. It is used as a lexicon lookup feature where its value is 1 if the lexicon contains a given word or 0 if it doesn’t. Default value is true. (default: true)
  --name: string # The Phraselist name.
  --phrases: string # List of comma-separated phrases that represent the Phraselist.
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/phraselists"))
  let req_body = {"enabledForAllModels": $enabled_for_all_models, "isExchangeable": $is_exchangeable, "name": $name, "phrases": $phrases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a phraselist feature from a version of the application.
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

# Gets phraselist feature info in a version of the application.
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

# Updates the phrases, the state and the name of the phraselist feature in a version of the application.
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
  --enabled-for-all-models: oneof<nothing, bool> # Indicates if the Phraselist is enabled for all models in the application. (default: true)
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
  let req_body = {"enabledForAllModels": $enabled_for_all_models, "isActive": $is_active, "isExchangeable": $is_exchangeable, "name": $name, "phrases": $phrases} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets information about all the prebuilt entities in a version of the application.
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

# Adds a list of prebuilt entities to a version of the application.
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

# Get a prebuilt entity's roles in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles
# operationId: Model_ListPrebuiltEntityRoles
export def "apps-versions-prebuilts-roles list-model-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for a prebuilt entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles
# operationId: Model_CreatePrebuiltEntityRole
export def "apps-versions-prebuilts-roles create-model-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role in a prebuilt entity in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# operationId: Model_DeletePrebuiltEntityRole
export def "apps-versions-prebuilts-roles delete-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given prebuilt entity in a version of the application
#
# GET /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# operationId: Model_GetPrebuiltEntityRole
export def "apps-versions-prebuilts-roles get-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given prebuilt entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/prebuilts/{entityId}/roles/{roleId}
# operationId: Model_UpdatePrebuiltEntityRole
export def "apps-versions-prebuilts-roles update-model-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/prebuilts/{entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a prebuilt entity extractor from a version of the application.
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

# Gets information about a prebuilt entity model in a version of the application.
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

# Gets information about the regular expression entity models in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities
# operationId: Model_ListRegexEntityInfos
export def "apps-versions-regexentities list-model-regex-entity-infos" [
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
]: nothing -> table<regexPattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let qp = [(serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"skip": $skip, "take": $take} | compact), body: null}
}

# Adds a regular expression entity model to a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/regexentities
# operationId: Model_CreateRegexEntityModel
export def "apps-versions-regexentities create-model-regex-entity-model" [
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
  --name: string # The model name.
  --regex-pattern: string # The regular expression entity pattern.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities"))
  let req_body = {"name": $name, "regexPattern": $regex_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all roles for a regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles
# operationId: Model_ListRegexEntityRoles
export def "apps-versions-regexentities-roles list-model-regex-entity" [
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
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{entity_id}/roles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a role for an regular expression entity in a version of the application.
#
# POST /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles
# operationId: Model_CreateRegexEntityRole
export def "apps-versions-regexentities-roles create-model-regex-entity" [
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
  --name: string # The entity role name.
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{entity_id}/roles"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a role for a given regular expression in a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# operationId: Model_DeleteRegexEntityRole
export def "apps-versions-regexentities-roles delete-model-regex-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
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
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get one role for a given regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# operationId: Model_GetRegexEntityRole
export def "apps-versions-regexentities-roles get-model-regex-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{entity_id}/roles/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role for a given regular expression entity in a version of the application
#
# PUT /apps/{appId}/versions/{versionId}/regexentities/{entityId}/roles/{roleId}
# operationId: Model_UpdateRegexEntityRole
export def "apps-versions-regexentities-roles update-model-regex-entity" [
  app_id: string
  version_id: string
  entity_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The entity role name.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'roleId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), entity_id: (encode-path-segment $entity_id), role_id: (encode-path-segment $role_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{entity_id}/roles/{role_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a regular expression entity from a version of the application.
#
# DELETE /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# operationId: Model_DeleteRegexEntityModel
export def "apps-versions-regexentities delete-model-regex-entity-model" [
  app_id: string
  version_id: string
  regex_entity_id: string
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
  if ($regex_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'regexEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), regex_entity_id: (encode-path-segment $regex_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{regex_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets information about a regular expression entity in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# operationId: Model_GetRegexEntityEntityInfo
export def "apps-versions-regexentities get-model-regex-entity-entity" [
  app_id: string
  version_id: string
  regex_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<regexPattern: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($regex_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'regexEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), regex_entity_id: (encode-path-segment $regex_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{regex_entity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the regular expression entity in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/regexentities/{regexEntityId}
# operationId: Model_UpdateRegexEntityModel
export def "apps-versions-regexentities update-model-regex-entity-model" [
  app_id: string
  version_id: string
  regex_entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The model name.
  --regex-pattern: string # The regular expression entity pattern.
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  if ($regex_entity_id | is-empty) { error make --unspanned { msg: "path parameter 'regexEntityId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id), regex_entity_id: (encode-path-segment $regex_entity_id)} | format pattern "/apps/{app_id}/versions/{version_id}/regexentities/{regex_entity_id}"))
  let req_body = {"name": $name, "regexPattern": $regex_pattern} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gets the settings in a version of the application.
#
# GET /apps/{appId}/versions/{versionId}/settings
# operationId: Settings_List
export def "apps-versions-settings list" [
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
]: nothing -> table<name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates the settings in a version of the application.
#
# PUT /apps/{appId}/versions/{versionId}/settings
# operationId: Settings_Update
export def "apps-versions-settings update" [
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
]: any -> record<code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/apps/{app_id}/versions/{version_id}/settings"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deleted an unlabelled utterance in a version of the application.
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

# user - Get LUIS Azure accounts
#
# GET /azureaccounts
# operationId: AzureAccounts_ListUserLUISAccounts
export def "azureaccounts list-azure-accounts-user-luis-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The bearer authorization header to use; containing the user's ARM token used to validate Azure accounts information.
]: nothing -> table<accountName: string, azureSubscriptionId: string, resourceGroup: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/azureaccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# package - Gets published LUIS application package in binary stream GZip format
#
# GET /package/{appId}/slot/{slotName}/gzip
# operationId: Apps_PackagePublishedApplicationAsGzip
export def "package-slot-gzip get-apps-published-application" [
  app_id: string
  slot_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($slot_name | is-empty) { error make --unspanned { msg: "path parameter 'slotName' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), slot_name: (encode-path-segment $slot_name)} | format pattern "/package/{app_id}/slot/{slot_name}/gzip"))
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# package - Gets trained LUIS application package in binary stream GZip format
#
# GET /package/{appId}/versions/{versionId}/gzip
# operationId: Apps_PackageTrainedApplicationAsGzip
export def "package-versions-gzip get-apps-trained-application" [
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
  --accept: string@accept-completer-1 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id | is-empty) { error make --unspanned { msg: "path parameter 'appId' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version_id: (encode-path-segment $version_id)} | format pattern "/package/{app_id}/versions/{version_id}/gzip"))
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
