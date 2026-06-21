# Auto-generated client for bridgedb webservices v0.9.0
# Source: https://api.apis.guru/v2/specs/bridgedb.org/0.9.0/swagger.json
# Auth: --token flag or $env.BRIDGEDB_WEBSERVICES_TOKEN

const BASE_URL = "https://webservice.bridgedb.org"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BRIDGEDB_WEBSERVICES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://webservice.bridgedb.org" "http://webservice.bridgedb.org"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def data-source-completer [] { ["Ag" "Ca" "Ce" "Cg" "Ch" "Ck" "Cks" "Cpc" "Cs" "E" "Eco" "En" "H" "Ik" "Il" "L" "Lm" "Ma" "Mb" "Mc" "Om" "Pd" "Q" "Re" "Rf" "Rh" "Rk" "S" "T" "U" "Uc" "Up" "Wd" "Wg" "Wi" "X"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attribute-search get" } } | get name | first)
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

# Returns a list of xrefs and associated attributes that contain the query string for a given organism. Results are not restricted to exact matches. Optionally limit results to a specified number per data source, or by the type of attribute. See possible attribute types via /{organism}/attributeSet.
#
# GET /{organism}/attributeSearch/{query}
export def "attribute-search get" [
  organism: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results
  --attr-name: string # Restrict search by attribute name (case sensitive). Use GET /{organism}/attributeSet to find out which attributes are supported.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "attrName" $attr_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), query: (encode-path-segment $query)} | format pattern "/{organism}/attributeSearch/{query}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "attrName": $attr_name} | compact), body: null}
}

# Returns the supported attributes to the given Organism.
#
# GET /{organism}/attributeSet
export def "attribute-set get" [
  organism: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism)} | format pattern "/{organism}/attributeSet"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the attributes for a given identifier, data source, organism. Optionally display only a specified attribute
#
# GET /{organism}/attributes/{systemCode}/{identifier}
export def "attributes get" [
  organism: string
  system_code: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attr-name: string # Type of attribute
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($system_code | is-empty) { error make --unspanned { msg: "path parameter 'systemCode' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "attrName" $attr_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), system_code: (encode-path-segment $system_code), identifier: (encode-path-segment $identifier)} | format pattern "/{organism}/attributes/{system_code}/{identifier}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"attrName": $attr_name} | compact), body: null}
}

# Returns `true` or `false` based on whether or not /{organism}/search/{query} is supported for a given organism.
#
# GET /{organism}/isFreeSearchSupported
export def "is-free-search-supported get" [
  organism: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism)} | format pattern "/{organism}/isFreeSearchSupported"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns `true` or `false` based on whether or not /{organism}/xrefs/{systemCode}/{identifier} would possibly return a {targetSystemCode} result given a {sourceSystemCode} query. This function basically combines the results of /{organism}/sourceDataSources and /{organism}/targetDataSources into a single boolean result.
#
# GET /{organism}/isMappingSupported/{sourceSystemCode}/{targetSystemCode}
export def "is-mapping-supported get" [
  organism: string
  source_system_code: string
  target_system_code: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($source_system_code | is-empty) { error make --unspanned { msg: "path parameter 'sourceSystemCode' must be non-empty" } }
  if ($target_system_code | is-empty) { error make --unspanned { msg: "path parameter 'targetSystemCode' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), source_system_code: (encode-path-segment $source_system_code), target_system_code: (encode-path-segment $target_system_code)} | format pattern "/{organism}/isMappingSupported/{source_system_code}/{target_system_code}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the list of properties available for a given organism
#
# GET /{organism}/properties
export def "properties get" [
  organism: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism)} | format pattern "/{organism}/properties"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of xrefs with identifiers that contain the query string for a given organism. Results are not restricted to exact matches. Optionally limit results to a specified number per data source.
#
# GET /{organism}/search/{query}
export def "search get" [
  organism: string
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results per data source
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), query: (encode-path-segment $query)} | format pattern "/{organism}/search/{query}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit} | compact), body: null}
}

# Returns a list of data sources available as xref sources for a given organism.
#
# GET /{organism}/sourceDataSources
export def "source-data-sources get" [
  organism: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism)} | format pattern "/{organism}/sourceDataSources"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of data sources available as xref targets for a given organism.
#
# GET /{organism}/targetDataSources
export def "target-data-sources get" [
  organism: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism)} | format pattern "/{organism}/targetDataSources"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns `true` or `false` based on whether or not an xref exists in the database given an identifier, data source, and organism.
#
# GET /{organism}/xrefExists/{systemCode}/{identifier}
export def "xref-exists get" [
  organism: string
  system_code: string
  identifier: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($system_code | is-empty) { error make --unspanned { msg: "path parameter 'systemCode' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), system_code: (encode-path-segment $system_code), identifier: (encode-path-segment $identifier)} | format pattern "/{organism}/xrefExists/{system_code}/{identifier}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of xrefs that map to a given identifier, data source, and organism.
#
# GET /{organism}/xrefs/{systemCode}/{identifier}
export def "xrefs get" [
  organism: string
  system_code: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-source: string@data-source-completer # (Optional) Restrict results by data source [system code](https://bridgedb.github.io/pages/system-codes.html)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($system_code | is-empty) { error make --unspanned { msg: "path parameter 'systemCode' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "dataSource" $data_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), system_code: (encode-path-segment $system_code), identifier: (encode-path-segment $identifier)} | format pattern "/{organism}/xrefs/{system_code}/{identifier}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"dataSource": $data_source} | compact), body: null}
}

# Returns a list of xrefs, per identifier, that maps to a given list of identifiers an data source given an organism.
#
# POST /{organism}/xrefsBatch
export def "xrefs-batch create-by-organism" [
  organism: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-source: string@data-source-completer # (Optional) Restrict results by data source [system code](https://bridgedb.github.io/pages/system-codes.html)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  let qp = [(serialize-qp "dataSource" $data_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organism: (encode-path-segment $organism)} | format pattern "/{organism}/xrefsBatch") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/html" $req_body {query: ({"dataSource": $data_source} | compact), body: $req_body}
}

# Returns a list of xrefs, that maps to a given list of identifiers to a given data source and organism.
#
# POST /{organism}/xrefsBatch/{systemCode}
export def "xrefs-batch create-by-organism-system-code" [
  organism: string
  system_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-source: string@data-source-completer # (Optional) Restrict results by data source [system code](https://bridgedb.github.io/pages/system-codes.html)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organism | is-empty) { error make --unspanned { msg: "path parameter 'organism' must be non-empty" } }
  if ($system_code | is-empty) { error make --unspanned { msg: "path parameter 'systemCode' must be non-empty" } }
  let qp = [(serialize-qp "dataSource" $data_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organism: (encode-path-segment $organism), system_code: (encode-path-segment $system_code)} | format pattern "/{organism}/xrefsBatch/{system_code}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/html" $req_body {query: ({"dataSource": $data_source} | compact), body: $req_body}
}
