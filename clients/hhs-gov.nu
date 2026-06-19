# Auto-generated client for HHS Media Services API v2
# Source: https://api.apis.guru/v2/specs/hhs.gov/2/openapi.json
# Auth: --token flag or $env.HHS_MEDIA_SERVICES_API_TOKEN

const BASE_URL = "http://localhost/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HHS_MEDIA_SERVICES_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "resources-json get" } } | get name | first)
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

# Get Resources by search query
#
# GET /resources.json
export def "resources-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The search query supplied by the user (format: )
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get Campaigns
#
# GET /resources/campaigns.json
export def "resources-campaigns-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination (format: int32)
  --qp-sort: string # * Set of fields to sort the records by. (format: )
]: nothing -> record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<contactEmail: string, description: string, endDate: string, id: int, name: string, source: record, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/campaigns.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max": $max, "offset": $offset, "sort": $qp_sort} | compact), body: null}
}

# Get Campaign by ID
#
# GET /resources/campaigns/{id}.json
export def "resources-campaigns get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<contactEmail: string, description: string, endDate: string, id: int, name: string, source: record, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/campaigns/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get MediaItems by Campaign ID
#
# GET /resources/campaigns/{id}/media.json
export def "resources-campaigns-media-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination (format: int32)
]: nothing -> record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<campaigns: list, createdBy: string, customAttributionUrl: string, customPreviewUrl: string, customThumbnailUrl: string, dateContentAuthored: string, dateContentPublished: string, dateContentReviewed: string, dateContentUpdated: string, dateSyndicationCaptured: string, dateSyndicationUpdated: string, dateSyndicationVisible: string, description: string, extendedAttributes: list, externalGuid: string, foreignSyndicationAPIUrl: string, hash: string, id: int, language: record, mediaType: string, name: string, source: record, sourceUrl: string, targetUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/campaigns/{id}/media.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "max": $max, "offset": $offset} | compact), body: null}
}

# Get MediaItems for Campaign
#
# GET /resources/campaigns/{id}/syndicate.{format}
export def "resources-campaigns-syndicate-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<content: string, description: string, id: int, mediaType: string, name: string, sourceUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "displayMethod" $display_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/campaigns/{id}/syndicate.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"displayMethod": $display_method} | compact), body: null}
}

# Get Languages
#
# GET /resources/languages.json
export def "resources-languages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/languages.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max": $max, "offset": $offset, "sort": $qp_sort} | compact), body: null}
}

