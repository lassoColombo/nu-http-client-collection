# Auto-generated client for OPTIMADE API v1.1.0~develop
# Source: https://api.apis.guru/v2/specs/optimade.local/1.1.0~develop/openapi.json
# Auth: --token flag or $env.OPTIMADE_API_TOKEN

const BASE_URL = "http://optimade.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPTIMADE_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://optimade.local"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "info list" } } | get name | first)
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

# Get Info
#
# GET /info
# operationId: get_info_info_get
export def "info list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<api_version: string, available_api_versions: list, available_endpoints: list, entry_types_by_format: record, formats: list, is_index: bool>, id: string, links: record<self: any>, meta: record, relationships: record, type: string>, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: table<attributes: record, id: string, links: record, meta: record, relationships: record, type: string>, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Entry Info
#
# GET /info/{entry}
# operationId: get_entry_info_info__entry__get
export def "info get" [
  entry: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<description: string, formats: list<string>, output_fields_by_format: record, properties: record>, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: table<attributes: record, id: string, links: record, meta: record, relationships: record, type: string>, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry | is-empty) { error make --unspanned { msg: "path parameter 'entry' must be non-empty" } }
  let full_url = (build-url $base ({entry: (encode-path-segment $entry)} | format pattern "/info/{entry}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Links
#
# GET /links
# operationId: get_links_links_get
export def "links get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter string, in the format described in section API Filtering Format Specification of the specification. (default: )
  --response-format: string # The output format requested (see section Response Format). Defaults to the format string 'json', which specifies the standard output format described in this specification. Example: `http://example.com/v1/structures?response_format=xml` (default: json)
  --email-address: string # An email address of the user making the request. The email SHOULD be that of a person and not an automatic system. Example: `http://example.com/v1/structures?email_address=user@example.com` (format: email, default: )
  --response-fields: string # A comma-delimited set of fields to be provided in the output. If provided, these fields MUST be returned along with the REQUIRED fields. Other OPTIONAL fields MUST NOT be returned when this parameter is present. Example: `http://example.com/v1/structures?response_fields=last_modified,nsites` (default: )
  --qp-sort: string # If supporting sortable queries, an implementation MUST use the `sort` query parameter with format as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-sorting). An implementation MAY support multiple sort fields for a single query. If it does, it again MUST conform to the JSON API 1.0 specification. If an implementation supports sorting for an entry listing endpoint, then the `/info/` endpoint MUST include, for each field name `` in its `data.properties.` response value that can be used for sorting, the key `sortable` with value `true`. If a field name under an entry listing endpoint supporting sorting cannot be used for sorting, the server MUST either leave out the `sortable` key or set it equal to `false` for the specific field name. The set of field names, with `sortable` equal to `true` are allowed to be used in the "sort fields" list according to its definition in the JSON API 1.0 specification. The field `sortable` is in addition to each property description and other OPTIONAL fields. An example is shown in the section Entry Listing Info Endpoints. (default: )
  --page-limit: int # Sets a numerical limit on the number of entries returned. See [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-pagination). The API implementation MUST return no more than the number specified. It MAY return fewer. The database MAY have a maximum limit and not accept larger numbers (in which case an error code -- 403 Forbidden -- MUST be returned). The default limit value is up to the API implementation to decide. Example: `http://example.com/optimade/v1/structures?page_limit=100` (default: 20)
  --page-offset: int # RECOMMENDED for use with _offset-based_ pagination: using `page_offset` and `page_limit` is RECOMMENDED. Example: Skip 50 structures and fetch up to 100: `/structures?page_offset=50&page_limit=100`. (default: 0)
  --page-number: int # RECOMMENDED for use with _page-based_ pagination: using `page_number` and `page_limit` is RECOMMENDED. It is RECOMMENDED that the first page has number 1, i.e., that `page_number` is 1-based. Example: Fetch page 2 of up to 50 structures per page: `/structures?page_number=2&page_limit=50`. (default: 0)
  --page-cursor: int # RECOMMENDED for use with _cursor-based_ pagination: using `page_cursor` and `page_limit` is RECOMMENDED. (default: 0)
  --page-above: int # RECOMMENDED for use with _value-based_ pagination: using `page_above`/`page_below` and `page_limit` is RECOMMENDED. Example: Fetch up to 100 structures above sort-field value 4000 (in this example, server chooses to fetch results sorted by increasing `id`, so `page_above` value refers to an `id` value): `/structures?page_above=4000&page_limit=100`. (default: 0)
  --page-below: int # RECOMMENDED for use with _value-based_ pagination: using `page_above`/`page_below` and `page_limit` is RECOMMENDED. (default: 0)
  --include: string # A server MAY implement the JSON API concept of returning [compound documents](https://jsonapi.org/format/1.0/#document-compound-documents) by utilizing the `include` query parameter as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-includes). All related resource objects MUST be returned as part of an array value for the top-level `included` field, see the section JSON Response Schema: Common Fields. The value of `include` MUST be a comma-separated list of "relationship paths", as defined in the [JSON API](https://jsonapi.org/format/1.0/#fetching-includes). If relationship paths are not supported, or a server is unable to identify a relationship path a `400 Bad Request` response MUST be made. The **default value** for `include` is `references`. This means `references` entries MUST always be included under the top-level field `included` as default, since a server assumes if `include` is not specified by a client in the request, it is still specified as `include=references`. Note, if a client explicitly specifies `include` and leaves out `references`, `references` resource objects MUST NOT be included under the top-level field `included`, as per the definition of `included`, see section JSON Response Schema: Common Fields. > **Note**: A query with the parameter `include` set to the empty string means no related resource objects are to be returned under the top-level field `included`. (default: references)
  --api-hint: string # If the client provides the parameter, the value SHOULD have the format `vMAJOR` or `vMAJOR.MINOR`, where MAJOR is a major version and MINOR is a minor version of the API. For example, if a client appends `api_hint=v1.0` to the query string, the hint provided is for major version 1 and minor version 0. (default: )
]: nothing -> record<data: any, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: any, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "response_format" $response_format "scalar") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_limit" $page_limit "scalar") (serialize-qp "page_offset" $page_offset "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "page_above" $page_above "scalar") (serialize-qp "page_below" $page_below "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "api_hint" $api_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "response_format": $response_format, "email_address": $email_address, "response_fields": $response_fields, "sort": $qp_sort, "page_limit": $page_limit, "page_offset": $page_offset, "page_number": $page_number, "page_cursor": $page_cursor, "page_above": $page_above, "page_below": $page_below, "include": $include, "api_hint": $api_hint} | compact), body: null}
}

