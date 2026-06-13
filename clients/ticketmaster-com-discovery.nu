# Auto-generated client for Discovery API vv2
# Source: https://api.apis.guru/v2/specs/ticketmaster.com/discovery/v2/openapi.json
# Auth: --token flag or $env.DISCOVERY_API_TOKEN

const BASE_URL = "http://localhost//www.ticketmaster.com/discovery/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISCOVERY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["http://localhost//www.ticketmaster.com/discovery/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def source-completer [] { [" frontgate" " tmr" " universe" "ticketmaster"] }
def includeTest-completer [] { [" no" " only" "yes"] }
def includeLicensedContent-completer [] { [" no" "yes"] }
def includeSpellcheck-completer [] { [" no" "yes"] }
def includeTBA-completer [] { [" no" " only" "yes"] }
def includeTBD-completer [] { [" no" " only" "yes"] }
def unit-completer [] { ["km" "miles"] }
def includeFuzzy-completer [] { [" no" "yes"] }
def accept-completer [] { ["application/hal+json; charset=utf-8" "application/json; charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "discovery-attractions find" } } | get name | first)
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

# Attraction Search
#
# GET /discovery/v2/attractions
# operationId: find
export def "discovery-attractions find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result. Allowable Values : 'name,asc', 'name,desc', 'relevance,asc', 'relevance,desc' (default: relevance,desc, e.g. )
  --classificationName: list # Filter attractions by classification name: name of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --classificationId: list # Filter attractions by classification id: id of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --includeTest: string@includeTest-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # Yes if you want to display licensed content (default: no, e.g. )
  --includeSpellcheck: string@includeSpellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "classificationName" $classificationName "multi") (serialize-qp "classificationId" $classificationId "multi") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $includeTest "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar") (serialize-qp "includeSpellcheck" $includeSpellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/attractions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Attraction Details
#
# GET /discovery/v2/attractions/{id}
# operationId: get
export def "discovery-attractions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/attractions/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Classification Search
#
# GET /discovery/v2/classifications
export def "discovery-classifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result (default: name,asc, e.g. )
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --includeTest: string@includeTest-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # Yes if you want to display licensed content (default: no, e.g. )
  --includeSpellcheck: string@includeSpellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $includeTest "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar") (serialize-qp "includeSpellcheck" $includeSpellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/classifications" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Genre Details
#
# GET /discovery/v2/classifications/genres/{id}
# operationId: getGenre
export def "discovery-classifications-genres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/classifications/genres/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Segment Details
#
# GET /discovery/v2/classifications/segments/{id}
# operationId: getSegment
export def "discovery-classifications-segments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/classifications/segments/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Sub-Genre Details
#
# GET /discovery/v2/classifications/subgenres/{id}
# operationId: getSubgenre
export def "discovery-classifications-subgenres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/classifications/subgenres/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Classification Details
#
# GET /discovery/v2/classifications/{id}
export def "discovery-classifications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/classifications/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Event Search
#
# GET /discovery/v2/events
export def "discovery-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result. Allowable values : 'name,asc', 'name,desc', 'date,asc', 'date,desc', 'relevance,asc', 'relevance,desc', 'distance,asc', 'name,date,asc', 'name,date,desc', 'date,name,asc', 'date,name,desc','onsaleStartDate,asc', 'id,asc' (default: relevance,desc, e.g. )
  --startDateTime: string # Filter events with a start date after this date (default: , e.g. )
  --endDateTime: string # Filter events with a start date before this date (default: , e.g. )
  --onsaleStartDateTime: string # Filter events with onsale start date after this date (default: , e.g. )
  --onsaleOnStartDate: string # Filter events with onsale start date on this date (default: , e.g. )
  --onsaleOnAfterStartDate: string # Filter events with onsale range within this date (default: , e.g. )
  --onsaleEndDateTime: string # Filter events with onsale end date before this date (default: , e.g. )
  --city: string # Filter events by city (default: , e.g. )
  --countryCode: string # Filter events by country code (default: , e.g. )
  --stateCode: string # Filter events by state code (default: , e.g. )
  --postalCode: string # Filter events by postal code / zipcode (default: , e.g. )
  --venueId: string # Filter events by venue id (default: , e.g. )
  --attractionId: string # Filter events by attraction id (default: , e.g. )
  --segmentId: string # Filter events by segment id (default: , e.g. )
  --segmentName: string # Filter events by segment name (default: , e.g. )
  --classificationName: list # Filter events by classification name: name of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --classificationId: list # Filter events by classification id: id of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --marketId: string # Filter events by market id (default: , e.g. )
  --promoterId: string # Filter events by promoter id (default: , e.g. )
  --dmaId: string # Filter events by dma id (default: , e.g. )
  --includeTBA: string@includeTBA-completer # True, to include events with date to be announce (TBA) (default: no if date parameter sent, yes otherwise, e.g. )
  --includeTBD: string@includeTBD-completer # True, to include event with a date to be defined (TBD) (default: no if date parameter sent, yes otherwise, e.g. )
  --clientVisibility: string # Filter events by clientName (default: , e.g. )
  --latlong: string # Filter events by latitude and longitude, this filter is deprecated and maybe removed in a future release, please use geoPoint instead (default: , e.g. 33.80003000,-117.88304300)
  --radius: string # Radius of the area in which we want to search for events. (default: 50, e.g. )
  --unit: string@unit-completer # Unit of the radius (default: miles, e.g. )
  --geoPoint: string # filter events by geoHash (default: , e.g. dr5rh)
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --includeTest: string@includeTest-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # Yes if you want to display licensed content (default: no, e.g. )
  --includeSpellcheck: string@includeSpellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "onsaleStartDateTime" $onsaleStartDateTime "scalar") (serialize-qp "onsaleOnStartDate" $onsaleOnStartDate "scalar") (serialize-qp "onsaleOnAfterStartDate" $onsaleOnAfterStartDate "scalar") (serialize-qp "onsaleEndDateTime" $onsaleEndDateTime "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "stateCode" $stateCode "scalar") (serialize-qp "postalCode" $postalCode "scalar") (serialize-qp "venueId" $venueId "scalar") (serialize-qp "attractionId" $attractionId "scalar") (serialize-qp "segmentId" $segmentId "scalar") (serialize-qp "segmentName" $segmentName "scalar") (serialize-qp "classificationName" $classificationName "multi") (serialize-qp "classificationId" $classificationId "multi") (serialize-qp "marketId" $marketId "scalar") (serialize-qp "promoterId" $promoterId "scalar") (serialize-qp "dmaId" $dmaId "scalar") (serialize-qp "includeTBA" $includeTBA "scalar") (serialize-qp "includeTBD" $includeTBD "scalar") (serialize-qp "clientVisibility" $clientVisibility "scalar") (serialize-qp "latlong" $latlong "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "geoPoint" $geoPoint "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $includeTest "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar") (serialize-qp "includeSpellcheck" $includeSpellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/events" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Event Details
#
# GET /discovery/v2/events/{id}
export def "discovery-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/events/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Event Images
#
# GET /discovery/v2/events/{id}/images
# operationId: getImages
export def "discovery-events-images get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/events/($id)/images" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find Suggest
#
# GET /discovery/v2/suggest
export def "discovery-suggest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --keyword: string # Keyword to search on (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --latlong: string # Filter events by latitude and longitude, this filter is deprecated and maybe removed in a future release, please use geoPoint instead (default: , e.g. 33.80003000,-117.88304300)
  --radius: string # Radius of the area in which we want to search for events. (default: 100, e.g. )
  --unit: string@unit-completer # Unit of the radius (default: miles, e.g. )
  --size: string # Size of every entity returned in the response (default: 5, e.g. )
  --includeFuzzy: string@includeFuzzy-completer # yes, to include fuzzy matches in the search. This has performance impact. (default: no, e.g. )
  --clientVisibility: string # Filter events to clientName (default: , e.g. )
  --countryCode: string # Filter suggestions by country code (default: , e.g. )
  --includeTBA: string@includeTBA-completer # True, to include events with date to be announce (TBA) (default: no if date parameter sent, yes otherwise, e.g. )
  --includeTBD: string@includeTBD-completer # True, to include event with a date to be defined (TBD) (default: no if date parameter sent, yes otherwise, e.g. )
  --segmentId: string # Filter suggestions by segment id (default: , e.g. )
  --geoPoint: string # filter events by geoHash (default: , e.g. dr5rh)
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # Yes if you want to display licensed content (default: no, e.g. )
  --includeSpellcheck: string@includeSpellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyword" $keyword "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "latlong" $latlong "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "includeFuzzy" $includeFuzzy "scalar") (serialize-qp "clientVisibility" $clientVisibility "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "includeTBA" $includeTBA "scalar") (serialize-qp "includeTBD" $includeTBD "scalar") (serialize-qp "segmentId" $segmentId "scalar") (serialize-qp "geoPoint" $geoPoint "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar") (serialize-qp "includeSpellcheck" $includeSpellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/suggest" $qp)
  let accept_val = ($accept | default "application/hal+json; charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Venue Search
#
# GET /discovery/v2/venues
export def "discovery-venues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result. Allowable Values: 'name,asc', 'name,desc', 'relevance,asc', 'relevance,desc', 'distance,asc', 'distance,desc' (default: relevance,desc, e.g. )
  --stateCode: string # Filter venues by state / province code (default: , e.g. )
  --countryCode: string # Filter venues by country code (default: , e.g. )
  --latlong: string # Filter events by latitude and longitude, this filter is deprecated and maybe removed in a future release, please use geoPoint instead (default: , e.g. 33.80003000,-117.88304300)
  --radius: string # Radius of the area in which we want to search for events. (default: 50, e.g. )
  --unit: string@unit-completer # Unit of the radius (default: miles, e.g. )
  --geoPoint: string # filter events by geoHash (default: , e.g. dr5rh)
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --includeTest: string@includeTest-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # Yes if you want to display licensed content (default: no, e.g. )
  --includeSpellcheck: string@includeSpellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "stateCode" $stateCode "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "latlong" $latlong "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "geoPoint" $geoPoint "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $includeTest "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar") (serialize-qp "includeSpellcheck" $includeSpellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/venues" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Venue Details
#
# GET /discovery/v2/venues/{id}
export def "discovery-venues get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*')  (default: en, e.g. en-us,en,fr)
  --includeLicensedContent: string@includeLicensedContent-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $includeLicensedContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/discovery/v2/venues/($id)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