# Get Language by ID
#
# GET /resources/languages/{id}.json
export def "resources-languages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/languages/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get MediaItems
#
# GET /resources/media.json
export def "resources-media-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination. (format: int32)
  --qp-sort: string # * Set of fields to sort the records by. (format: )
  --order: string # * The ascending or descending order. (format: )
  --media-types: string # Find all media items belonging to the specified media type[s]. (format: )
  --name: string # Find all media items containing the provided name, case insensitive. (format: )
  --collection-id: int # Restrict filtering to media items in a specific collection. (format: int32)
  --name-contains: string # Find all media items containing the partial name, case insensitive. (format: )
  --description-contains: string # Find all media items containing the provided partial description, case insensitive. (format: )
  --source-url: string # Find all media items which have the provided sourceUrl, case insensitive. (format: )
  --source-url-contains: string # Find all media items which contain the provided partial sourceUrl, case insensitive. (format: )
  --custom-thumbnail-url: string # Find all media items which have the provided customThumbnailUrl, case insensitive. (format: )
  --custom-thumbnail-url-contains: string # Find all media items which contain the provided partial customThumbnailUrl, case insensitive. (format: )
  --date-content-authored: string # Find all media items authored on the provided day (RFC 3339, time ignored). (format: date)
  --date-content-updated: string # Find all media items updated on the provided day (RFC 3339, time ignored). (format: date)
  --date-content-published: string # Find all media items published on the provided day (RFC 3339, time ignored). (format: date)
  --date-content-reviewed: string # Find all media items reviewed on the provided day (RFC 3339, time ignored). (format: date)
  --date-syndication-captured: string # Find all media items syndicated on the provided day (RFC 3339, time ignored). (format: date)
  --date-syndication-updated: string # Find all media items updated through the syndication system on the provided day, (RFC 3339, time ignored). (format: date)
  --content-authored-since-date: string # Find all media items authored since the provided day (RFC 3339, time ignored). (format: date)
  --content-authored-before-date: string # Find all media items authored before the provided day (RFC 3339, time ignored). (format: date)
  --content-authored-in-range: string # Find all media items authored between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --content-updated-since-date: string # Find all media items updated since the provided day (RFC 3339, time ignored). (format: date)
  --content-updated-before-date: string # Find all media items updated before the provided day (RFC 3339, time ignored). (format: date)
  --content-updated-in-range: string # Find all media items updated between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --content-published-since-date: string # Find all media items updated since the provided day (RFC 3339, time ignored). (format: date)
  --content-published-before-date: string # Find all media items published before the provided day (RFC 3339, time ignored). (format: date)
  --content-published-in-range: string # Find all media items published between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --content-reviewed-since-date: string # Find all media items reviewed since the provided day (RFC 3339, time ignored). (format: date)
  --content-reviewed-before-date: string # Find all media items reviewed before the provided day (RFC 3339, time ignored). (format: date)
  --content-reviewed-in-range: string # Find all media items reviewed between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --syndication-captured-since-date: string # Find all media items authored since the provided day (RFC 3339, time ignored). (format: date)
  --syndication-captured-before-date: string # Find all media items authored before the provided day (RFC 3339, time ignored). (format: date)
  --syndication-captured-in-range: string # Find all media items authored between the provided start and end days (RFC 3339, comma separated, time ignored). (format: )
  --syndication-updated-since-date: string # Find all media items updated since the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-updated-before-date: string # Find all media items updated before the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-updated-in-range: string # Find all media items updated between the provided start and end days, (RFC 3339, comma separated, time ignored). (format: )
  --syndication-visible-since-date: string # Find all media items visible since the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-visible-before-date: string # Find all media items visible before the provided day, (RFC 3339, time ignored). (format: date)
  --syndication-visible-in-range: string # Find all media items visible between the provided start and end days, (RFC 3339, comma separated, time ignored). (format: date)
  --language-id: int # Find all media items written in the language specified by Id. (format: int64)
  --language-name: string # Find all media items written in the language specified by name, case insensitive. (format: )
  --language-iso-code: string # Find all media items written in the language specified by 639-2 isoCode , case insensitive. (format: )
  --hash: string # Find all media items which match the provided hash, case insensitive. (format: )
  --hash-contains: string # Find all media items which match the provided partial hash, case insensitive. (format: )
  --source-id: int # Find all media items that belong to the source specified by Id. (format: int64)
  --source-name: string # Find all media items that belong to the source specified by name, case insensitive. (format: )
  --source-name-contains: string # Find all media items that belong to the source specified by partial name, case insensitive. (format: )
  --source-acronym: string # Find all media items that belong to the source specified by acronym, case insensitive. (format: )
  --source-acronym-contains: string # Find all media items that belong to the source specified by partial acronym, case insensitive. (format: )
  --tag-ids: string # Find only media items tagged with the specified tag Ids. (format: )
  --restrict-to-set: string # Find only media from within the supplied list of Ids. (format: )
  --created-by: string # Find all media items containing the createdBy value. (format: )
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "mediaTypes" $media_types "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "collectionId" $collection_id "scalar") (serialize-qp "nameContains" $name_contains "scalar") (serialize-qp "descriptionContains" $description_contains "scalar") (serialize-qp "sourceUrl" $source_url "scalar") (serialize-qp "sourceUrlContains" $source_url_contains "scalar") (serialize-qp "customThumbnailUrl" $custom_thumbnail_url "scalar") (serialize-qp "customThumbnailUrlContains" $custom_thumbnail_url_contains "scalar") (serialize-qp "dateContentAuthored" $date_content_authored "scalar") (serialize-qp "dateContentUpdated" $date_content_updated "scalar") (serialize-qp "dateContentPublished" $date_content_published "scalar") (serialize-qp "dateContentReviewed" $date_content_reviewed "scalar") (serialize-qp "dateSyndicationCaptured" $date_syndication_captured "scalar") (serialize-qp "dateSyndicationUpdated" $date_syndication_updated "scalar") (serialize-qp "contentAuthoredSinceDate" $content_authored_since_date "scalar") (serialize-qp "contentAuthoredBeforeDate" $content_authored_before_date "scalar") (serialize-qp "contentAuthoredInRange" $content_authored_in_range "scalar") (serialize-qp "contentUpdatedSinceDate" $content_updated_since_date "scalar") (serialize-qp "contentUpdatedBeforeDate" $content_updated_before_date "scalar") (serialize-qp "contentUpdatedInRange" $content_updated_in_range "scalar") (serialize-qp "contentPublishedSinceDate" $content_published_since_date "scalar") (serialize-qp "contentPublishedBeforeDate" $content_published_before_date "scalar") (serialize-qp "contentPublishedInRange" $content_published_in_range "scalar") (serialize-qp "contentReviewedSinceDate" $content_reviewed_since_date "scalar") (serialize-qp "contentReviewedBeforeDate" $content_reviewed_before_date "scalar") (serialize-qp "contentReviewedInRange" $content_reviewed_in_range "scalar") (serialize-qp "syndicationCapturedSinceDate" $syndication_captured_since_date "scalar") (serialize-qp "syndicationCapturedBeforeDate" $syndication_captured_before_date "scalar") (serialize-qp "syndicationCapturedInRange" $syndication_captured_in_range "scalar") (serialize-qp "syndicationUpdatedSinceDate" $syndication_updated_since_date "scalar") (serialize-qp "syndicationUpdatedBeforeDate" $syndication_updated_before_date "scalar") (serialize-qp "syndicationUpdatedInRange" $syndication_updated_in_range "scalar") (serialize-qp "syndicationVisibleSinceDate" $syndication_visible_since_date "scalar") (serialize-qp "syndicationVisibleBeforeDate" $syndication_visible_before_date "scalar") (serialize-qp "syndicationVisibleInRange" $syndication_visible_in_range "scalar") (serialize-qp "languageId" $language_id "scalar") (serialize-qp "languageName" $language_name "scalar") (serialize-qp "languageIsoCode" $language_iso_code "scalar") (serialize-qp "hash" $hash "scalar") (serialize-qp "hashContains" $hash_contains "scalar") (serialize-qp "sourceId" $source_id "scalar") (serialize-qp "sourceName" $source_name "scalar") (serialize-qp "sourceNameContains" $source_name_contains "scalar") (serialize-qp "sourceAcronym" $source_acronym "scalar") (serialize-qp "sourceAcronymContains" $source_acronym_contains "scalar") (serialize-qp "tagIds" $tag_ids "scalar") (serialize-qp "restrictToSet" $restrict_to_set "scalar") (serialize-qp "createdBy" $created_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/media.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max": $max, "offset": $offset, "sort": $qp_sort, "order": $order, "mediaTypes": $media_types, "name": $name, "collectionId": $collection_id, "nameContains": $name_contains, "descriptionContains": $description_contains, "sourceUrl": $source_url, "sourceUrlContains": $source_url_contains, "customThumbnailUrl": $custom_thumbnail_url, "customThumbnailUrlContains": $custom_thumbnail_url_contains, "dateContentAuthored": $date_content_authored, "dateContentUpdated": $date_content_updated, "dateContentPublished": $date_content_published, "dateContentReviewed": $date_content_reviewed, "dateSyndicationCaptured": $date_syndication_captured, "dateSyndicationUpdated": $date_syndication_updated, "contentAuthoredSinceDate": $content_authored_since_date, "contentAuthoredBeforeDate": $content_authored_before_date, "contentAuthoredInRange": $content_authored_in_range, "contentUpdatedSinceDate": $content_updated_since_date, "contentUpdatedBeforeDate": $content_updated_before_date, "contentUpdatedInRange": $content_updated_in_range, "contentPublishedSinceDate": $content_published_since_date, "contentPublishedBeforeDate": $content_published_before_date, "contentPublishedInRange": $content_published_in_range, "contentReviewedSinceDate": $content_reviewed_since_date, "contentReviewedBeforeDate": $content_reviewed_before_date, "contentReviewedInRange": $content_reviewed_in_range, "syndicationCapturedSinceDate": $syndication_captured_since_date, "syndicationCapturedBeforeDate": $syndication_captured_before_date, "syndicationCapturedInRange": $syndication_captured_in_range, "syndicationUpdatedSinceDate": $syndication_updated_since_date, "syndicationUpdatedBeforeDate": $syndication_updated_before_date, "syndicationUpdatedInRange": $syndication_updated_in_range, "syndicationVisibleSinceDate": $syndication_visible_since_date, "syndicationVisibleBeforeDate": $syndication_visible_before_date, "syndicationVisibleInRange": $syndication_visible_in_range, "languageId": $language_id, "languageName": $language_name, "languageIsoCode": $language_iso_code, "hash": $hash, "hashContains": $hash_contains, "sourceId": $source_id, "sourceName": $source_name, "sourceNameContains": $source_name_contains, "sourceAcronym": $source_acronym, "sourceAcronymContains": $source_acronym_contains, "tagIds": $tag_ids, "restrictToSet": $restrict_to_set, "createdBy": $created_by} | compact), body: null}
}