# Get References
#
# GET /references
# operationId: get_references_references_get
export def "references get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter string, in the format described in section API Filtering Format Specification of the specification. (default: )
  --response-format: string # The output format requested (see section Response Format). Defaults to the format string 'json', which specifies the standard output format described in this specification. Example: `http://example.com/v1/structures?response_format=xml` (default: json)
  --email-address: string # An email address of the user making the request. The email SHOULD be that of a person and not an automatic system. Example: `http://example.com/v1/structures?email_address=user@example.com` (format: email, default: )
  --response-fields: string # A comma-delimited set of fields to be provided in the output. If provided, these fields MUST be returned along with the REQUIRED fields. Other OPTIONAL fields MUST NOT be returned when this parameter is present. Example: `http://example.com/v1/structures?response_fields=last_modified,nsites` (default: )
  --qp-sort: string # If supporting sortable queries, an implementation MUST use the `sort` query parameter with format as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-sorting). An implementation MAY support multiple sort fields for a single query. If it does, it again MUST conform to the JSON API 1.0 specification. If an implementation supports sorting for an entry listing endpoint, then the `/info/` endpoint MUST include, for each field name `` in its `data.properties.` response value that can be used for sorting, the key `sortable` with value `true`. If a field name under an entry listing endpoint supporting sorting cannot be used for sorting, the server MUST either leave out the `sortable` key or set it equal to `false` for the specific field name. The set of field names, with `sortable` equal to `true` are allowed to be used in the "sort fields" list according to its definition in the JSON API 1.0 specification. The field `sortable` is in addition to each property description and other OPTIONAL fields. An example is shown in the section Entry Listing Info Endpoints. (default: )
  --page-limit: int # Sets a numerical limit on the number of entries returned. See [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-pagination). The API implementation MUST return no more than the number specified. It MAY return fewer. The database MAY have a maximum limit and not accept larger numbers (in which case an error code -- 403 Forbidden -- MUST be returned). The default limit value is up to the API implementation to decide. Example: `http://example.com/optimade/v1/structures?page_limit=100` (default: 20)
  --page-offset: int # RECOMMENDED for use with _offset-based_ pagination: using `page_offset` and `page_limit` is RECOMMENDED. Example: Skip 50 structures and fetch up to 100: `/structures?page_offset=50&page_limit=100`. (default: 0)
  --page-number: int # RECOMMENDED for use with _page-based_ pagination: using `page_number` and `page_limit` is RECOMMENDED. It is RECOMMENDED that the first page has number 1, i.e., that `page_number` is 1-based. Example: Fetch page 2 of up to 50 structures per page: `/structures?page_number=2&page_limit=50`. (default: 0)
  --page-cursor: int # RECOMMENDED for use with _cursor-based_ pagination: using `page_cursor` and `page_limit` is RECOMMENDED. (default: 0)
  --page-above: int # RECOMMENDED for use with _value-based_ pagination: using `page_above`/`page_below` and `page_limit` is RECOMMENDED. Example: Fetch up to 100 structures above sort-field value 4000 (in this example, server chooses to fetch results sorted by increasing `id`, so `page_above` value refers to an `id` value): `/structures?page_above=4000&page_limit=100`. (default: 0)
  --page-below: int # RECOMMENDED for use with _value-based_ pagination: using `page_above`/`page_below` and `page_limit` is RECOMMENDED. (default: 0)
  --include: string # A server MAY implement the JSON API concept of returning [compound documents](https://jsonapi.org/format/1.0/#document-compound-documents) by utilizing the `include` query parameter as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-includes). All related resource objects MUST be returned as part of an array value for the top-level `included` field, see the section JSON Response Schema: Common Fields. The value of `include` MUST be a comma-separated list of "relationship paths", as defined in the [JSON API](https://jsonapi.org/format/1.0/#fetching-includes). If relationship paths are not supported, or a server is unable to identify a relationship path a `400 Bad Request` response MUST be made. The **default value** for `include` is `references`. This means `references` entries MUST always be included under the top-level field `included` as default, since a server assumes if `include` is not specified by a client in the request, it is still specified as `include=references`. Note, if a client explicitly specifies `include` and leaves out `references`, `references` resource objects MUST NOT be included under the top-level field `included`, as per the definition of `included`, see section JSON Response Schema: Common Fields. > **Note**: A query with the parameter `include` set to the empty string means no related resource objects are to be returned under the top-level field `included`. (default: references)
  --api-hint: string # If the client provides the parameter, the value SHOULD have the format `vMAJOR` or `vMAJOR.MINOR`, where MAJOR is a major version and MINOR is a minor version of the API. For example, if a client appends `api_hint=v1.0` to the query string, the hint provided is for major version 1 and minor version 0. (default: )
]: nothing -> record<data: any, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: any, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "response_format" $response_format "scalar") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_limit" $page_limit "scalar") (serialize-qp "page_offset" $page_offset "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "page_above" $page_above "scalar") (serialize-qp "page_below" $page_below "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "api_hint" $api_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/references" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "response_format": $response_format, "email_address": $email_address, "response_fields": $response_fields, "sort": $qp_sort, "page_limit": $page_limit, "page_offset": $page_offset, "page_number": $page_number, "page_cursor": $page_cursor, "page_above": $page_above, "page_below": $page_below, "include": $include, "api_hint": $api_hint} | compact), body: null}
}

