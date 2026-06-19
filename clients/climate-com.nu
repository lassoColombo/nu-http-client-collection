# Auto-generated client for Climate FieldView Platform APIs v4.0.11
# Source: https://api.apis.guru/v2/specs/climate.com/4.0.11/openapi.json
# Auth: --token flag or $env.CLIMATE_FIELDVIEW_PLATFORM_APIS_TOKEN

const BASE_URL = "https://platform.climate.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLIMATE_FIELDVIEW_PLATFORM_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-Api-Key: $token_val}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://platform.climate.com"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }

# Completers for enum parameters
def content-type-completer [] { ["application/vnd.climate.acrsi.geojson" "application/vnd.climate.harvest.geojson"] }
def content-type-completer-1 [] { ["application/vnd.climate.as-applied.zip" "application/vnd.climate.as-harvested.zip" "application/vnd.climate.as-planted.zip" "application/vnd.climate.field.geojson" "application/vnd.climate.modus.xml" "application/vnd.climate.prescription.zones.shp" "application/vnd.climate.rx.planting.shp" "application/vnd.climate.stand-count.geojson" "application/vnd.climate.weed-count.geojson" "image/vnd.climate.elevation.geotiff" "image/vnd.climate.ndvi.geotiff" "image/vnd.climate.raw.geotiff" "image/vnd.climate.rgb-cir.geotiff" "image/vnd.climate.rgb-nir.geotiff" "image/vnd.climate.rgb.geotiff" "image/vnd.climate.thermal.geotiff" "image/vnd.climate.waterstress.geotiff"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "boundaries upload-boundary" } } | get name | first)
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

# Upload a boundary
#
# POST /v4/boundaries
# operationId: uploadBoundary
# --geometry shape: {coordinates: list<string>, type: "Point"|"Polygon"|"MultiPolygon"}
export def "boundaries upload-boundary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  geometry: any # GeoJSON (e.g. {coordinates: [0, 0], type: Point}) — shape: {coordinates: list<string>, type: "Point"|"Polygon"|"MultiPolygon"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/boundaries")
  let req_body = {"geometry": $geometry} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve Boundaries in batch