# Get the list of featured content in the syndication system
#
# GET /resources/media/featured.json
export def "resources-media-featured-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
]: nothing -> table<campaigns: list<record>, createdBy: string, customAttributionUrl: string, customPreviewUrl: string, customThumbnailUrl: string, dateContentAuthored: string, dateContentPublished: string, dateContentReviewed: string, dateContentUpdated: string, dateSyndicationCaptured: string, dateSyndicationUpdated: string, dateSyndicationVisible: string, description: string, extendedAttributes: list<record>, externalGuid: string, foreignSyndicationAPIUrl: string, hash: string, id: int, language: record<id: int, isActive: bool, isoCode: string, name: string>, mediaType: string, name: string, source: record<acronym: string, contactEmail: string, id: int, largeLogoUrl: string, name: string, smallLogoUrl: string, websiteUrl: string>, sourceUrl: string, targetUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/media/featured.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "max": $max, "offset": $offset} | compact), body: null}
}

# Get MediaItems by popularity
#
# GET /resources/media/mostPopularMedia.{format}
export def "resources-media-most-popular-media-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination. (format: int32)
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/resources/media/mostPopularMedia.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max": $max, "offset": $offset} | compact), body: null}
}

# Get MediaItems by search query
#
# GET /resources/media/searchResults.json
export def "resources-media-search-results-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The search query supplied by the user (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # The offset of the records set to return for pagination. (format: int32)
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/media/searchResults.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "max": $max, "offset": $offset} | compact), body: null}
}