# Get Single Reference
#
# GET /references/{entry_id}
# operationId: get_single_reference_references__entry_id__get
export def "references get-single" [
  entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-format: string # The output format requested (see section Response Format). Defaults to the format string 'json', which specifies the standard output format described in this specification. Example: `http://example.com/v1/structures?response_format=xml` (default: json)
  --email-address: string # An email address of the user making the request. The email SHOULD be that of a person and not an automatic system. Example: `http://example.com/v1/structures?email_address=user@example.com` (format: email, default: )
  --response-fields: string # A comma-delimited set of fields to be provided in the output. If provided, these fields MUST be returned along with the REQUIRED fields. Other OPTIONAL fields MUST NOT be returned when this parameter is present. Example: `http://example.com/v1/structures?response_fields=last_modified,nsites` (default: )
  --include: string # A server MAY implement the JSON API concept of returning [compound documents](https://jsonapi.org/format/1.0/#document-compound-documents) by utilizing the `include` query parameter as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-includes). All related resource objects MUST be returned as part of an array value for the top-level `included` field, see the section JSON Response Schema: Common Fields. The value of `include` MUST be a comma-separated list of "relationship paths", as defined in the [JSON API](https://jsonapi.org/format/1.0/#fetching-includes). If relationship paths are not supported, or a server is unable to identify a relationship path a `400 Bad Request` response MUST be made. The **default value** for `include` is `references`. This means `references` entries MUST always be included under the top-level field `included` as default, since a server assumes if `include` is not specified by a client in the request, it is still specified as `include=references`. Note, if a client explicitly specifies `include` and leaves out `references`, `references` resource objects MUST NOT be included under the top-level field `included`, as per the definition of `included`, see section JSON Response Schema: Common Fields. > **Note**: A query with the parameter `include` set to the empty string means no related resource objects are to be returned under the top-level field `included`. (default: references)
  --api-hint: string # If the client provides the parameter, the value SHOULD have the format `vMAJOR` or `vMAJOR.MINOR`, where MAJOR is a major version and MINOR is a minor version of the API. For example, if a client appends `api_hint=v1.0` to the query string, the hint provided is for major version 1 and minor version 0. (default: )
]: nothing -> record<data: any, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: any, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_id | is-empty) { error make --unspanned { msg: "path parameter 'entry_id' must be non-empty" } }
  let qp = [(serialize-qp "response_format" $response_format "scalar") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "api_hint" $api_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entry_id: (encode-path-segment $entry_id)} | format pattern "/references/{entry_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"response_format": $response_format, "email_address": $email_address, "response_fields": $response_fields, "include": $include, "api_hint": $api_hint} | compact), body: null}
}

