# Auto-generated client for GeoDB Cities API v1.0.0
# Source: https://api.apis.guru/v2/specs/mashape.com/geodb/1.0.0/swagger.json
# Auth: --token flag or $env.GEODB_CITIES_API_TOKEN

const BASE_URL = "https://wft-geo-db.p.rapidapi.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEODB_CITIES_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-rapidapi-key" => { {scheme: $scheme, headers: {x-rapidapi-key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://wft-geo-db.p.rapidapi.com/v1"] }
def auth-scheme-completer [] { ["x-rapidapi-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "geo-admin-divisions find-using-get" } } | get name | first)
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

# Find administrative divisions
#
# GET /geo/adminDivisions
# operationId: findAdminDivisionsUsingGET
export def "geo-admin-divisions find-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string # Only places near this location. Latitude/longitude in ISO-6709 format: ±DD.DDDD±DDD.DDDD
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/adminDivisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"location": $location, "radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Get administrative division details
#
# GET /geo/adminDivisions/{divisionId}
# operationId: getAdminDivisionUsingGET
export def "geo-admin-divisions get-using" [
  division_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($division_id | is-empty) { error make --unspanned { msg: "path parameter 'divisionId' must be non-empty" } }
  let qp = [(serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "languageCode" $language_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({division_id: (encode-path-segment $division_id)} | format pattern "/geo/adminDivisions/{division_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"asciiMode": $ascii_mode, "languageCode": $language_code} | compact), body: null}
}

# Find cities near division
#
# GET /geo/adminDivisions/{divisionId}/nearbyCities
# operationId: findCitiesNearAdminDivisionUsingGET
export def "geo-admin-divisions-nearby-cities find-near-using-get" [
  division_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($division_id | is-empty) { error make --unspanned { msg: "path parameter 'divisionId' must be non-empty" } }
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({division_id: (encode-path-segment $division_id)} | format pattern "/geo/adminDivisions/{division_id}/nearbyCities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "types": $types, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Find divisions near division
#
# GET /geo/adminDivisions/{divisionId}/nearbyDivisions
# operationId: findDivisionsNearAdminDivisionUsingGET
export def "geo-admin-divisions-nearby-divisions find-near-using-get" [
  division_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($division_id | is-empty) { error make --unspanned { msg: "path parameter 'divisionId' must be non-empty" } }
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({division_id: (encode-path-segment $division_id)} | format pattern "/geo/adminDivisions/{division_id}/nearbyDivisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Find cities
#
# GET /geo/cities
# operationId: findCitiesUsingGET
export def "geo-cities find-using-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: string # Only places near this location. Latitude/longitude in ISO-6709 format: ±DD.DDDD±DDD.DDDD
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/cities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"location": $location, "radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "types": $types, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Get city details
#
# GET /geo/cities/{cityId}
# operationId: getCityUsingGET
export def "geo-cities get-city-using" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'cityId' must be non-empty" } }
  let qp = [(serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "languageCode" $language_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/geo/cities/{city_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"asciiMode": $ascii_mode, "languageCode": $language_code} | compact), body: null}
}

# Get city date-time
#
# GET /geo/cities/{cityId}/dateTime
# operationId: getCityDateTimeUsingGET
export def "geo-cities-date-time get-city-using" [
  city_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'cityId' must be non-empty" } }
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/geo/cities/{city_id}/dateTime"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get city distance
#
# GET /geo/cities/{cityId}/distance
# operationId: getCityDistanceUsingGET
export def "geo-cities-distance get-city-using" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --to-city-id: string # Distance to this city
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'cityId' must be non-empty" } }
  let qp = [(serialize-qp "toCityId" $to_city_id "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/geo/cities/{city_id}/distance") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"toCityId": $to_city_id, "distanceUnit": $distance_unit} | compact), body: null}
}

# Get city admin region
#
# GET /geo/cities/{cityId}/locatedIn
# operationId: getCityLocatedInUsingGET
export def "geo-cities-located-in get-city-using" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'cityId' must be non-empty" } }
  let qp = [(serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "languageCode" $language_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/geo/cities/{city_id}/locatedIn") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"asciiMode": $ascii_mode, "languageCode": $language_code} | compact), body: null}
}

# Find cities near city
#
# GET /geo/cities/{cityId}/nearbyCities
# operationId: findCitiesNearCityUsingGET
export def "geo-cities-nearby-cities find-near-city-using-get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'cityId' must be non-empty" } }
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/geo/cities/{city_id}/nearbyCities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "types": $types, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Get city time
#
# GET /geo/cities/{cityId}/time
# operationId: getCityTimeUsingGET
export def "geo-cities-time get-city-using" [
  city_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'cityId' must be non-empty" } }
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/geo/cities/{city_id}/time"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find countries
#
# GET /geo/countries
# operationId: getCountriesUsingGET
export def "geo-countries get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: string # Only countries supporting this currency
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort countries. Format: ±SORT_FIELD where SORT_FIELD = code | name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currencyCode" $currency_code "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currencyCode": $currency_code, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort} | compact), body: null}
}

# Get country details
#
# GET /geo/countries/{countryId}
# operationId: getCountryUsingGET
export def "geo-countries get-country-using" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'countryId' must be non-empty" } }
  let qp = [(serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "languageCode" $language_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id)} | format pattern "/geo/countries/{country_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"asciiMode": $ascii_mode, "languageCode": $language_code} | compact), body: null}
}

# Find country regions
#
# GET /geo/countries/{countryId}/regions
# operationId: getRegionsUsingGET
export def "geo-countries-regions list" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort regions. Format: ±SORT_FIELD where SORT_FIELD = fipsCode | isoCode | name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'countryId' must be non-empty" } }
  let qp = [(serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id)} | format pattern "/geo/countries/{country_id}/regions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort} | compact), body: null}
}

# Get region details
#
# GET /geo/countries/{countryId}/regions/{regionCode}
# operationId: getRegionUsingGET
export def "geo-countries-regions get-using" [
  country_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --language-code: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'countryId' must be non-empty" } }
  if ($region_code | is-empty) { error make --unspanned { msg: "path parameter 'regionCode' must be non-empty" } }
  let qp = [(serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "languageCode" $language_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id), region_code: (encode-path-segment $region_code)} | format pattern "/geo/countries/{country_id}/regions/{region_code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"asciiMode": $ascii_mode, "languageCode": $language_code} | compact), body: null}
}

# Find country region administrative divisions
#
# GET /geo/countries/{countryId}/regions/{regionCode}/adminDivisions
# operationId: findRegionDivisionsUsingGET
export def "geo-countries-regions-admin-divisions find-using-get" [
  country_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort place results. 'Format: ±SORT_FIELD,±SORT_FIELD' where SORT_FIELD = elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'countryId' must be non-empty" } }
  if ($region_code | is-empty) { error make --unspanned { msg: "path parameter 'regionCode' must be non-empty" } }
  let qp = [(serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id), region_code: (encode-path-segment $region_code)} | format pattern "/geo/countries/{country_id}/regions/{region_code}/adminDivisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Find country region cities
#
# GET /geo/countries/{countryId}/regions/{regionCode}/cities
# operationId: findRegionCitiesUsingGET
export def "geo-countries-regions-cities find-using-get" [
  country_id: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort place results. 'Format: ±SORT_FIELD,±SORT_FIELD' where SORT_FIELD = elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'countryId' must be non-empty" } }
  if ($region_code | is-empty) { error make --unspanned { msg: "path parameter 'regionCode' must be non-empty" } }
  let qp = [(serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id), region_code: (encode-path-segment $region_code)} | format pattern "/geo/countries/{country_id}/regions/{region_code}/cities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "types": $types, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Find cities near location
#
# GET /geo/locations/{locationId}/nearbyCities
# operationId: findCitiesNearLocationUsingGET
export def "geo-locations-nearby-cities find-near-using-get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/geo/locations/{location_id}/nearbyCities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "types": $types, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Find divisions near location
#
# GET /geo/locations/{locationId}/nearbyDivisions
# operationId: findDivisionsNearLocationUsingGET
export def "geo-locations-nearby-divisions find-near-using-get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The location radius within which to find places (format: int32)
  --distance-unit: string # The unit of distance: MI | KM (default: MI)
  --country-ids: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excluded-country-ids: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --min-population: int # Only places having at least this population (format: int32)
  --max-population: int # Only places having no more than this population (format: int32)
  --name-prefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --name-prefix-default-lang-results: oneof<nothing, bool> # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set. (default: true)
  --time-zone-ids: string # Only places in these time-zones (comma-delimited)
  --ascii-mode: oneof<nothing, bool> # Display results using ASCII characters (default: false)
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --language-code: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places. Format: ±SORT_FIELD,±SORT_FIELD where SORT_FIELD = countryCode | elevation | name | population
  --include-deleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'locationId' must be non-empty" } }
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "countryIds" $country_ids "scalar") (serialize-qp "excludedCountryIds" $excluded_country_ids "scalar") (serialize-qp "minPopulation" $min_population "scalar") (serialize-qp "maxPopulation" $max_population "scalar") (serialize-qp "namePrefix" $name_prefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $name_prefix_default_lang_results "scalar") (serialize-qp "timeZoneIds" $time_zone_ids "scalar") (serialize-qp "asciiMode" $ascii_mode "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/geo/locations/{location_id}/nearbyDivisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"radius": $radius, "distanceUnit": $distance_unit, "countryIds": $country_ids, "excludedCountryIds": $excluded_country_ids, "minPopulation": $min_population, "maxPopulation": $max_population, "namePrefix": $name_prefix, "namePrefixDefaultLangResults": $name_prefix_default_lang_results, "timeZoneIds": $time_zone_ids, "asciiMode": $ascii_mode, "hateoasMode": $hateoas_mode, "languageCode": $language_code, "limit": $limit, "offset": $offset, "sort": $qp_sort, "includeDeleted": $include_deleted} | compact), body: null}
}

# Find currencies
#
# GET /locale/currencies
# operationId: getCurrenciesUsingGET
export def "locale-currencies get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # Currencies for this country id
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryId" $country_id "scalar") (serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/currencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"countryId": $country_id, "hateoasMode": $hateoas_mode, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Get languages
#
# GET /locale/languages
# operationId: getLanguagesUsingGET
export def "locale-languages get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/languages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hateoasMode": $hateoas_mode, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Get locales
#
# GET /locale/locales
# operationId: getLocalesUsingGET
export def "locale-locales get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/locales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hateoasMode": $hateoas_mode, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Get time-zones
#
# GET /locale/timezones
# operationId: getTimezonesUsingGET
export def "locale-timezones get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hateoas-mode: oneof<nothing, bool> # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hateoasMode" $hateoas_mode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/timezones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hateoasMode": $hateoas_mode, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Get time-zone
#
# GET /locale/timezones/{zoneId}
# operationId: getTimeZoneUsingGET
export def "locale-timezones get-time-zone-using" [
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zoneId' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/locale/timezones/{zone_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get time-zone date-time
#
# GET /locale/timezones/{zoneId}/dateTime
# operationId: getTimeZoneDateTimeUsingGET
export def "locale-timezones-date-time get-zone-using" [
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zoneId' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/locale/timezones/{zone_id}/dateTime"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get time-zone time
#
# GET /locale/timezones/{zoneId}/time
# operationId: getTimeZoneTimeUsingGET
export def "locale-timezones-time get-zone-using" [
  zone_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  if ($zone_id | is-empty) { error make --unspanned { msg: "path parameter 'zoneId' must be non-empty" } }
  let full_url = (build-url $base ({zone_id: (encode-path-segment $zone_id)} | format pattern "/locale/timezones/{zone_id}/time"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