#
# POST /v4/boundaries/query
# operationId: fetchBoundaries
export def "boundaries-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/boundaries/query")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a Boundary by ID
#
# GET /v4/boundaries/{boundaryId}
# operationId: fetchBoundaryById
export def "boundaries get-boundary" [
  boundary_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($boundary_id | is-empty) { error make --unspanned { msg: "path parameter 'boundaryId' must be non-empty" } }
  let full_url = (build-url $base ({boundary_id: (encode-path-segment $boundary_id)} | format pattern "/v4/boundaries/{boundary_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Initiate a new export request.
#
# POST /v4/exports
# operationId: postExport
export def "exports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  content_type: string@content-type-completer # Content type representing data being exported (e.g. application/vnd.climate.acrsi.geojson). (format: mime-type)
  --definition: record # Additional specifications for a client's data export request, dependent on the content type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/exports")
  let req_body = {"contentType": $content_type, "definition": $definition} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve the binary contents of a processed export request.
#
# GET /v4/exports/{exportId}/contents
# operationId: fetchExportContentsById
export def "exports-contents get" [
  export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --range: string # Byte range `bytes=start-end` (https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1). e.g. bytes=0-1048576. Currently only single range value is supported. Both start and end need to be specified, end value should be greater than start and end - start should not be greater than 5MiB.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/v4/exports/{export_id}/contents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the status of an Export.
#
# GET /v4/exports/{exportId}/status
# operationId: fetchExportStatusById
export def "exports-status get" [
  export_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($export_id | is-empty) { error make --unspanned { msg: "path parameter 'exportId' must be non-empty" } }
  let full_url = (build-url $base ({export_id: (encode-path-segment $export_id)} | format pattern "/v4/exports/{export_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a specific farm organization by organization type and ID
#
# GET /v4/farmOrganizations/{farmOrganizationType}/{farmOrganizationId}
# operationId: fetchFarmOrganizationByTypeAndId
export def "farm-organizations get-by-type-and" [
  farm_organization_type: string
  farm_organization_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($farm_organization_type | is-empty) { error make --unspanned { msg: "path parameter 'farmOrganizationType' must be non-empty" } }
  if ($farm_organization_id | is-empty) { error make --unspanned { msg: "path parameter 'farmOrganizationId' must be non-empty" } }
  let full_url = (build-url $base ({farm_organization_type: (encode-path-segment $farm_organization_type), farm_organization_id: (encode-path-segment $farm_organization_id)} | format pattern "/v4/farmOrganizations/{farm_organization_type}/{farm_organization_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve list of Fields
#
# GET /v4/fields
# operationId: fetchFields
export def "fields list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string # Optional prefix filter for field name. Must be at least 3 characters.
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldName" $field_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/fields" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fieldName": $field_name} | compact), body: null}
}

# Retrieve list of all Fields the user has access to.
#
# GET /v4/fields/all
# operationId: fetchAllFields
export def "fields-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-name: string # Optional prefix filter for field name. Must be at least 3 characters.
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldName" $field_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/fields/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fieldName": $field_name} | compact), body: null}
}

# Retrieve a specific Field by ID
#
# GET /v4/fields/{fieldId}
# operationId: fetchFieldById
export def "fields get" [
  field_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'fieldId' must be non-empty" } }
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/v4/fields/{field_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of application activities
#
# GET /v4/layers/asApplied
export def "layers-as-applied get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-owner-id: string # Optional unique identifier of the resource owner. If resourceOwnerId is not specified, it defaults to the x-authenticated-user-uuid. (format: uuid)
  --occurred-after: string # Optional start time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with an end time at or after (inclusive) the specified time will match this filter. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --occurred-before: string # Optional end time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a start time at or before (inclusive) the specified time. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --updated-after: string # Optional updated time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a modification time at or after (inclusive) the specified time. (format: date-time)
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceOwnerId" $resource_owner_id "scalar") (serialize-qp "occurredAfter" $occurred_after "scalar") (serialize-qp "occurredBefore" $occurred_before "scalar") (serialize-qp "updatedAfter" $updated_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/layers/asApplied" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceOwnerId": $resource_owner_id, "occurredAfter": $occurred_after, "occurredBefore": $occurred_before, "updatedAfter": $updated_after} | compact), body: null}
}

# Retrieve the raw application activity
#
# GET /v4/layers/asApplied/{activityId}/contents
export def "layers-as-applied-contents get" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --range: string # Byte range `bytes=start-end` (https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1). e.g. bytes=0-1048576. Currently only single range value is supported. Both start and end need to be specified, end value should be greater than start and end - start should not be greater than 5MiB.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/v4/layers/asApplied/{activity_id}/contents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of harvest activities
#
# GET /v4/layers/asHarvested
export def "layers-as-harvested get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-owner-id: string # Optional unique identifier of the resource owner. If resourceOwnerId is not specified, it defaults to the x-authenticated-user-uuid. (format: uuid)
  --occurred-after: string # Optional start time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with an end time at or after (inclusive) the specified time will match this filter. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --occurred-before: string # Optional end time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a start time at or before (inclusive) the specified time. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --updated-after: string # Optional updated time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a modification time at or after (inclusive) the specified time. (format: date-time)
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceOwnerId" $resource_owner_id "scalar") (serialize-qp "occurredAfter" $occurred_after "scalar") (serialize-qp "occurredBefore" $occurred_before "scalar") (serialize-qp "updatedAfter" $updated_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/layers/asHarvested" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceOwnerId": $resource_owner_id, "occurredAfter": $occurred_after, "occurredBefore": $occurred_before, "updatedAfter": $updated_after} | compact), body: null}
}

# Retrieve the raw harvest activity
#
# GET /v4/layers/asHarvested/{activityId}/contents
export def "layers-as-harvested-contents get" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --range: string # Byte range `bytes=start-end` (https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1). e.g. bytes=0-1048576. Currently only single range value is supported. Both start and end need to be specified, end value should be greater than start and end - start should not be greater than 5MiB.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/v4/layers/asHarvested/{activity_id}/contents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of planting activities
#
# GET /v4/layers/asPlanted
export def "layers-as-planted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-owner-id: string # Optional unique identifier of the resource owner. If resourceOwnerId is not specified, it defaults to the x-authenticated-user-uuid. (format: uuid)
  --occurred-after: string # Optional start time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with an end time at or after (inclusive) the specified time will match this filter. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --occurred-before: string # Optional end time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a start time at or before (inclusive) the specified time. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --updated-after: string # Optional updated time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a modification time at or after (inclusive) the specified time. (format: date-time)
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceOwnerId" $resource_owner_id "scalar") (serialize-qp "occurredAfter" $occurred_after "scalar") (serialize-qp "occurredBefore" $occurred_before "scalar") (serialize-qp "updatedAfter" $updated_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/layers/asPlanted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceOwnerId": $resource_owner_id, "occurredAfter": $occurred_after, "occurredBefore": $occurred_before, "updatedAfter": $updated_after} | compact), body: null}
}

# Retrieve the raw planting activity
#
# GET /v4/layers/asPlanted/{activityId}/contents
export def "layers-as-planted-contents get" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --range: string # Byte range `bytes=start-end` (https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1). e.g. bytes=0-1048576. Currently only single range value is supported. Both start and end need to be specified, end value should be greater than start and end - start should not be greater than 5MiB.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/v4/layers/asPlanted/{activity_id}/contents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a list of scouting observations
#
# GET /v4/layers/scoutingObservations
export def "layers-scouting-observations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --occurred-after: string # Optional start time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with an end time at or after (inclusive) the specified time will match this filter. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --occurred-before: string # Optional end time by which to filter layer results. Time must be in ISO 8601 format with time zone, e.g. 2016-05-13T00:00:00Z (https://tools.ietf.org/html/rfc3339). Layers with a start time at or before (inclusive) the specified time. If both occurredAfter and occurredBefore are populated, occurredAfter must be <= occurredBefore. (format: date-time)
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "occurredAfter" $occurred_after "scalar") (serialize-qp "occurredBefore" $occurred_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/layers/scoutingObservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"occurredAfter": $occurred_after, "occurredBefore": $occurred_before} | compact), body: null}
}