# Get Structures
#
# GET /structures
# operationId: get_structures_structures_get
export def "structures get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # A filter string, in the format described in section API Filtering Format Specification of the specification. (default: )
  --response-format: string # The output format requested (see section Response Format). Defaults to the format string 'json', which specifies the standard output format described in this specification. Example: `http://example.com/v1/structures?response_format=xml` (default: json)
  --email-address: string # An email address of the user making the request. The email SHOULD be that of a person and not an automatic system. Example: `http://example.com/v1/structures?email_address=user@example.com` (format: email, default: )
  --response-fields: string # A comma-delimited set of fields to be provided in the output. If provided, these fields MUST be returned along with the REQUIRED fields. Other OPTIONAL fields MUST NOT be returned when this parameter is present. Example: `http://example.com/v1/structures?response_fields=last_modified,nsites` (default: )
  --qp-sort: string # If supporting sortable queries, an implementation MUST use the `sort` query parameter with format as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-sorting). An implementation MAY support multiple sort fields for a single query. If it does, it again MUST conform to the JSON API 1.0 specification. If an implementation supports sorting for an entry listing endpoint, then the `/info/` endpoint MUST include, for each field name `` in its `data.properties.` response value that can be used for sorting, the key `sortable` with value `true`. If a field name under an entry listing endpoint supporting sorting cannot be used for sorting, the server MUST either leave out the `sortable` key or set it equal to `false` for the specific field name. The set of field names, with `sortable` equal to `true` are allowed to be used in the "sort fields" list according to its definition in the JSON API 1.0 specification. The field `sortable` is in addition to each property description and other OPTIONAL fields. An example is shown in the section Entry Listing Info Endpoints. (default: )
  --page-limit: int # Sets a numerical limit on the number of entries returned. See [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-pagination). The API implementation MUST return no more than the number specified. It MAY return fewer. The database MAY have a maximum limit and not accept larger numbers (in which case an error code -- 403 Forbidden -- MUST be returned). The default limit value is up to the API implementation to decide. Example: `http://example.com/optimade/v1/structures?page_limit=100` (default: 20)
  --page-offset: int # RECOMMENDED for use with _offset-based_ pagination: using `page_offset` and `page_limit` is RECOMMENDED. Example: Skip 50 structures and fetch up to 100: `/structures?page_offset=50&page_limit=100`. (default: 0)
  --page-number: int # RECOMMENDED for use with _page-based_ pagination: using `page_number` and `page_limit` is RECOMMENDED. It is RECOMMENDED that the first page has number 1, i.e., that `page_number` is 1-based. Example: Fetch page 2 of up to 50 structures per page: `/structures?page_number=2&page_limit=50`. (default: 0)
  --page-cursor: int # RECOMMENDED for use with _cursor-based_ pagination: using `page_cursor` and `page_limit` is RECOMMENDED. (default: 0)
  --page-above: int # RECOMMENDED for use with _value-based_ pagination: using `page_above`/`page_below` and `page_limit` is RECOMMENDED. Example: Fetch up to 100 structures above sort-field value 4000 (in this example, server chooses to fetch results sorted by increasing `id`, so `page_above` value refers to an `id` value): `/structures?page_above=4000&page_limit=100`. (default: 0)
  --page-below: int # RECOMMENDED for use with _value-based_ pagination: using `page_above`/`page_below` and `page_limit` is RECOMMENDED. (default: 0)
  --include: string # A server MAY implement the JSON API concept of returning [compound documents](https://jsonapi.org/format/1.0/#document-compound-documents) by utilizing the `include` query parameter as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-includes). All related resource objects MUST be returned as part of an array value for the top-level `included` field, see the section JSON Response Schema: Common Fields. The value of `include` MUST be a comma-separated list of "relationship paths", as defined in the [JSON API](https://jsonapi.org/format/1.0/#fetching-includes). If relationship paths are not supported, or a server is unable to identify a relationship path a `400 Bad Request` response MUST be made. The **default value** for `include` is `references`. This means `references` entries MUST always be included under the top-level field `included` as default, since a server assumes if `include` is not specified by a client in the request, it is still specified as `include=references`. Note, if a client explicitly specifies `include` and leaves out `references`, `references` resource objects MUST NOT be included under the top-level field `included`, as per the definition of `included`, see section JSON Response Schema: Common Fields. > **Note**: A query with the parameter `include` set to the empty string means no related resource objects are to be returned under the top-level field `included`. (default: references)
  --api-hint: string # If the client provides the parameter, the value SHOULD have the format `vMAJOR` or `vMAJOR.MINOR`, where MAJOR is a major version and MINOR is a minor version of the API. For example, if a client appends `api_hint=v1.0` to the query string, the hint provided is for major version 1 and minor version 0. (default: )
]: nothing -> record<data: any, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: any, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "response_format" $response_format "scalar") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page_limit" $page_limit "scalar") (serialize-qp "page_offset" $page_offset "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "page_cursor" $page_cursor "scalar") (serialize-qp "page_above" $page_above "scalar") (serialize-qp "page_below" $page_below "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "api_hint" $api_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/structures" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "response_format": $response_format, "email_address": $email_address, "response_fields": $response_fields, "sort": $qp_sort, "page_limit": $page_limit, "page_offset": $page_offset, "page_number": $page_number, "page_cursor": $page_cursor, "page_above": $page_above, "page_below": $page_below, "include": $include, "api_hint": $api_hint} | compact), body: null}
}

