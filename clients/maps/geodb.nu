# Auto-generated client for GeoDB Cities API v1.0.0
# Source: https://api.apis.guru/v2/specs/mashape.com/geodb/1.0.0/swagger.json
# Auth: --token flag or $env.GEODB_CITIES_API_TOKEN

const BASE_URL = "https://wft-geo-db.p.rapidapi.com/v1"
const DEFAULT_AUTH = "x-rapidapi-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEODB_CITIES_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-rapidapi-key" => { {headers: {x-rapidapi-key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://wft-geo-db.p.rapidapi.com/v1"] }
def auth-scheme-completer [] { ["x-rapidapi-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "geo-admin-divisions findAdminDivisionsUsingGET" } } | get name | first)
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
export def "geo-admin-divisions findAdminDivisionsUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: string # Only places near this location. Latitude/longitude in ISO-6709 format: ±DD.DDDD±DDD.DDDD
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/adminDivisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get administrative division details
#
# GET /geo/adminDivisions/{divisionId}
# operationId: getAdminDivisionUsingGET
export def "geo-admin-divisions get" [
  divisionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --languageCode: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "languageCode" $languageCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/adminDivisions/($divisionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find cities near division
#
# GET /geo/adminDivisions/{divisionId}/nearbyCities
# operationId: findCitiesNearAdminDivisionUsingGET
export def "geo-admin-divisions-nearby-cities findCitiesNearAdminDivisionUsingGET" [
  divisionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/adminDivisions/($divisionId)/nearbyCities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find divisions near division
#
# GET /geo/adminDivisions/{divisionId}/nearbyDivisions
# operationId: findDivisionsNearAdminDivisionUsingGET
export def "geo-admin-divisions-nearby-divisions findDivisionsNearAdminDivisionUsingGET" [
  divisionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/adminDivisions/($divisionId)/nearbyDivisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find cities
#
# GET /geo/cities
# operationId: findCitiesUsingGET
export def "geo-cities findCitiesUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: string # Only places near this location. Latitude/longitude in ISO-6709 format: ±DD.DDDD±DDD.DDDD
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/cities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get city details
#
# GET /geo/cities/{cityId}
# operationId: getCityUsingGET
export def "geo-cities get" [
  cityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --languageCode: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "languageCode" $languageCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/cities/($cityId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get city date-time
#
# GET /geo/cities/{cityId}/dateTime
# operationId: getCityDateTimeUsingGET
export def "geo-cities-date-time get" [
  cityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/geo/cities/($cityId)/dateTime")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get city distance
#
# GET /geo/cities/{cityId}/distance
# operationId: getCityDistanceUsingGET
export def "geo-cities-distance get" [
  cityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --toCityId: string # Distance to this city
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "toCityId" $toCityId "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/cities/($cityId)/distance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get city admin region
#
# GET /geo/cities/{cityId}/locatedIn
# operationId: getCityLocatedInUsingGET
export def "geo-cities-located-in get" [
  cityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --languageCode: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "languageCode" $languageCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/cities/($cityId)/locatedIn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find cities near city
#
# GET /geo/cities/{cityId}/nearbyCities
# operationId: findCitiesNearCityUsingGET
export def "geo-cities-nearby-cities findCitiesNearCityUsingGET" [
  cityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/cities/($cityId)/nearbyCities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get city time
#
# GET /geo/cities/{cityId}/time
# operationId: getCityTimeUsingGET
export def "geo-cities-time get" [
  cityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/geo/cities/($cityId)/time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find countries
#
# GET /geo/countries
# operationId: getCountriesUsingGET
export def "geo-countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currencyCode: string # Only countries supporting this currency
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort countries.  Format: ±SORT_FIELD  where SORT_FIELD = code | name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currencyCode" $currencyCode "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get country details
#
# GET /geo/countries/{countryId}
# operationId: getCountryUsingGET
export def "geo-countries get" [
  countryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --languageCode: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "languageCode" $languageCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/countries/($countryId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find country regions
#
# GET /geo/countries/{countryId}/regions
# operationId: getRegionsUsingGET
export def "geo-countries-regions list" [
  countryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort regions.  Format: ±SORT_FIELD  where SORT_FIELD = fipsCode | isoCode | name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/countries/($countryId)/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get region details
#
# GET /geo/countries/{countryId}/regions/{regionCode}
# operationId: getRegionUsingGET
export def "geo-countries-regions get" [
  countryId: string
  regionCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --languageCode: string # Display results in this language
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "languageCode" $languageCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/countries/($countryId)/regions/($regionCode)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find country region administrative divisions
#
# GET /geo/countries/{countryId}/regions/{regionCode}/adminDivisions
# operationId: findRegionDivisionsUsingGET
export def "geo-countries-regions-admin-divisions findRegionDivisionsUsingGET" [
  countryId: string
  regionCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort place results.  'Format: ±SORT_FIELD,±SORT_FIELD'  where SORT_FIELD = elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/countries/($countryId)/regions/($regionCode)/adminDivisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find country region cities
#
# GET /geo/countries/{countryId}/regions/{regionCode}/cities
# operationId: findRegionCitiesUsingGET
export def "geo-countries-regions-cities findRegionCitiesUsingGET" [
  countryId: string
  regionCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort place results.  'Format: ±SORT_FIELD,±SORT_FIELD'  where SORT_FIELD = elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/countries/($countryId)/regions/($regionCode)/cities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find cities near location
#
# GET /geo/locations/{locationId}/nearbyCities
# operationId: findCitiesNearLocationUsingGET
export def "geo-locations-nearby-cities findCitiesNearLocationUsingGET" [
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --types: string # Only places for these types (comma-delimited): CITY | ADM2
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/locations/($locationId)/nearbyCities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find divisions near location
#
# GET /geo/locations/{locationId}/nearbyDivisions
# operationId: findDivisionsNearLocationUsingGET
export def "geo-locations-nearby-divisions findDivisionsNearLocationUsingGET" [
  locationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --radius: int # The location radius within which to find places (format: int32)
  --distanceUnit: string # The unit of distance: MI | KM (default: MI)
  --countryIds: string # Only places in these countries (comma-delimited country codes or WikiData ids)
  --excludedCountryIds: string # Only places NOT in these countries (comma-delimited country codes or WikiData ids)
  --minPopulation: int # Only places having at least this population (format: int32)
  --maxPopulation: int # Only places having no more than this population (format: int32)
  --namePrefix: string # Only entities whose names start with this prefix. If languageCode is set, the prefix will be matched on the name as it appears in that language.
  --namePrefixDefaultLangResults: string@bool-completer # When name-prefix matching, whether or not to match on names in the default language if a non-default languageCode is set.  (default: true)
  --timeZoneIds: string # Only places in these time-zones (comma-delimited)
  --asciiMode: string@bool-completer # Display results using ASCII characters (default: false)
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --languageCode: string # Display results in this language
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
  --qp-sort: string # How to sort places.  Format: ±SORT_FIELD,±SORT_FIELD  where SORT_FIELD = countryCode | elevation | name | population
  --includeDeleted: string # Whether to include any divisions marked deleted: ALL | SINCE_YESTERDAY | SINCE_LAST_WEEK | NONE (default: NONE)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "countryIds" $countryIds "scalar") (serialize-qp "excludedCountryIds" $excludedCountryIds "scalar") (serialize-qp "minPopulation" $minPopulation "scalar") (serialize-qp "maxPopulation" $maxPopulation "scalar") (serialize-qp "namePrefix" $namePrefix "scalar") (serialize-qp "namePrefixDefaultLangResults" $namePrefixDefaultLangResults "scalar") (serialize-qp "timeZoneIds" $timeZoneIds "scalar") (serialize-qp "asciiMode" $asciiMode "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "languageCode" $languageCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDeleted" $includeDeleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geo/locations/($locationId)/nearbyDivisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find currencies
#
# GET /locale/currencies
# operationId: getCurrenciesUsingGET
export def "locale-currencies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --countryId: string # Currencies for this country id
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryId" $countryId "scalar") (serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/currencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get languages
#
# GET /locale/languages
# operationId: getLanguagesUsingGET
export def "locale-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/languages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get locales
#
# GET /locale/locales
# operationId: getLocalesUsingGET
export def "locale-locales get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/locales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time-zones
#
# GET /locale/timezones
# operationId: getTimezonesUsingGET
export def "locale-timezones list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hateoasMode: string@bool-completer # Include HATEOAS-style links in results (default: true)
  --limit: int # The maximum number of results to retrieve (format: int32, default: 10)
  --offset: int # The zero-ary offset index into the results (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hateoasMode" $hateoasMode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/locale/timezones" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time-zone
#
# GET /locale/timezones/{zoneId}
# operationId: getTimeZoneUsingGET
export def "locale-timezones get" [
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/locale/timezones/($zoneId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time-zone date-time
#
# GET /locale/timezones/{zoneId}/dateTime
# operationId: getTimeZoneDateTimeUsingGET
export def "locale-timezones-date-time get" [
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/locale/timezones/($zoneId)/dateTime")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time-zone time
#
# GET /locale/timezones/{zoneId}/time
# operationId: getTimeZoneTimeUsingGET
export def "locale-timezones-time get" [
  zoneId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-rapidapi-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/locale/timezones/($zoneId)/time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