# Retrieve individual scouting observation
#
# GET /v4/layers/scoutingObservations/{scoutingObservationId}
export def "layers-scouting-observations get" [
  scouting_observation_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($scouting_observation_id | is-empty) { error make --unspanned { msg: "path parameter 'scoutingObservationId' must be non-empty" } }
  let full_url = (build-url $base ({scouting_observation_id: (encode-path-segment $scouting_observation_id)} | format pattern "/v4/layers/scoutingObservations/{scouting_observation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve attachments associated with a given scouting observation.
#
# GET /v4/layers/scoutingObservations/{scoutingObservationId}/attachments
export def "layers-scouting-observations-attachments get" [
  scouting_observation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-next-token: string # Opaque string which allows for fetching the next batch of results. Can be used to poll for changes.
  --x-limit: int # Max number of results to return per batch. Must be between 1 and 100 inclusive. Defaults to 100.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($scouting_observation_id | is-empty) { error make --unspanned { msg: "path parameter 'scoutingObservationId' must be non-empty" } }
  let full_url = (build-url $base ({scouting_observation_id: (encode-path-segment $scouting_observation_id)} | format pattern "/v4/layers/scoutingObservations/{scouting_observation_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Next-Token": $x_next_token, "X-Limit": $x_limit} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the binary contents of a scouting observation’s attachment.
#
# GET /v4/layers/scoutingObservations/{scoutingObservationId}/attachments/{attachmentId}/contents
export def "layers-scouting-observations-attachments-contents get" [
  scouting_observation_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Must be either \*/* or application/octet-stream,application/json
  --range: string # Byte range `bytes=start-end` (https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.35.1). e.g. bytes=0-1048576. Currently only single range value is supported. Both start and end need to be specified, end value should be greater than start and end - start should not be greater than 5MiB.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($scouting_observation_id | is-empty) { error make --unspanned { msg: "path parameter 'scoutingObservationId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({scouting_observation_id: (encode-path-segment $scouting_observation_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/v4/layers/scoutingObservations/{scouting_observation_id}/attachments/{attachment_id}/contents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve the operations accessible to a a given user.
#
# GET /v4/operations/all
# operationId: fetchOperations
export def "operations-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-owner-id: string # Optional comma-separated list of resource owner unique identifiers by which to filter results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resourceOwnerId" $resource_owner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/operations/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"resourceOwnerId": $resource_owner_id} | compact), body: null}
}

# Retrieve a resource owner by ID
#
# GET /v4/resourceOwners/{resourceOwnerId}
# operationId: getResourceOwner
export def "resource-owners get" [
  resource_owner_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_owner_id | is-empty) { error make --unspanned { msg: "path parameter 'resourceOwnerId' must be non-empty" } }
  let full_url = (build-url $base ({resource_owner_id: (encode-path-segment $resource_owner_id)} | format pattern "/v4/resourceOwners/{resource_owner_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Initiate a new upload
#
# POST /v4/uploads
# operationId: postUpload
export def "uploads create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-recipient-email: string # Email address associated with a Climate account, used when to sending to another user.
  content_type: string@content-type-completer-1 # Content type representing data being uploaded (e.g. image/vnd.climate.rgb.geotiff) (format: mime-type)
  length: int # Content size in bytes (format: int64)
  md5: string # Base64 encoded md5 hash of the content
  --metadata: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/uploads")
  let req_body = {"contentType": $content_type, "length": $length, "md5": $md5, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Recipient-Email": $x_recipient_email} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve Upload statuses in batch
#
# POST /v4/uploads/status/query
# operationId: fetchUploadStatuses
export def "uploads-status-query get-statuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/uploads/status/query")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Chunked upload of data
#
# PUT /v4/uploads/{uploadId}
# operationId: chunkedUpload
export def "uploads upload-chunked" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Byte range `bytes start-end/total` (https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.16). e.g. bytes 0-5242880/10242880. Downloads larger than 5MiB (5242880 bytes) in size must be downloaded in chunks no larger than 5MiB (5242880 bytes) and no smaller than 1MiB (1048576 bytes). The last chunk could be less than 1MiB (1048576 bytes).
  --content-type: string # Must be `application/octet-stream`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'uploadId' must be non-empty" } }
  let full_url = (build-url $base ({upload_id: (encode-path-segment $upload_id)} | format pattern "/v4/uploads/{upload_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Range": $content_range, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve Upload status
#
# GET /v4/uploads/{uploadId}/status
# operationId: fetchUploadStatusById
export def "uploads-status get" [
  upload_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($upload_id | is-empty) { error make --unspanned { msg: "path parameter 'uploadId' must be non-empty" } }
  let full_url = (build-url $base ({upload_id: (encode-path-segment $upload_id)} | format pattern "/v4/uploads/{upload_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