# Get MediaItem by ID
#
# GET /resources/media/{id}.json
export def "resources-media get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/media/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get content for MediaItem
#
# GET /resources/media/{id}/content
export def "resources-media-content get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --called-by-build: oneof<nothing, bool> # The method that called this method (format: )
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "calledByBuild" $called_by_build "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/media/{id}/content") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"calledByBuild": $called_by_build} | compact), body: null}
}

# Get embed code for MediaItem
#
# GET /resources/media/{id}/embed.json
export def "resources-media-embed-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flavor: string # Currently supports 'iframe', defaults to 'javascript'. (format: )
  --width: int # The width of the generated iframe. (format: int32)
  --height: int # The height of the generated iframe. (format: int32)
  --iframe-name: string # The name of the iframe element (format: )
  --exclude-jquery: oneof<nothing, bool> # Should a reference to the JQuery Library be omitted? (format: , default: false)
  --exclude-div: oneof<nothing, bool> # Should the div to insert content into be omitted? (format: , default: false)
  --div-id: string # Should the div to insert content into have a specific name? (format: )
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "flavor" $flavor "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "iframeName" $iframe_name "scalar") (serialize-qp "excludeJquery" $exclude_jquery "scalar") (serialize-qp "excludeDiv" $exclude_div "scalar") (serialize-qp "divId" $div_id "scalar") (serialize-qp "displayMethod" $display_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/media/{id}/embed.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"flavor": $flavor, "width": $width, "height": $height, "iframeName": $iframe_name, "excludeJquery": $exclude_jquery, "excludeDiv": $exclude_div, "divId": $div_id, "displayMethod": $display_method} | compact), body: null}
}

