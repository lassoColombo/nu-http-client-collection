# Auto-generated client for Semantria v4.0
# Source: https://api.apis.guru/v2/specs/semantria.com/4.0/swagger.json
# Auth: --token flag or $env.SEMANTRIA_TOKEN

const BASE_URL = "https://api.semantria.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEMANTRIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.semantria.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "blacklist-content-type delete-items" } } | get name | first)
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

# Remove items from blacklist
#
# DELETE /blacklist.{content_type}
# operationId: deleteBlacklistItems
export def "blacklist-content-type delete-items" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist items linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve blacklisted items
#
# GET /blacklist.{content_type}
# operationId: getBlacklist
export def "blacklist-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist linked to.
]: nothing -> table<id: string, modified: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add items to blacklist
#
# POST /blacklist.{content_type}
# operationId: addBlacklist
export def "blacklist-content-type create" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update items in blacklist
#
# PUT /blacklist.{content_type}
# operationId: updateBlacklist
export def "blacklist-content-type update" [
  content_type: string
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
  --config-id: string # Identifier of configuration blacklist linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove user categories
#
# DELETE /categories.{content_type}
# operationId: deleteCategories
export def "categories-content-type delete" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve user categories
#
# GET /categories.{content_type}
# operationId: getCategories
export def "categories-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
]: nothing -> table<id: string, modified: string, name: string, samples: list<string>, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add user categories
#
# POST /categories.{content_type}
# operationId: addCategories
export def "categories-content-type create" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, samples: list<string>, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates user categories
#
# PUT /categories.{content_type}
# operationId: updateCategories
export def "categories-content-type update" [
  content_type: string
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
  --config-id: string # Identifier of configuration user categories linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, samples: list<string>, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Queue collection for analysis
#
# POST /collection.{content_type}
# operationId: queueCollection
export def "collection-content-type create-queue" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> record<documents: list<string>, id: string, job_id: string, tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/collection.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve collections analysis
#
# GET /collection/processed.{content_type}
# operationId: retrieveProcessedCollections
export def "collection-processed-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/collection/processed.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Cancel collection analysis
#
# DELETE /collection/{collection_id}.{content_type}
# operationId: cancelCollection
export def "collection cancel" [
  collection_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), content_type: (encode-path-segment $content_type)} | format pattern "/collection/{collection_id}.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve collection analysis or its status in queue
#
# GET /collection/{collection_id}.{content_type}
# operationId: receiveCollectionAnalyticData
export def "collection receive-analytic-data" [
  collection_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), content_type: (encode-path-segment $content_type)} | format pattern "/collection/{collection_id}.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove user configurations
#
# DELETE /configurations.{content_type}
# operationId: deleteConfigurations
export def "configurations-content-type delete" [
  content_type: string
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
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve user configurations
#
# GET /configurations.{content_type}
# operationId: getConfigurations
export def "configurations-content-type get" [
  content_type: string
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
]: nothing -> table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create user configurations
#
# POST /configurations.{content_type}
# operationId: addConfigurations
export def "configurations-content-type create" [
  content_type: string
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
  --body: record
]: any -> table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update user configurations
#
# PUT /configurations.{content_type}
# operationId: updateConfigurations
export def "configurations-content-type update" [
  content_type: string
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
  --body: record
]: any -> table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Queue document for analysis
#
# POST /document.{content_type}
# operationId: queueDocument
export def "document-content-type create-queue" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> record<id: string, job_id: string, tag: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/document.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Queue batch of documents for analysis
#
# POST /document/batch.{content_type}
# operationId: queueBatchOfDocuments
export def "document-batch-content-type create-queue" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> record<id: string, job_id: string, tag: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/document/batch.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve documents analysis
#
# GET /document/processed.{content_type}
# operationId: retrieveProcessedDocuments
export def "document-processed-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/document/processed.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Cancel document analysis
#
# DELETE /document/{document_id}.{content_type}
# operationId: cancelDocument
export def "document cancel" [
  document_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), content_type: (encode-path-segment $content_type)} | format pattern "/document/{document_id}.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve document analysis or its status in queue
