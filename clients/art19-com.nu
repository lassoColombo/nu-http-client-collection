# Auto-generated client for ART19 Content API Documentation v1.0.0
# Source: https://api.apis.guru/v2/specs/art19.com/1.0.0/openapi.json
# Auth: --token flag or $env.ART19_CONTENT_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://art19.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ART19_CONTENT_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://art19.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def classification-type-completer [] { ["AlternateFeedType" "Genre" "Industry" "Language" "MediaRating"] }
def classified-type-completer [] { ["Episode" "Season" "Series"] }
def type-completer [] { ["AlternateFeedType" "Genre" "Industry" "Language" "MediaRating"] }
def creditable-type-completer [] { ["Episode" "Season" "Series"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "classification-inclusions list" } } | get name | first)
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

# Get ClassificationInclusion records
#
# GET /classification_inclusions
export def "classification-inclusions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --classification-id: string # Limit the result to classification inclusions linked to a classification with this ID. (format: uuid, e.g. a90609c0-9f0c-48fd-8a41-83eb8414bedb)
  --classification-type: string@classification-type-completer # The type of classification that the classification inclusions are linked to. Depending on the permissions of your credential, only a subset of these types are usable.
  --classified-id: string # Limit the result to classification inclusions linked to a resource with this ID. You will have to use this filter together with either `classified_type` or `classification_type`. (format: uuid, e.g. fee1976e-f1bc-48a9-9ee8-58800f4d3462)
  --classified-type: string@classified-type-completer # Limit the result to classification inclusions linked to this type of entity.
  --q: string # Limit the result to classification inclusions linked to a classification containing the parameter value disregarding case.
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: created_at)
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "classification_id" $classification_id "scalar") (serialize-qp "classification_type" $classification_type "scalar") (serialize-qp "classified_id" $classified_id "scalar") (serialize-qp "classified_type" $classified_type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/classification_inclusions" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "classification_id": $classification_id, "classification_type": $classification_type, "classified_id": $classified_id, "classified_type": $classified_type, "q": $q, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific classification inclusion
#
# GET /classification_inclusions/{id}
export def "classification-inclusions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<classification_id: string, classification_type: string, classified_id: string, classified_type: string, created_at: string, position: int, primary: bool, updated_at: string>, id: string, relationships: record<classification: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/classification_inclusions/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of classifications
#
# GET /classifications
export def "classifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --type: string@type-completer # Limit the result to classifications of this type. The possible values for types depends on the privileges of the provided credential. (e.g. Genre)
  --q: string # Limit the result to classifications with a value containing the parameter value disregarding case.
  --is-country: string # If this parameter is provided and not empty, limit the result to classifications of type `Geography` representing countries. The credential must have at least one privilege with a network, series, or advertiser profile. (e.g. true)
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: value)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "is_country" $is_country "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/classifications" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "type": $type, "q": $q, "is_country": $is_country, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific classification
#
# GET /classifications/{id}
export def "classifications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<created_at: string, display_name: string, metadata: record, parent_id: string, tree_path: list, type: string, updated_at: string, value: string, value_path: string>, id: string, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/classifications/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of credits
#
# GET /credits
export def "credits list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --creditable-id: string # Limit the result to credits for the entity with this ID only. If the entity is not published, the credential needs to have the right privilege to list the credits for it. (format: uuid, e.g. 76654e16-76ce-4945-92e9-e0a381917853)
  --creditable-type: string@creditable-type-completer # Limit the result to credits linked to this type of entity only. Depending on the privileges of the credential, this list might be further reduced to only published entities.
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: position)
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "creditable_id" $creditable_id "scalar") (serialize-qp "creditable_type" $creditable_type "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/credits" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "creditable_id": $creditable_id, "creditable_type": $creditable_type, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific credit
#
# GET /credits/{id}
export def "credits get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<created_at: string, position: int, type: string, updated_at: string>, id: string, relationships: record<creditable: record, person: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credits/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of episodes
#
# GET /episodes
export def "episodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --included-in-inventory-calendar: string # Limit the result to episodes usable with an inventory management calendar for the provided AdDeal ID. (format: uuid, e.g. b97239ef-1776-489a-a1df-5f70a8407148)
  --month: string # Limit the result to episodes released in this month.
  --published: oneof<nothing, bool> # If `true`, limit the result to published episodes only. If `false`, limit the result to _unpublished_ episodes only.
  --q: string # Limit the result to episodes with a title containing this parameter in a case-insensitive way.
  --released-after: string # Limit the result to episodes released after this timestamp. (format: date-time)
  --released-before: string # Limit the result to episodes released before this timestamp. (format: date-time)
  --rss: oneof<nothing, bool> # If `true`, limit the result to published and released episodes holding an available media file. If this is `true`, it also changes the default sort order to `-released_at`.
  --season-id: string # Limit result to episodes linked to this season. (format: uuid, e.g. 30e7b568-d099-486b-9a8e-51b7594cab7d)
  --series-id: string # Limit the result to episodes linked to this series. (format: uuid, e.g. d0ceb1ff-b95b-4c1e-a7e5-a36ed7b4d3b7)
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: sort_title)
  --year: string # Limit the result to episodes released in this year.
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "included_in_inventory_calendar" $included_in_inventory_calendar "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "published" $published "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "released_after" $released_after "scalar") (serialize-qp "released_before" $released_before "scalar") (serialize-qp "rss" $rss "scalar") (serialize-qp "season_id" $season_id "scalar") (serialize-qp "series_id" $series_id "scalar") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/episodes" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "included_in_inventory_calendar": $included_in_inventory_calendar, "month": $month, "published": $published, "q": $q, "released_after": $released_after, "released_before": $released_before, "rss": $rss, "season_id": $season_id, "series_id": $series_id, "sort": $qp_sort, "year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific episode
#
# GET /episodes/{id}
export def "episodes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/episodes/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the episode released right after the specified one
#
# GET /episodes/{id}/next_sibling
export def "episodes-next-sibling get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rss: oneof<nothing, bool> # If `true`, get the next released and published episode with an available media file.
]: nothing -> record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rss" $rss "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/episodes/{id}/next_sibling") $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rss": $rss} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the episode released right before the specified one
#
# GET /episodes/{id}/previous_sibling
export def "episodes-previous-sibling get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rss: oneof<nothing, bool> # If `true`, get the previously released and published episode with an available media file.
]: nothing -> record<data: record<attributes: record<allow_user_comments: bool, cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, file_name: string, itunes_type: string, listen_count: int, premium_status: string, published: bool, release_end_at: string, release_immediately: bool, released_at: string, rss_guid: string, season_id: string, series_id: string, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, default_marker_points: record, episode_versions: record, images: record, season: record, segment_lists: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "rss" $rss "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/episodes/{id}/previous_sibling") $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"rss": $rss} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of images
#
# GET /images
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/images" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific image
#
# GET /images/{id}
export def "images get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<bucket_id: string, bucket_type: string, created_at: string, crop_data: record, status: string, updated_at: string>, id: string, relationships: record<media_assets: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/images/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of media assets
#
# GET /media_assets
export def "media-assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/media_assets" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific media asset
#
# GET /media_assets/{id}
export def "media-assets get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<attachment_id: string, attachment_type: string, cdn_url: string, content_type: string, created_at: string, file_name: string, file_size: int, size_height: int, size_width: int, style: string, updated_at: string>, id: string, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/media_assets/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of networks
#
# GET /networks
export def "networks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --q: string # Limit the result to networks with a name containing this parameter in a case-insensitive way.
  --ad-rep-account-id: string # Limit the result to networks containing at least one series with an ad deal of this Ad Ops profile. (format: uuid)
  --ad-deal-status: list<string> # Limit the result to networks containing at least one series with an ad deal matching one of the values in this parameter.
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: name)
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "ad_rep_account_id" $ad_rep_account_id "scalar") (serialize-qp "ad_deal_status" $ad_deal_status "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/networks" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "q": $q, "ad_rep_account_id": $ad_rep_account_id, "ad_deal_status": $ad_deal_status, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific network
#
# GET /networks/{id}
export def "networks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<copyright: string, created_at: string, description: string, description_is_html: bool, description_plain: string, facebook_url: string, instagram_url: string, linkedin_url: string, name: string, public_email: string, public_page_enabled: bool, slug: string, tumblr_url: string, twitter_url: string, updated_at: string, website_url: string>, id: string, relationships: record<cover_image: record, images: record, parent: record, series: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/networks/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of people
#
# GET /people
export def "people list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --q: string # Limit the result to people with a full name containing this parameter in a case-insensitive way.
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: last_name,first_name)
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/people" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "q": $q, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific person
#
# GET /people/{id}
export def "people get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<avatar_id: string, biography: string, born: string, created_at: string, died: string, first_name: string, from_country: string, from_locality: string, from_region: string, last_name: string, public_email: string, updated_at: string>, id: string, relationships: record<avatar: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/people/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of seasons
#
# GET /seasons
export def "seasons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --series-id: string # Limit the result to seasons owned by this series. (format: uuid, e.g. 7ebd702d-07c8-4da9-a7a8-cf18ec414d5c)
  --q: string # Limit the result to seasons with a title containing this parameter in a case-insensitive way.
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: sort_title)
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "series_id" $series_id "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/seasons" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "series_id": $series_id, "q": $q, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific season
#
# GET /seasons/{id}
export def "seasons get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<cascaded_cover_image_id: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, first_released_episode_id: string, last_released_episode_id: string, season_number: int, sort_title: string, status: string, title: string, updated_at: string>, id: string, relationships: record<cascaded_cover_image: record, classification_inclusions: record, cover_image: record, credits: record, episodes: record, first_released_episode: record, images: record, last_released_episode: record, series: record, taggings: record, tags: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/seasons/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of series
#
# GET /series
export def "series list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # The list of IDs to filter by. Repeat this parameter for each ID you want to include in the filter. The brackets *MUST* be percent-encoded, per the requirements in [RFC 3986 § 3.4](https://tools.ietf.org/html/rfc3986#section-3.4).
  --page-number: int # Select which page number to receive results for. Pages are numbered starting at 1.
  --page-size: int # Indicate how many records to return per page. The maximum is 100.
  --ad-rep-account-id: string # Limit the result to series with an ad deal of this Ad Ops profile. (format: uuid, e.g. 35eb02fc-54db-4650-98e0-4695b101b71d)
  --network-id: string # Limit the result to series owned by this network. (format: uuid, e.g. 5317358a-527e-4365-a343-361854286cc7)
  --q: string # Limit the result to series with a title or slug containing this parameter in a case-insensitive way.
  --qp-sort: list<string> # Specify how to sort the result. Please refer to either the top section or the [JSON:API specification](https://jsonapi.org/format/#fetching-sorting) on how sorting works in general. (default: sort_title)
]: nothing -> record<data: table<attributes: record, id: string, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string, self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids[]" $ids "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "ad_rep_account_id" $ad_rep_account_id "scalar") (serialize-qp "network_id" $network_id "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/series" $qp $auth.query)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids[]": $ids, "page[number]": $page_number, "page[size]": $page_size, "ad_rep_account_id": $ad_rep_account_id, "network_id": $network_id, "q": $q, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a specific series
#
# GET /series/{id}
export def "series get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<amazon_subscription_url: string, castbox_subscription_url: string, cover_image_id: string, created_at: string, description: string, description_is_html: bool, description_plain: string, facebook_url: string, google_subscription_url: string, iheart_subscription_url: string, instagram_url: string, itunes_subscription_badge_enabled: bool, itunes_subscription_url: string, linkedin_url: string, pocket_casts_subscription_url: string, podcast_subscription_url: string, public_page_enabled: bool, public_title: string, radio_public_subscription_url: string, rss_author: string, rss_copyright: string, rss_email: string, rss_owner: string, slug: string, sort_title: string, spotify_subscription_badge_enabled: bool, spotify_subscription_url: string, status: string, stitcher_subscription_badge_enabled: bool, stitcher_subscription_url: string, title: string, tumblr_url: string, tune_in_subscription_url: string, twitter_url: string, type: string, updated_at: string, website_url: string>, id: string, relationships: record<classification_inclusions: record, cover_image: record, credits: record, episodes: record, images: record, network: record, seasons: record, taggings: record, tags: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}") $auth.query)
  let accept_val = "application/vnd.api+json"
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
  send-get $req $insecure $raw $allow_errors $full [200]
}