# Get Tag by ID
#
# GET /resources/media/{id}/preview.jpg
export def "resources-media-preview-jpg get" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/media/{id}/preview.jpg"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get related MediaItems by ID
#
# GET /resources/media/{id}/relatedMedia.{format}
export def "resources-media-related-media-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/media/{id}/relatedMedia.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max": $max, "offset": $offset, "sort": $qp_sort} | compact), body: null}
}

# Get syndicated content for MediaItem
#
# GET /resources/media/{id}/syndicate.{format}
export def "resources-media-syndicate-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css-class: string # The css class to target for extraction. (format: , default: syndicate)
  --strip-styles: oneof<nothing, bool> # Remove in-line styles from content. (format: , default: false)
  --strip-scripts: oneof<nothing, bool> # Remove script tags from content. (format: , default: false)
  --strip-images: oneof<nothing, bool> # Remove image tags from content. (format: , default: false)
  --strip-breaks: oneof<nothing, bool> # Remove break tags from content. (format: , default: false)
  --strip-classes: oneof<nothing, bool> # Remove class attributes from content (except 'syndicate'). (format: , default: false)
  --font-size: int # Set font size (in points) of p, div, and span tags. (format: int32)
  --image-float: string # Accepts valid CSS float options, such as 'left' or 'right'. Will inject a style into the content before rendering. (format: )
  --image-margin: string # Accepts 4 CSV values representing pixel sizes of margin similar to CSS. Default format is 'north,east,south,west' - for example '0,10,10,0' would put a 10 pixel margin on the right and bottom sides of an image. Will inject a style into the content before rendering. (format: )
  --autoplay: oneof<nothing, bool> # If content is a video, the embeded video will auto play when loaded. (format: , default: true)
  --rel: oneof<nothing, bool> # If content is a video, related items will be shown at the end of playback. (format: , default: false)
]: nothing -> record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: table<content: string, description: string, id: int, mediaType: string, name: string, sourceUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "cssClass" $css_class "scalar") (serialize-qp "stripStyles" $strip_styles "scalar") (serialize-qp "stripScripts" $strip_scripts "scalar") (serialize-qp "stripImages" $strip_images "scalar") (serialize-qp "stripBreaks" $strip_breaks "scalar") (serialize-qp "stripClasses" $strip_classes "scalar") (serialize-qp "font-size" $font_size "scalar") (serialize-qp "imageFloat" $image_float "scalar") (serialize-qp "imageMargin" $image_margin "scalar") (serialize-qp "autoplay" $autoplay "scalar") (serialize-qp "rel" $rel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/media/{id}/syndicate.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cssClass": $css_class, "stripStyles": $strip_styles, "stripScripts": $strip_scripts, "stripImages": $strip_images, "stripBreaks": $strip_breaks, "stripClasses": $strip_classes, "font-size": $font_size, "imageFloat": $image_float, "imageMargin": $image_margin, "autoplay": $autoplay, "rel": $rel} | compact), body: null}
}