#
# GET /document/{document_id}.{content_type}
# operationId: receiveDocumentAnalyticData
export def "document receive-analytic-data" [
  document_id: string
  content_type: string
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
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), content_type: (encode-path-segment $content_type)} | format pattern "/document/{document_id}.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove user entities
#
# DELETE /entities.{content_type}
# operationId: deleteEntities
export def "entities-content-type delete" [
  content_type: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve user entities
#
# GET /entities.{content_type}
# operationId: getEntities
export def "entities-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration user entities linked to.
]: nothing -> table<id: string, label: string, modified: string, name: string, normalized: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add user entities
#
# POST /entities.{content_type}
# operationId: addEntities
export def "entities-content-type create" [
  content_type: string
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
  --config-id: string # Identifier of configuration user entities linked to.
  --body: record
]: any -> table<id: string, label: string, modified: string, name: string, normalized: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update user entities
#
# PUT /entities.{content_type}
# operationId: updateEntities
export def "entities-content-type update" [
  content_type: string
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
  --config-id: string # Identifier of configuration user entities linked to.
  --body: record
]: any -> table<id: string, label: string, modified: string, name: string, normalized: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve supported features
#
# GET /features.{content_type}
# operationId: getFeatures
export def "features-content-type get" [
  content_type: string
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
  --language: string # Filter features by specified language
]: nothing -> table<detailed_mode: record<auto_categories: bool, entity_mentions: bool, entity_opinions: bool, entity_relations: bool, entity_themes: bool, intentions: bool, language_detection: bool, model_sentiment: bool, named_entities: bool, pos_tagging: bool, queries: bool, sentiment: bool, sentiment_phrases: bool, summarization: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, discovery_mode: record<entity_mentions: bool, facet_attributes: bool, facet_mentioins: bool, facets: bool, named_entities: bool, queries: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, html_processing: bool, id: string, language: string, one_sentence_mode: bool, settings: record<blacklist: bool, queries: bool, sentiment_phrases: bool, taxonomy: bool, user_categories: bool, user_entities: bool>, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/features.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove sentiment-bearing phrases
#
# DELETE /phrases.{content_type}
# operationId: deletePhrases
export def "phrases-content-type delete" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve sentiment-bearing phrases
#
# GET /phrases.{content_type}
# operationId: getPhrases
export def "phrases-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
]: nothing -> table<id: string, modified: string, name: string, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add sentiment-bearing phrases
#
# POST /phrases.{content_type}
# operationId: addPhrases
export def "phrases-content-type create" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates sentiment-bearing phrases
#
# PUT /phrases.{content_type}
# operationId: updatePhrases
export def "phrases-content-type update" [
  content_type: string
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
  --config-id: string # Identifier of configuration phrases linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove queries
#
# DELETE /queries.{content_type}
# operationId: deleteQueries
export def "queries-content-type delete" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve queries
#
# GET /queries.{content_type}
# operationId: getQueries
export def "queries-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
]: nothing -> table<id: string, modified: string, name: string, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add or update queries
#
# POST /queries.{content_type}
# operationId: addQueries
export def "queries-content-type create" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, query: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update queries
#
# PUT /queries.{content_type}
# operationId: updateQueries
export def "queries-content-type update" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, query: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve usage statistics
#
# GET /statistics.{content_type}
# operationId: getStatistic
export def "statistics-content-type get" [
  content_type: string
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
  --config-id: string # Configuration identifier for usage statistics retrieving.
  --interval: string # Hour, Day, Week, Month, Year values are supported.
]: nothing -> record<calls_data: int, calls_polling: int, calls_settings: int, colls_documents: int, colls_failed: int, colls_processed: int, colls_responded: int, configurations: table<calls_data: int, calls_polling: int, calls_settings: int, colls_failed: int, colls_processed: int, colls_responded: int, config_id: string, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, used_apps: string>, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, status: string, used_apps: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/statistics.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve API status
#
# GET /status.{content_type}
# operationId: getStatus
export def "status-content-type get" [
  content_type: string
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
]: nothing -> record<api_version: string, service_status: string, service_version: string, supported_compression: string, supported_encoding: string, supported_languages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/status.{content_type}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve subscription details
#
# GET /subscription.{content_type}
# operationId: getSubscription
export def "subscription-content-type get" [
  content_type: string
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
]: nothing -> record<basic_settings: record<auto_response_limit: int, batch_limit: int, blacklist_limit: int, callback_batch_limit: int, categories_limit: int, category_samples_limit: int, characters_limit: int, collection_limit: int, configurations_limit: int, entities_limit: int, output_data_limit: int, processed_batch_limit: int, queries_limit: int, return_source_text: bool, sentiment_limit: int>, billing_settings: record<app_seats_allocated: int, app_seats_permitted: int, data_calls_balance: int, data_calls_limit: int, data_calls_limit_interval: int, docs_balance: int, docs_limit: int, docs_limit_interval: int, docs_suggested: int, docs_suggested_interval: int, expiration_date: string, limit_type: string, polling_calls_balance: int, polling_calls_limit: int, polling_calls_limit_interval: int, priority: string, settings_calls_balance: int, settings_calls_limit: int, settings_calls_limit_interval: int>, feature_settings: record<collection: record<concept_topics: bool, facets: bool, mentions: bool, named_entities: bool, query_topics: bool, themes: bool, user_entities: bool>, document: record<auto_categories: bool, concept_topics: bool, entity_themes: bool, intentions: bool, language_detection: bool, mentions: bool, model_sentiment: bool, named_entities: bool, named_relations: bool, opinions: bool, phrases_detection: bool, pos_tagging: bool, query_topics: bool, sentiment_phrases: bool, summary: bool, themes: bool, user_entities: bool, user_relations: bool>, html_processing: bool, supported_languages: string, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>>, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/subscription.{content_type}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove taxonomy nodes
#
# DELETE /taxonomy.{content_type}
# operationId: deleteTaxonomy
export def "taxonomy-content-type delete" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieve taxonomy
#
# GET /taxonomy.{content_type}
# operationId: getTaxonomy
export def "taxonomy-content-type get" [
  content_type: string
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
  --config-id: string # Identifier of configuration taxonomy linked to.
]: nothing -> table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add taxonomy nodes
#
# POST /taxonomy.{content_type}
# operationId: addTaxonomy
export def "taxonomy-content-type create" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update taxonomy nodes
#
# PUT /taxonomy.{content_type}
# operationId: updateTaxonomy
export def "taxonomy-content-type update" [
  content_type: string
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
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
