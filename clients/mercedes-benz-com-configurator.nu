# Auto-generated client for Car Configurator v1.0
# Source: https://api.apis.guru/v2/specs/mercedes-benz.com/configurator/1.0/swagger.json
# Auth: --token flag or $env.CAR_CONFIGURATOR_TOKEN

const BASE_URL = "https://api.mercedes-benz.com/configurator_tryout/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CAR_CONFIGURATOR_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.mercedes-benz.com/configurator_tryout/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "markets list" } } | get name | first)
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

# Get all available markets.
#
# GET /markets
# operationId: marketsGET
export def "markets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # This is a ISO language string e.g. 'de' and is spoken in Austria 'AT', Germany 'DE' and Swiss 'CH'. (default: de)
  --country: string # This is a ISO country string e.g. Germany 'DE' or Swiss 'CH'.
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<bodies: record, classes: record, models: record, productgroups: record, self: record>, country: string, language: string, marketId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/markets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "country": $country, "fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get the market with the given marketId.
#
# GET /markets/{marketId}
# operationId: marketGET
export def "markets get" [
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<bodies: record<href: string>, classes: record<href: string>, models: record<href: string>, productgroups: record<href: string>, self: record<href: string>>, country: string, language: string, marketId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id)} | format pattern "/markets/{market_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all available bodies for the given marketId.
#
# GET /markets/{marketId}/bodies
# operationId: bodiesGET
export def "markets-bodies get" [
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --class-id: string # This is a class id e.g. '176' for 'A-Class' in Germany. (default: 222)
  --body-id: string # This is a body id e.g. '1' for 'Limousine' in Germany. (default: 2)
  --product-groups: list<string> # Specifies to which product groups the vehicles belong which should be returned. The product groups are separated from each other by a comma and are case sensitive. Allowed values are: * PKW * VAN * SMART
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<models: record, self: record>, bodyId: string, bodyName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let qp = [(serialize-qp "classId" $class_id "scalar") (serialize-qp "bodyId" $body_id "scalar") (serialize-qp "productGroups" $product_groups "csv") (serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id)} | format pattern "/markets/{market_id}/bodies") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"classId": $class_id, "bodyId": $body_id, "productGroups": $product_groups, "fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get the body for the given marketId and bodyId.
#
# GET /markets/{marketId}/bodies/{bodyId}
# operationId: bodyGET
export def "markets-bodies get-body" [
  market_id: string
  body_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<models: record<href: string>, self: record<href: string>>, bodyId: string, bodyName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($body_id | is-empty) { error make --unspanned { msg: "path parameter 'bodyId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), body_id: (encode-path-segment $body_id)} | format pattern "/markets/{market_id}/bodies/{body_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all available classes for the given marketId.
#
# GET /markets/{marketId}/classes
# operationId: classesGET
export def "markets-classes get" [
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --class-id: string # This is a class id e.g. '176' for 'A-Class' in Germany. (default: 222)
  --body-id: string # This is a body id e.g. '1' for 'Limousine' in Germany. (default: 2)
  --product-groups: list<string> # Specifies to which product groups the vehicles belong which should be returned. The product groups are separated from each other by a comma and are case sensitive. Allowed values are: * PKW * VAN * SMART
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<models: record, self: record>, classId: string, className: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let qp = [(serialize-qp "classId" $class_id "scalar") (serialize-qp "bodyId" $body_id "scalar") (serialize-qp "productGroups" $product_groups "csv") (serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id)} | format pattern "/markets/{market_id}/classes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"classId": $class_id, "bodyId": $body_id, "productGroups": $product_groups, "fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get the class for the given marketId and classId.
#
# GET /markets/{marketId}/classes/{classId}
# operationId: classGET
export def "markets-classes get-class" [
  market_id: string
  class_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<models: record<href: string>, self: record<href: string>>, classId: string, className: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($class_id | is-empty) { error make --unspanned { msg: "path parameter 'classId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), class_id: (encode-path-segment $class_id)} | format pattern "/markets/{market_id}/classes/{class_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all available models for the given marketId.
#
# GET /markets/{marketId}/models
# operationId: modelsGET
export def "markets-models list" [
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --class-id: string # This is a class id e.g. '176' for 'A-Class' in Germany. (default: 222)
  --body-id: string # This is a body id e.g. '1' for 'Limousine' in Germany. (default: 2)
  --baumuster4prefix: string # The first four digits of a baumuster are called baumuster4prefix e.g. '1760' for 'Berline' in France.
  --baumuster: string # This is a baumuster e.g. '176042' for 'A 180 Limousine' in Germany.
  --national-sales-type: string # This is the national sales type (NST) of a distinct baumuster. There is no predefined pattern for the NST, each market defines its NST. e.g. 'E07' in France, 0001 in Germany and ZA1 in South Africa Using the NST markets can define market specific conditions. e.g. different initial configuration, etc.
  --product-groups: list<string> # Specifies to which product groups the vehicles belong which should be returned. The product groups are separated from each other by a comma and are case sensitive. Allowed values are: * PKW * VAN * SMART
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<configuration: record, self: record>, baumuster: string, modelId: string, name: string, nationalSalesType: string, priceInformation: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list>, productGroup: record<name: string>, shortName: string, vehicleBody: record<_links: record, bodyId: string, bodyName: string>, vehicleClass: record<_links: record, classId: string, className: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let qp = [(serialize-qp "classId" $class_id "scalar") (serialize-qp "bodyId" $body_id "scalar") (serialize-qp "baumuster4prefix" $baumuster4prefix "scalar") (serialize-qp "baumuster" $baumuster "scalar") (serialize-qp "nationalSalesType" $national_sales_type "scalar") (serialize-qp "productGroups" $product_groups "csv") (serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id)} | format pattern "/markets/{market_id}/models") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"classId": $class_id, "bodyId": $body_id, "baumuster4prefix": $baumuster4prefix, "baumuster": $baumuster, "nationalSalesType": $national_sales_type, "productGroups": $product_groups, "fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get the model for the given marketId and modelId.
#
# GET /markets/{marketId}/models/{modelId}
# operationId: modelGET
export def "markets-models get" [
  market_id: string
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
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<configuration: record<href: string>, self: record<href: string>>, baumuster: string, modelId: string, name: string, nationalSalesType: string, priceInformation: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, productGroup: record<name: string>, shortName: string, vehicleBody: record<_links: record<models: record, self: record>, bodyId: string, bodyName: string>, vehicleClass: record<_links: record<models: record, self: record>, classId: string, className: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id)} | format pattern "/markets/{market_id}/models/{model_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the initial configuration for the given marketId and modelId.
#
# GET /markets/{marketId}/models/{modelId}/configurations/initial
# operationId: modelConfigurationsGET
export def "markets-models-configurations-initial get" [
  market_id: string
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
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<imageapi_vehicle: record<href: string>, selectables: record<href: string>, self: record<href: string>>, changeYear: string, configurationId: string, configurationPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, initialPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, marketId: string, modelId: string, modelYear: string, technicalInformation: record<acceleration: record<unit: string, value: float>, doors: float, energyEfficiencyClass: string, engine: record<alternativeFuelType: string, capacity: record, cylinder: string, driveConcept: string, emissionStandard: string, engineConcept: string, fuelEconomy: record, fuelType: string, powerHp: record, powerHybridExtensionHp: record, powerHybridExtensionKw: record, powerKw: record>, nedc: record<consumption: record, electricRange: record, emission: record, weight: record>, seats: float, topSpeed: record<unit: string, value: float>, transmission: record<code: string, codeType: string, name: string>, wltp: record<consumption: record, emission: record>>, vehicleComponents: table<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>, wltpConfiguration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/initial") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the configuration for the given marketId, modelId and configurationId.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}
# operationId: modelConfigurationGET
export def "markets-models-configurations get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<imageapi_vehicle: record<href: string>, selectables: record<href: string>, self: record<href: string>>, changeYear: string, configurationId: string, configurationPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, initialPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, marketId: string, modelId: string, modelYear: string, technicalInformation: record<acceleration: record<unit: string, value: float>, doors: float, energyEfficiencyClass: string, engine: record<alternativeFuelType: string, capacity: record, cylinder: string, driveConcept: string, emissionStandard: string, engineConcept: string, fuelEconomy: record, fuelType: string, powerHp: record, powerHybridExtensionHp: record, powerHybridExtensionKw: record, powerKw: record>, nedc: record<consumption: record, electricRange: record, emission: record, weight: record>, seats: float, topSpeed: record<unit: string, value: float>, transmission: record<code: string, codeType: string, name: string>, wltp: record<consumption: record, emission: record>>, vehicleComponents: table<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>, wltpConfiguration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the alternatives for the given marketId, modelId, configurationId and componentList.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/alternatives/{componentList}
# operationId: modelConfigurationAlternativesGET
export def "markets-models-configurations-alternatives get" [
  market_id: string
  model_id: string
  configuration_id: string
  component_list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<imageapi_vehicle: record, selectables: record, self: record>, addedComponents: list<record>, configurationId: string, marketId: string, modelId: string, priceInformation: record, removedComponents: list<record>, updatedComponents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  if ($component_list | is-empty) { error make --unspanned { msg: "path parameter 'componentList' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id), component_list: (encode-path-segment $component_list)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/alternatives/{component_list}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns URLs pointing to images in JPG format in the highest available resolution (depending on the component) of the vehicle's: * engine (1024x576 px), * rim (710x710 px), * trim (800x600 px), * paints (800x600 px), * upholstery (800x600 px) and * equipments (740x416 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components
# operationId: imageComponentsGET
export def "markets-models-configurations-images-components get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<components: record<engine: record<url: string>, equipments: record, paint: record<paint1: record, paint2: record>, rim: record<code: string, url: string>, trim: record<code: string, url: string>, upholstery: record<code: string, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns a URL pointing to an image of the vehicles engine. These images are available in the resolution 1024x576 px.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/engine
# operationId: imageComponentsEngineGET
export def "markets-models-configurations-images-components-engine get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<engine: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/engine") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns URLs pointing to images of this vehicle's equipments. The images are available in the highest possible resolution (usually 740x416 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/equipments
# operationId: imageComponentsEquipmentsGET
export def "markets-models-configurations-images-components-equipments get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<equipments: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/equipments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns URLs pointing to images of this vehicle's equipments. The images are available in the highest possible resolution (usually 740x416 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/equipments/{componentCode}
# operationId: imageComponentsEquipmentsByCodeGET
export def "markets-models-configurations-images-components-equipments get-by-code" [
  market_id: string
  model_id: string
  configuration_id: string
  component_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<equipment: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  if ($component_code | is-empty) { error make --unspanned { msg: "path parameter 'componentCode' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id), component_code: (encode-path-segment $component_code)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/equipments/{component_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns URLs pointing to images of this vehicles paint. These images are available in resolution 800x600 px. Note there might be two paints (e.g. Smart, 'paint' for body panel and 'paint2' for the tridion cell)
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/paint
# operationId: imageComponentsPaintGET
export def "markets-models-configurations-images-components-paint get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<paint: record<paint1: record<code: string, url: string>, paint2: record<code: string, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/paint") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns a URL pointing to an image of the vehicles rim. These images are available in the resolution 710x710 px.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/rim
# operationId: imageComponentsRimGET
export def "markets-models-configurations-images-components-rim get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rim: record<code: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/rim") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns a URL pointing to an image of this vehicles trim. These images are available in resolution 800x600 px.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/trim
# operationId: imageComponentsTrimGET
export def "markets-models-configurations-images-components-trim get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<trim: record<code: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/trim") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns URLs pointing to images of the vehicle's upholsteries. Tge images are available in the highest possible resolution (usually 800x600 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/upholstery
# operationId: imageComponentsUpholsteryGET
export def "markets-models-configurations-images-components-upholstery get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<upholstery: record<code: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/components/upholstery") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Returns URLs pointing to PNG images of a vehicle with a white background.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/vehicle
# operationId: imageVehicleGET
export def "markets-models-configurations-images-vehicle get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --perspectives: string # One or more perspectives as a comma separated String list e.g. 'EXT000,EXT010,INT1'. The following perspectives are available: * EXT000-EXT350: EXT000 defines the front view, EXT010 defines a rotation of 10 degress and so forth. * INT1-INT4: These are the 4 available interior perspectives. The default value is EXT020,INT1 if no value is provided. (default: EXT020,INT1)
  --roof-open: oneof<nothing, bool> # Set 'true', if you are looking for images with the roof open. This option is only valid for cabrios. Default is 'false'. (default: false)
  --night: oneof<nothing, bool> # Set 'true', if you are looking for images with a darker background and the vehicle's headlights turned on. Default is 'false'. (default: false)
]: nothing -> record<vehicle: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let qp = [(serialize-qp "perspectives" $perspectives "scalar") (serialize-qp "roofOpen" $roof_open "scalar") (serialize-qp "night" $night "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/images/vehicle") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"perspectives": $perspectives, "roofOpen": $roof_open, "night": $night} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get the selectable components for the given marketId, modelId and configurationId.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/selectables
# operationId: modelConfigurationSelectablesGET
export def "markets-models-configurations-selectables get" [
  market_id: string
  model_id: string
  configuration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --component-types: list<string> # A list of component types separated by a comma case insensitive. If nothing is defined all component types are returned. Allowed values are: - WHEELS - PAINTS - UPHOLSTERIES - TRIMS - PACKAGES - LINES - SPECIAL_EDITION - SPECIAL_EQUIPMENT
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<self: record<href: string>>, componentCategories: table<cardinality: string, categoryId: string, categoryName: string, categorySortId: float, componentIds: list, subcategories: list>, vehicleComponents: record<componentId: record<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($model_id | is-empty) { error make --unspanned { msg: "path parameter 'modelId' must be non-empty" } }
  if ($configuration_id | is-empty) { error make --unspanned { msg: "path parameter 'configurationId' must be non-empty" } }
  let qp = [(serialize-qp "componentTypes" $component_types "csv") (serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), model_id: (encode-path-segment $model_id), configuration_id: (encode-path-segment $configuration_id)} | format pattern "/markets/{market_id}/models/{model_id}/configurations/{configuration_id}/selectables") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"componentTypes": $component_types, "fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Stores the configuration of the given configurationId and modelId
#
# POST /markets/{marketId}/onlinecode
# operationId: onlineCodePOST
export def "markets-onlinecode create-online-code" [
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  configuration_id: string # String that identifies a configuration. e.g. E-D15-D18-D41-D46-D49-D52-D53-D54-D59-D60-D71-F32-F36-F88-F98-G03-G05-G36-G56-I61-J67-M23-M70-N18-N25-N62-N92-O76-Q29-Q56-Q79-Q92-S01-S05-S08-S63-S92-T05-T07-T62-T84-T88_I-953_L-696_P-001_S-152-160-161-171-258-290-292-294-411-442-470-472-475-485-516-533-538-560-570-573-580-584-58U-591-620-70B-807-888-B03-B16-B51-K11-L18-R43-U60
  model_id: string # String that identifies a model. e.g. '176042_002'
]: any -> record<onlineCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id)} | format pattern "/markets/{market_id}/onlinecode") $auth.query)
  let req_body = {"configurationId": $configuration_id, "modelId": $model_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get the configuration of the given onlineCode and marketId.
#
# GET /markets/{marketId}/onlinecode/{onlineCode}
# operationId: onlineCodeGET
export def "markets-onlinecode get-online-code" [
  market_id: string
  online_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<imageapi_vehicle: record<href: string>, selectables: record<href: string>, self: record<href: string>>, changeYear: string, configurationId: string, configurationPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, initialPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, marketId: string, modelId: string, modelYear: string, technicalInformation: record<acceleration: record<unit: string, value: float>, doors: float, energyEfficiencyClass: string, engine: record<alternativeFuelType: string, capacity: record, cylinder: string, driveConcept: string, emissionStandard: string, engineConcept: string, fuelEconomy: record, fuelType: string, powerHp: record, powerHybridExtensionHp: record, powerHybridExtensionKw: record, powerKw: record>, nedc: record<consumption: record, electricRange: record, emission: record, weight: record>, seats: float, topSpeed: record<unit: string, value: float>, transmission: record<code: string, codeType: string, name: string>, wltp: record<consumption: record, emission: record>>, vehicleComponents: table<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>, wltpConfiguration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  if ($online_code | is-empty) { error make --unspanned { msg: "path parameter 'onlineCode' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id), online_code: (encode-path-segment $online_code)} | format pattern "/markets/{market_id}/onlinecode/{online_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all configured active product groups for the given marketId.
#
# GET /markets/{marketId}/productgroups
# operationId: productGroupsGET
export def "markets-productgroups get-product-groups" [
  market_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-filter: list<string> # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<models: record<href: string>, self: record<href: string>>, market: record<_links: record<bodies: record, classes: record, models: record, productgroups: record, self: record>, country: string, language: string, marketId: string>, productGroups: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($market_id | is-empty) { error make --unspanned { msg: "path parameter 'marketId' must be non-empty" } }
  let qp = [(serialize-qp "fieldsFilter" $fields_filter "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({market_id: (encode-path-segment $market_id)} | format pattern "/markets/{market_id}/productgroups") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldsFilter": $fields_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