# Get JPG thumbnail for MediaItem
#
# GET /resources/media/{id}/thumbnail.jpg
export def "resources-media-thumbnail-jpg get" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/media/{id}/thumbnail.jpg"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Youtube metadata for MediaItem
#
# GET /resources/media/{id}/youtubeMetaData.json
export def "resources-media-youtube-meta-data-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callback: string, meta: record<messages: list<record>, pagination: record<count: int, currentUrl: string, max: int, nextUrl: string, offset: int, pageNum: int, previousUrl: string, sort: string, total: int, totalPages: int>, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/media/{id}/youtubeMetaData.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get MediaTypes
#
# GET /resources/mediaTypes.{format}
export def "resources-media-types-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/resources/mediaTypes.{format}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Sources
#
# GET /resources/sources.json
export def "resources-sources-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/sources.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"max": $max, "offset": $offset, "sort": $qp_sort} | compact), body: null}
}

# Get Source by ID
#
# GET /resources/sources/{id}.json
export def "resources-sources get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/sources/{id}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get MediaItems for Source
#
# GET /resources/sources/{id}/syndicate.{format}
export def "resources-sources-syndicate-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "displayMethod" $display_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/sources/{id}/syndicate.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"displayMethod": $display_method} | compact), body: null}
}

# Get Tags
#
# GET /resources/tags.{format}
export def "resources-tags-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
  --name: string # Return tags[s] matching the supplied name (format: )
  --name-contains: string # Return tags which contain the supplied partial name. (format: )
  --media-id: int # Return tags associated with the supplied media id. (format: int64)
  --type-id: int # Return tags belonging to the supplied tag type id. (format: int64)
  --type-name: string # Return tags belonging to the supplied tag type name. (format: )
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "nameContains" $name_contains "scalar") (serialize-qp "mediaId" $media_id "scalar") (serialize-qp "typeId" $type_id "scalar") (serialize-qp "typeName" $type_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/resources/tags.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "max": $max, "offset": $offset, "name": $name, "nameContains": $name_contains, "mediaId": $media_id, "typeId": $type_id, "typeName": $type_name} | compact), body: null}
}

# Get TagLanguages
#
# GET /resources/tags/tagLanguages.{format}
export def "resources-tags-tag-languages-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/resources/tags/tagLanguages.{format}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get MediaItems for Tag
#
# GET /resources/tags/tagTypes.{format}
export def "resources-tags-tag-types-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/resources/tags/tagTypes.{format}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Tag by ID
#
# GET /resources/tags/{id}.{format}
export def "resources-tags get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/tags/{id}.{format}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get MediaItems for Tag
#
# GET /resources/tags/{id}/media.{format}
export def "resources-tags-media-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/tags/{id}/media.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "max": $max, "offset": $offset} | compact), body: null}
}

# Get related Tags by ID
#
# GET /resources/tags/{id}/related.{format}
export def "resources-tags-related-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # The name of the property to which sorting will be applied (format: )
  --max: int # The maximum number of records to return (format: int32)
  --offset: int # Return records starting at the offset index. (format: int32)
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/tags/{id}/related.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "max": $max, "offset": $offset} | compact), body: null}
}

# Get MediaItems for Tag
#
# GET /resources/tags/{id}/syndicate.{format}
export def "resources-tags-syndicate-format get" [
  id: int
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: )
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "displayMethod" $display_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), format: (encode-path-segment $format)} | format pattern "/resources/tags/{id}/syndicate.{format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"displayMethod": $display_method} | compact), body: null}
}

# Get UserMediaList by ID
#
# GET /resources/userMediaLists/{id}.json
export def "resources-user-media-lists get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --display-method: string # Method used to render an html request. Accepts one: [mv, list, feed] (format: int64)
]: nothing -> table<callback: string, meta: record<messages: list, pagination: record, status: int>, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "displayMethod" $display_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/resources/userMediaLists/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"displayMethod": $display_method} | compact), body: null}
}