# Get Single Structure
#
# GET /structures/{entry_id}
# operationId: get_single_structure_structures__entry_id__get
export def "structures get-single" [
  entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-format: string # The output format requested (see section Response Format). Defaults to the format string 'json', which specifies the standard output format described in this specification. Example: `http://example.com/v1/structures?response_format=xml` (default: json)
  --email-address: string # An email address of the user making the request. The email SHOULD be that of a person and not an automatic system. Example: `http://example.com/v1/structures?email_address=user@example.com` (format: email, default: )
  --response-fields: string # A comma-delimited set of fields to be provided in the output. If provided, these fields MUST be returned along with the REQUIRED fields. Other OPTIONAL fields MUST NOT be returned when this parameter is present. Example: `http://example.com/v1/structures?response_fields=last_modified,nsites` (default: )
  --include: string # A server MAY implement the JSON API concept of returning [compound documents](https://jsonapi.org/format/1.0/#document-compound-documents) by utilizing the `include` query parameter as specified by [JSON API 1.0](https://jsonapi.org/format/1.0/#fetching-includes). All related resource objects MUST be returned as part of an array value for the top-level `included` field, see the section JSON Response Schema: Common Fields. The value of `include` MUST be a comma-separated list of "relationship paths", as defined in the [JSON API](https://jsonapi.org/format/1.0/#fetching-includes). If relationship paths are not supported, or a server is unable to identify a relationship path a `400 Bad Request` response MUST be made. The **default value** for `include` is `references`. This means `references` entries MUST always be included under the top-level field `included` as default, since a server assumes if `include` is not specified by a client in the request, it is still specified as `include=references`. Note, if a client explicitly specifies `include` and leaves out `references`, `references` resource objects MUST NOT be included under the top-level field `included`, as per the definition of `included`, see section JSON Response Schema: Common Fields. > **Note**: A query with the parameter `include` set to the empty string means no related resource objects are to be returned under the top-level field `included`. (default: references)
  --api-hint: string # If the client provides the parameter, the value SHOULD have the format `vMAJOR` or `vMAJOR.MINOR`, where MAJOR is a major version and MINOR is a minor version of the API. For example, if a client appends `api_hint=v1.0` to the query string, the hint provided is for major version 1 and minor version 0. (default: )
]: nothing -> record<data: any, errors: table<code: string, detail: string, id: string, links: record, meta: record, source: record, status: string, title: string>, included: any, jsonapi: record<meta: record, version: string>, links: record<first: any, last: any, next: any, prev: any, related: any, self: any>, meta: record<api_version: string, data_available: int, data_returned: int, implementation: record<homepage: any, issue_tracker: any, maintainer: record, name: string, source_url: any, version: string>, last_id: string, more_data_available: bool, provider: record<description: string, homepage: any, name: string, prefix: string>, query: record<representation: string>, response_message: string, schema: any, time_stamp: string, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_id | is-empty) { error make --unspanned { msg: "path parameter 'entry_id' must be non-empty" } }
  let qp = [(serialize-qp "response_format" $response_format "scalar") (serialize-qp "email_address" $email_address "scalar") (serialize-qp "response_fields" $response_fields "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "api_hint" $api_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entry_id: (encode-path-segment $entry_id)} | format pattern "/structures/{entry_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"response_format": $response_format, "email_address": $email_address, "response_fields": $response_fields, "include": $include, "api_hint": $api_hint} | compact), body: null}
}

# Get Versions
#
# GET /versions
# operationId: get_versions_versions_get
export def "versions get" [
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
  let full_url = (build-url $base "/versions")
  let accept_val = "text/csv; header=present"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
