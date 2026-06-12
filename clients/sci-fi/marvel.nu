# Auto-generated client for gateway.marvel.com vCable
# Source: https://gist.githubusercontent.com/wing328/30692487826e07962ae487dbb63a2fa1/raw/03e47f54adbef78800e128bb6b5e4c2aa9683972/marvel.openapi.v2.json
# Auth: --token flag or $env.GATEWAY_MARVEL_COM_TOKEN

const BASE_URL = "http://gateway.marvel.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GATEWAY_MARVEL_COM_TOKEN | default "" }
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

def base-url-completer [] { ["http://gateway.marvel.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "public-characters list" } } | get name | first)
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

# Fetches lists of characters.
#
# GET /v1/public/characters
# operationId: getCreatorCollection
export def "public-characters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return only characters matching the specified full character name (e.g. Spider-Man).
  --nameStartsWith: string # Return characters with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only characters which have been modified since the specified date. (format: date)
  --comics: list # Return only characters which appear in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only characters which appear the specified series (accepts a comma-separated list of ids).
  --events: list # Return only characters which appear in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only characters which appear the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public/characters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single character by id.
#
# GET /v1/public/characters/{characterId}
# operationId: getCharacterIndividual
export def "public-characters get" [
  characterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public/characters/($characterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of comics filtered by a character id.
#
# GET /v1/public/characters/{characterId}/comics
# operationId: getComicsCharacterCollection
export def "public-characters-comics get" [
  characterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Filter by the issue format (e.g. comic, digital comic, hardcover).
  --formatType: string # Filter by the issue format type (comic or collection).
  --noVariants: oneof<nothing, bool> # Exclude variant comics from the result set.
  --dateDescriptor: string # Return comics within a predefined date range.
  --dateRange: list # Return comics within a predefined date range.  Dates must be specified as date1,date2 (e.g. 2013-01-01,2013-01-02).  Dates are preferably formatted as YYYY-MM-DD but may be sent as any common date format.
  --title: string # Return only issues in series whose title matches the input.
  --titleStartsWith: string # Return only issues in series whose title starts with the input.
  --startYear: int # Return only issues in series whose start year matches the input. (format: int32)
  --issueNumber: int # Return only issues in series whose issue number matches the input. (format: int32)
  --diamondCode: string # Filter by diamond code.
  --digitalId: int # Filter by digital comic id. (format: int32)
  --upc: string # Filter by UPC.
  --isbn: string # Filter by ISBN.
  --ean: string # Filter by EAN.
  --issn: string # Filter by ISSN.
  --hasDigitalIssue: oneof<nothing, bool> # Include only results which are available digitally.
  --modifiedSince: string # Return only comics which have been modified since the specified date. (format: date)
  --creators: list # Return only comics which feature work by the specified creators (accepts a comma-separated list of ids).
  --series: list # Return only comics which are part of the specified series (accepts a comma-separated list of ids).
  --events: list # Return only comics which take place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only comics which contain the specified stories (accepts a comma-separated list of ids).
  --sharedAppearances: list # Return only comics in which the specified characters appear together (for example in which BOTH Spider-Man and Wolverine appear).
  --collaborators: list # Return only comics in which the specified creators worked together (for example in which BOTH Stan Lee and Jack Kirby did work).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "formatType" $formatType "scalar") (serialize-qp "noVariants" $noVariants "scalar") (serialize-qp "dateDescriptor" $dateDescriptor "scalar") (serialize-qp "dateRange" $dateRange "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "issueNumber" $issueNumber "scalar") (serialize-qp "diamondCode" $diamondCode "scalar") (serialize-qp "digitalId" $digitalId "scalar") (serialize-qp "upc" $upc "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "issn" $issn "scalar") (serialize-qp "hasDigitalIssue" $hasDigitalIssue "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "sharedAppearances" $sharedAppearances "csv") (serialize-qp "collaborators" $collaborators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/characters/($characterId)/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of events filtered by a character id.
#
# GET /v1/public/characters/{characterId}/events
# operationId: getCharacterEventsCollection
export def "public-characters-events get" [
  characterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter the event list by name.
  --nameStartsWith: string # Return events with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only events which have been modified since the specified date. (format: date)
  --creators: list # Return only events which feature work by the specified creators (accepts a comma-separated list of ids).
  --series: list # Return only events which are part of the specified series (accepts a comma-separated list of ids).
  --comics: list # Return only events which take place in the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only events which contain the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "series" $series "csv") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/characters/($characterId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of series filtered by a character id.
#
# GET /v1/public/characters/{characterId}/series
# operationId: getCharacterSeriesCollection
export def "public-characters-series get" [
  characterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Filter by series title.
  --titleStartsWith: string # Return series with titles that begin with the specified string (e.g. Sp).
  --startYear: int # Return only series matching the specified start year. (format: int32)
  --modifiedSince: string # Return only series which have been modified since the specified date. (format: date)
  --comics: list # Return only series which contain the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only series which contain the specified stories (accepts a comma-separated list of ids).
  --events: list # Return only series which have comics that take place during the specified events (accepts a comma-separated list of ids).
  --creators: list # Return only series which feature work by the specified creators (accepts a comma-separated list of ids).
  --seriesType: string # Filter the series by publication frequency type.
  --contains: list # Return only series containing one or more comics with the specified format.
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "events" $events "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "seriesType" $seriesType "scalar") (serialize-qp "contains" $contains "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/characters/($characterId)/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of stories filtered by a character id.
#
# GET /v1/public/characters/{characterId}/stories
# operationId: getCharacterStoryCollection
export def "public-characters-stories get" [
  characterId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Return only stories which have been modified since the specified date. (format: date)
  --comics: list # Return only stories contained in the specified (accepts a comma-separated list of ids).
  --series: list # Return only stories contained the specified series (accepts a comma-separated list of ids).
  --events: list # Return only stories which take place during the specified events (accepts a comma-separated list of ids).
  --creators: list # Return only stories which feature work by the specified creators (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/characters/($characterId)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of comics.
#
# GET /v1/public/comics
# operationId: getComicsCollection
export def "public-comics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Filter by the issue format (e.g. comic, digital comic, hardcover).
  --formatType: string # Filter by the issue format type (comic or collection).
  --noVariants: oneof<nothing, bool> # Exclude variants (alternate covers, secondary printings, director's cuts, etc.) from the result set.
  --dateDescriptor: string # Return comics within a predefined date range.
  --dateRange: list # Return comics within a predefined date range.  Dates must be specified as date1,date2 (e.g. 2013-01-01,2013-01-02).  Dates are preferably formatted as YYYY-MM-DD but may be sent as any common date format.
  --title: string # Return only issues in series whose title matches the input.
  --titleStartsWith: string # Return only issues in series whose title starts with the input.
  --startYear: int # Return only issues in series whose start year matches the input. (format: int32)
  --issueNumber: int # Return only issues in series whose issue number matches the input. (format: int32)
  --diamondCode: string # Filter by diamond code.
  --digitalId: int # Filter by digital comic id. (format: int32)
  --upc: string # Filter by UPC.
  --isbn: string # Filter by ISBN.
  --ean: string # Filter by EAN.
  --issn: string # Filter by ISSN.
  --hasDigitalIssue: oneof<nothing, bool> # Include only results which are available digitally.
  --modifiedSince: string # Return only comics which have been modified since the specified date. (format: date)
  --creators: list # Return only comics which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only comics which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only comics which are part of the specified series (accepts a comma-separated list of ids).
  --events: list # Return only comics which take place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only comics which contain the specified stories (accepts a comma-separated list of ids).
  --sharedAppearances: list # Return only comics in which the specified characters appear together (for example in which BOTH Spider-Man and Wolverine appear). Accepts a comma-separated list of ids.
  --collaborators: list # Return only comics in which the specified creators worked together (for example in which BOTH Stan Lee and Jack Kirby did work). Accepts a comma-separated list of ids.
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "formatType" $formatType "scalar") (serialize-qp "noVariants" $noVariants "scalar") (serialize-qp "dateDescriptor" $dateDescriptor "scalar") (serialize-qp "dateRange" $dateRange "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "issueNumber" $issueNumber "scalar") (serialize-qp "diamondCode" $diamondCode "scalar") (serialize-qp "digitalId" $digitalId "scalar") (serialize-qp "upc" $upc "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "issn" $issn "scalar") (serialize-qp "hasDigitalIssue" $hasDigitalIssue "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "sharedAppearances" $sharedAppearances "csv") (serialize-qp "collaborators" $collaborators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single comic by id.
#
# GET /v1/public/comics/{comicId}
# operationId: getComicIndividual
export def "public-comics get" [
  comicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public/comics/($comicId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of characters filtered by a comic id.
#
# GET /v1/public/comics/{comicId}/characters
# operationId: getComicCharacterCollection
export def "public-comics-characters get" [
  comicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return only characters matching the specified full character name (e.g. Spider-Man).
  --nameStartsWith: string # Return characters with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only characters which have been modified since the specified date. (format: date)
  --series: list # Return only characters which appear the specified series (accepts a comma-separated list of ids).
  --events: list # Return only characters which appear comics that took place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only characters which appear the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/comics/($comicId)/characters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of creators filtered by a comic id.
#
# GET /v1/public/comics/{comicId}/creators
# operationId: getCreatorCollection
export def "public-comics-creators get" [
  comicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string # Filter by creator first name (e.g. brian).
  --middleName: string # Filter by creator middle name (e.g. Michael).
  --lastName: string # Filter by creator last name (e.g. Bendis).
  --suffix: string # Filter by suffix or honorific (e.g. Jr., Sr.).
  --nameStartsWith: string # Filter by creator names that match critera (e.g. B, St L).
  --firstNameStartsWith: string # Filter by creator first names that match critera (e.g. B, St L).
  --middleNameStartsWith: string # Filter by creator middle names that match critera (e.g. Mi).
  --lastNameStartsWith: string # Filter by creator last names that match critera (e.g. Ben).
  --modifiedSince: string # Return only creators which have been modified since the specified date. (format: date)
  --comics: list # Return only creators who worked on in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only creators who worked on the specified series (accepts a comma-separated list of ids).
  --stories: list # Return only creators who worked on the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "suffix" $suffix "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "firstNameStartsWith" $firstNameStartsWith "scalar") (serialize-qp "middleNameStartsWith" $middleNameStartsWith "scalar") (serialize-qp "lastNameStartsWith" $lastNameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/comics/($comicId)/creators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of events filtered by a comic id.
#
# GET /v1/public/comics/{comicId}/events
# operationId: getIssueEventsCollection
export def "public-comics-events get" [
  comicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter the event list by name.
  --nameStartsWith: string # Return events with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only events which have been modified since the specified date. (format: date)
  --creators: list # Return only events which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only events which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only events which are part of the specified series (accepts a comma-separated list of ids).
  --stories: list # Return only events which contain the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/comics/($comicId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of stories filtered by a comic id.
#
# GET /v1/public/comics/{comicId}/stories
# operationId: getComicStoryCollection
export def "public-comics-stories get" [
  comicId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Return only stories which have been modified since the specified date. (format: date)
  --series: list # Return only stories contained the specified series (accepts a comma-separated list of ids).
  --events: list # Return only stories which take place during the specified events (accepts a comma-separated list of ids).
  --creators: list # Return only stories which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only stories which feature the specified characters (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/comics/($comicId)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of creators.
#
# GET /v1/public/creators
# operationId: getCreatorCollection
export def "public-creators list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string # Filter by creator first name (e.g. Brian).
  --middleName: string # Filter by creator middle name (e.g. Michael).
  --lastName: string # Filter by creator last name (e.g. Bendis).
  --suffix: string # Filter by suffix or honorific (e.g. Jr., Sr.).
  --nameStartsWith: string # Filter by creator names that match critera (e.g. B, St L).
  --firstNameStartsWith: string # Filter by creator first names that match critera (e.g. B, St L).
  --middleNameStartsWith: string # Filter by creator middle names that match critera (e.g. Mi).
  --lastNameStartsWith: string # Filter by creator last names that match critera (e.g. Ben).
  --modifiedSince: string # Return only creators which have been modified since the specified date. (format: date)
  --comics: list # Return only creators who worked on in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only creators who worked on the specified series (accepts a comma-separated list of ids).
  --events: list # Return only creators who worked on comics that took place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only creators who worked on the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "suffix" $suffix "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "firstNameStartsWith" $firstNameStartsWith "scalar") (serialize-qp "middleNameStartsWith" $middleNameStartsWith "scalar") (serialize-qp "lastNameStartsWith" $lastNameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public/creators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single creator by id.
#
# GET /v1/public/creators/{creatorId}
# operationId: getCreatorIndividual
export def "public-creators get" [
  creatorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public/creators/($creatorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of comics filtered by a creator id.
#
# GET /v1/public/creators/{creatorId}/comics
# operationId: getComicsCollection
export def "public-creators-comics get" [
  creatorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Filter by the issue format (e.g. comic, digital comic, hardcover).
  --formatType: string # Filter by the issue format type (comic or collection).
  --noVariants: oneof<nothing, bool> # Exclude variant comics from the result set.
  --dateDescriptor: string # Return comics within a predefined date range.
  --dateRange: list # Return comics within a predefined date range.  Dates must be specified as date1,date2 (e.g. 2013-01-01,2013-01-02).  Dates are preferably formatted as YYYY-MM-DD but may be sent as any common date format.
  --title: string # Return only issues in series whose title matches the input.
  --titleStartsWith: string # Return only issues in series whose title starts with the input.
  --startYear: int # Return only issues in series whose start year matches the input. (format: int32)
  --issueNumber: int # Return only issues in series whose issue number matches the input. (format: int32)
  --diamondCode: string # Filter by diamond code.
  --digitalId: int # Filter by digital comic id. (format: int32)
  --upc: string # Filter by UPC.
  --isbn: string # Filter by ISBN.
  --ean: string # Filter by EAN.
  --issn: string # Filter by ISSN.
  --hasDigitalIssue: list # Include only results which are available digitally.
  --modifiedSince: string # Return only comics which have been modified since the specified date. (format: date)
  --characters: list # Return only comics which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only comics which are part of the specified series (accepts a comma-separated list of ids).
  --events: list # Return only comics which take place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only comics which contain the specified stories (accepts a comma-separated list of ids).
  --sharedAppearances: list # Return only comics in which the specified characters appear together (for example in which BOTH Spider-Man and Wolverine appear).
  --collaborators: list # Return only comics in which the specified creators worked together (for example in which BOTH Stan Lee and Jack Kirby did work).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "formatType" $formatType "scalar") (serialize-qp "noVariants" $noVariants "scalar") (serialize-qp "dateDescriptor" $dateDescriptor "scalar") (serialize-qp "dateRange" $dateRange "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "issueNumber" $issueNumber "scalar") (serialize-qp "diamondCode" $diamondCode "scalar") (serialize-qp "digitalId" $digitalId "scalar") (serialize-qp "upc" $upc "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "issn" $issn "scalar") (serialize-qp "hasDigitalIssue" $hasDigitalIssue "csv") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "sharedAppearances" $sharedAppearances "csv") (serialize-qp "collaborators" $collaborators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/creators/($creatorId)/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of events filtered by a creator id.
#
# GET /v1/public/creators/{creatorId}/events
# operationId: getCreatorEventsCollection
export def "public-creators-events get" [
  creatorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter the event list by name.
  --nameStartsWith: string # Return events with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only events which have been modified since the specified date. (format: date)
  --characters: list # Return only events which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only events which are part of the specified series (accepts a comma-separated list of ids).
  --comics: list # Return only events which take place in the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only events which contain the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/creators/($creatorId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of series filtered by a creator id.
#
# GET /v1/public/creators/{creatorId}/series
# operationId: getCreatorSeriesCollection
export def "public-creators-series get" [
  creatorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Filter by series title.
  --titleStartsWith: string # Return series with titles that begin with the specified string (e.g. Sp).
  --startYear: int # Return only series matching the specified start year. (format: int32)
  --modifiedSince: string # Return only series which have been modified since the specified date. (format: date)
  --comics: list # Return only series which contain the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only series which contain the specified stories (accepts a comma-separated list of ids).
  --events: list # Return only series which have comics that take place during the specified events (accepts a comma-separated list of ids).
  --characters: list # Return only series which feature the specified characters (accepts a comma-separated list of ids).
  --seriesType: string # Filter the series by publication frequency type.
  --contains: list # Return only series containing one or more comics with the specified format.
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "events" $events "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "seriesType" $seriesType "scalar") (serialize-qp "contains" $contains "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/creators/($creatorId)/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of stories filtered by a creator id.
#
# GET /v1/public/creators/{creatorId}/stories
# operationId: getCreatorStoryCollection
export def "public-creators-stories get" [
  creatorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Return only stories which have been modified since the specified date. (format: date)
  --comics: list # Return only stories contained in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only stories contained the specified series (accepts a comma-separated list of ids).
  --events: list # Return only stories which take place during the specified events (accepts a comma-separated list of ids).
  --characters: list # Return only stories which feature the specified characters (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/creators/($creatorId)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of events.
#
# GET /v1/public/events
# operationId: getEventsCollection
export def "public-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return only events which match the specified name.
  --nameStartsWith: string # Return events with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only events which have been modified since the specified date. (format: date)
  --creators: list # Return only events which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only events which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only events which are part of the specified series (accepts a comma-separated list of ids).
  --comics: list # Return only events which take place in the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only events which take place in the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single event by id.
#
# GET /v1/public/events/{eventId}
# operationId: getEventIndividual
export def "public-events get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public/events/($eventId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of characters filtered by an event id.
#
# GET /v1/public/events/{eventId}/characters
# operationId: getEventCharacterCollection
export def "public-events-characters get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return only characters matching the specified full character name (e.g. Spider-Man).
  --nameStartsWith: string # Return characters with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only characters which have been modified since the specified date. (format: date)
  --comics: list # Return only characters which appear in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only characters which appear the specified series (accepts a comma-separated list of ids).
  --stories: list # Return only characters which appear the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/events/($eventId)/characters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of comics filtered by an event id.
#
# GET /v1/public/events/{eventId}/comics
# operationId: getComicsCollection
export def "public-events-comics get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Filter by the issue format (e.g. comic, digital comic, hardcover).
  --formatType: string # Filter by the issue format type (comic or collection).
  --noVariants: list # Exclude variant comics from the result set.
  --dateDescriptor: list # Return comics within a predefined date range.
  --dateRange: list # Return comics within a predefined date range.  Dates must be specified as date1,date2 (e.g. 2013-01-01,2013-01-02).  Dates are preferably formatted as YYYY-MM-DD but may be sent as any common date format.
  --title: string # Return only issues in series whose title matches the input.
  --titleStartsWith: string # Return only issues in series whose title starts with the input.
  --startYear: int # Return only issues in series whose start year matches the input. (format: int32)
  --issueNumber: int # Return only issues in series whose issue number matches the input. (format: int32)
  --diamondCode: string # Filter by diamond code.
  --digitalId: int # Filter by digital comic id. (format: int32)
  --upc: string # Filter by UPC.
  --isbn: string # Filter by ISBN.
  --ean: string # Filter by EAN.
  --issn: string # Filter by ISSN.
  --hasDigitalIssue: list # Include only results which are available digitally.
  --modifiedSince: string # Return only comics which have been modified since the specified date. (format: date)
  --creators: list # Return only comics which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only comics which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only comics which are part of the specified series (accepts a comma-separated list of ids).
  --events: list # Return only comics which take place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only comics which contain the specified stories (accepts a comma-separated list of ids).
  --sharedAppearances: list # Return only comics in which the specified characters appear together (for example in which BOTH Spider-Man and Wolverine appear).
  --collaborators: list # Return only comics in which the specified creators worked together (for example in which BOTH Stan Lee and Jack Kirby did work).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "formatType" $formatType "scalar") (serialize-qp "noVariants" $noVariants "csv") (serialize-qp "dateDescriptor" $dateDescriptor "csv") (serialize-qp "dateRange" $dateRange "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "issueNumber" $issueNumber "scalar") (serialize-qp "diamondCode" $diamondCode "scalar") (serialize-qp "digitalId" $digitalId "scalar") (serialize-qp "upc" $upc "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "issn" $issn "scalar") (serialize-qp "hasDigitalIssue" $hasDigitalIssue "csv") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "sharedAppearances" $sharedAppearances "csv") (serialize-qp "collaborators" $collaborators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/events/($eventId)/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of creators filtered by an event id.
#
# GET /v1/public/events/{eventId}/creators
# operationId: getCreatorCollection
export def "public-events-creators get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string # Filter by creator first name (e.g. brian).
  --middleName: string # Filter by creator middle name (e.g. Michael).
  --lastName: string # Filter by creator last name (e.g. Bendis).
  --suffix: string # Filter by suffix or honorific (e.g. Jr., Sr.).
  --nameStartsWith: string # Filter by creator names that match critera (e.g. B, St L).
  --firstNameStartsWith: string # Filter by creator first names that match critera (e.g. B, St L).
  --middleNameStartsWith: string # Filter by creator middle names that match critera (e.g. Mi).
  --lastNameStartsWith: string # Filter by creator last names that match critera (e.g. Ben).
  --modifiedSince: string # Return only creators which have been modified since the specified date. (format: date)
  --comics: list # Return only creators who worked on in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only creators who worked on the specified series (accepts a comma-separated list of ids).
  --stories: list # Return only creators who worked on the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "suffix" $suffix "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "firstNameStartsWith" $firstNameStartsWith "scalar") (serialize-qp "middleNameStartsWith" $middleNameStartsWith "scalar") (serialize-qp "lastNameStartsWith" $lastNameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/events/($eventId)/creators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of series filtered by an event id.
#
# GET /v1/public/events/{eventId}/series
# operationId: getEventSeriesCollection
export def "public-events-series get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Filter by series title.
  --titleStartsWith: string # Return series with titles that begin with the specified string (e.g. Sp).
  --startYear: int # Return only series matching the specified start year. (format: int32)
  --modifiedSince: string # Return only series which have been modified since the specified date. (format: date)
  --comics: list # Return only series which contain the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only series which contain the specified stories (accepts a comma-separated list of ids).
  --creators: list # Return only series which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only series which feature the specified characters (accepts a comma-separated list of ids).
  --seriesType: string # Filter the series by publication frequency type.
  --contains: list # Return only series containing one or more comics with the specified format.
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "seriesType" $seriesType "scalar") (serialize-qp "contains" $contains "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/events/($eventId)/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of stories filtered by an event id.
#
# GET /v1/public/events/{eventId}/stories
# operationId: getEventStoryCollection
export def "public-events-stories get" [
  eventId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Return only stories which have been modified since the specified date. (format: date)
  --comics: list # Return only stories contained in the specified (accepts a comma-separated list of ids).
  --series: list # Return only stories contained the specified series (accepts a comma-separated list of ids).
  --creators: list # Return only stories which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only stories which feature the specified characters (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/events/($eventId)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of series.
#
# GET /v1/public/series
# operationId: getSeriesCollection
export def "public-series list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Return only series matching the specified title.
  --titleStartsWith: string # Return series with titles that begin with the specified string (e.g. Sp).
  --startYear: int # Return only series matching the specified start year. (format: int32)
  --modifiedSince: string # Return only series which have been modified since the specified date. (format: date)
  --comics: list # Return only series which contain the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only series which contain the specified stories (accepts a comma-separated list of ids).
  --events: list # Return only series which have comics that take place during the specified events (accepts a comma-separated list of ids).
  --creators: list # Return only series which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only series which feature the specified characters (accepts a comma-separated list of ids).
  --seriesType: string # Filter the series by publication frequency type.
  --contains: list # Return only series containing one or more comics with the specified format.
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "events" $events "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "seriesType" $seriesType "scalar") (serialize-qp "contains" $contains "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single comic series by id.
#
# GET /v1/public/series/{seriesId}
# operationId: getSeriesIndividual
export def "public-series get" [
  seriesId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public/series/($seriesId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of characters filtered by a series id.
#
# GET /v1/public/series/{seriesId}/characters
# operationId: getSeriesCharacterWrapper
export def "public-series-characters get" [
  seriesId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return only characters matching the specified full character name (e.g. Spider-Man).
  --nameStartsWith: string # Return characters with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only characters which have been modified since the specified date. (format: date)
  --comics: list # Return only characters which appear in the specified comics (accepts a comma-separated list of ids).
  --events: list # Return only characters which appear comics that took place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only characters which appear the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/series/($seriesId)/characters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of comics filtered by a series id.
#
# GET /v1/public/series/{seriesId}/comics
# operationId: getComicsCollection
export def "public-series-comics get" [
  seriesId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Filter by the issue format (e.g. comic, digital comic, hardcover).
  --formatType: string # Filter by the issue format type (comic or collection).
  --noVariants: list # Exclude variant comics from the result set.
  --dateDescriptor: list # Return comics within a predefined date range.
  --dateRange: list # Return comics within a predefined date range.  Dates must be specified as date1,date2 (e.g. 2013-01-01,2013-01-02).  Dates are preferably formatted as YYYY-MM-DD but may be sent as any common date format.
  --title: string # Return only issues in series whose title matches the input.
  --titleStartsWith: string # Return only issues in series whose title starts with the input.
  --startYear: int # Return only issues in series whose start year matches the input. (format: int32)
  --issueNumber: int # Return only issues in series whose issue number matches the input. (format: int32)
  --diamondCode: string # Filter by diamond code.
  --digitalId: int # Filter by digital comic id. (format: int32)
  --upc: string # Filter by UPC.
  --isbn: string # Filter by ISBN.
  --ean: string # Filter by EAN.
  --issn: string # Filter by ISSN.
  --hasDigitalIssue: list # Include only results which are available digitally.
  --modifiedSince: string # Return only comics which have been modified since the specified date. (format: date)
  --creators: list # Return only comics which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only comics which feature the specified characters (accepts a comma-separated list of ids).
  --events: list # Return only comics which take place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only comics which contain the specified stories (accepts a comma-separated list of ids).
  --sharedAppearances: list # Return only comics in which the specified characters appear together (for example in which BOTH Spider-Man and Wolverine appear).
  --collaborators: list # Return only comics in which the specified creators worked together (for example in which BOTH Stan Lee and Jack Kirby did work).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "formatType" $formatType "scalar") (serialize-qp "noVariants" $noVariants "csv") (serialize-qp "dateDescriptor" $dateDescriptor "csv") (serialize-qp "dateRange" $dateRange "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "issueNumber" $issueNumber "scalar") (serialize-qp "diamondCode" $diamondCode "scalar") (serialize-qp "digitalId" $digitalId "scalar") (serialize-qp "upc" $upc "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "issn" $issn "scalar") (serialize-qp "hasDigitalIssue" $hasDigitalIssue "csv") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "sharedAppearances" $sharedAppearances "csv") (serialize-qp "collaborators" $collaborators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/series/($seriesId)/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of creators filtered by a series id.
#
# GET /v1/public/series/{seriesId}/creators
# operationId: getCreatorCollection
export def "public-series-creators get" [
  seriesId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string # Filter by creator first name (e.g. brian).
  --middleName: string # Filter by creator middle name (e.g. Michael).
  --lastName: string # Filter by creator last name (e.g. Bendis).
  --suffix: string # Filter by suffix or honorific (e.g. Jr., Sr.).
  --nameStartsWith: string # Filter by creator names that match critera (e.g. B, St L).
  --firstNameStartsWith: string # Filter by creator first names that match critera (e.g. B, St L).
  --middleNameStartsWith: string # Filter by creator middle names that match critera (e.g. Mi).
  --lastNameStartsWith: string # Filter by creator last names that match critera (e.g. Ben).
  --modifiedSince: string # Return only creators which have been modified since the specified date. (format: date)
  --comics: list # Return only creators who worked on in the specified comics (accepts a comma-separated list of ids).
  --events: list # Return only creators who worked on comics that took place in the specified events (accepts a comma-separated list of ids).
  --stories: list # Return only creators who worked on the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "suffix" $suffix "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "firstNameStartsWith" $firstNameStartsWith "scalar") (serialize-qp "middleNameStartsWith" $middleNameStartsWith "scalar") (serialize-qp "lastNameStartsWith" $lastNameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "events" $events "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/series/($seriesId)/creators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of events filtered by a series id.
#
# GET /v1/public/series/{seriesId}/events
# operationId: getEventsCollection
export def "public-series-events get" [
  seriesId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter the event list by name.
  --nameStartsWith: string # Return events with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only events which have been modified since the specified date. (format: date)
  --creators: list # Return only events which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only events which feature the specified characters (accepts a comma-separated list of ids).
  --comics: list # Return only events which take place in the specified comics (accepts a comma-separated list of ids).
  --stories: list # Return only events which contain the specified stories (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "comics" $comics "csv") (serialize-qp "stories" $stories "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/series/($seriesId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of stories filtered by a series id.
#
# GET /v1/public/series/{seriesId}/stories
# operationId: getSeriesStoryCollection
export def "public-series-stories get" [
  seriesId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Return only stories which have been modified since the specified date. (format: date)
  --comics: list # Return only stories contained in the specified (accepts a comma-separated list of ids).
  --events: list # Return only stories which take place during the specified events (accepts a comma-separated list of ids).
  --creators: list # Return only stories which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only stories which feature the specified characters (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "events" $events "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/series/($seriesId)/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of stories.
#
# GET /v1/public/stories
# operationId: getStoryCollection
export def "public-stories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Return only stories which have been modified since the specified date. (format: date)
  --comics: list # Return only stories contained in the specified (accepts a comma-separated list of ids).
  --series: list # Return only stories contained the specified series (accepts a comma-separated list of ids).
  --events: list # Return only stories which take place during the specified events (accepts a comma-separated list of ids).
  --creators: list # Return only stories which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only stories which feature the specified characters (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/public/stories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a single comic story by id.
#
# GET /v1/public/stories/{storyId}
# operationId: getStoryIndividual
export def "public-stories get" [
  storyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/public/stories/($storyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of characters filtered by a story id.
#
# GET /v1/public/stories/{storyId}/characters
# operationId: getCreatorCollection
export def "public-stories-characters get" [
  storyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Return only characters matching the specified full character name (e.g. Spider-Man).
  --nameStartsWith: string # Return characters with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only characters which have been modified since the specified date. (format: date)
  --comics: list # Return only characters which appear in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only characters which appear the specified series (accepts a comma-separated list of ids).
  --events: list # Return only characters which appear comics that took place in the specified events (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/stories/($storyId)/characters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of comics filtered by a story id.
#
# GET /v1/public/stories/{storyId}/comics
# operationId: getComicsCollection
export def "public-stories-comics get" [
  storyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Filter by the issue format (e.g. comic, digital comic, hardcover).
  --formatType: string # Filter by the issue format type (comic or collection).
  --noVariants: list # Exclude variant comics from the result set.
  --dateDescriptor: list # Return comics within a predefined date range.
  --dateRange: list # Return comics within a predefined date range.  Dates must be specified as date1,date2 (e.g. 2013-01-01,2013-01-02).  Dates are preferably formatted as YYYY-MM-DD but may be sent as any common date format.
  --title: string # Return only issues in series whose title matches the input.
  --titleStartsWith: string # Return only issues in series whose title starts with the input.
  --startYear: int # Return only issues in series whose start year matches the input. (format: int32)
  --issueNumber: int # Return only issues in series whose issue number matches the input. (format: int32)
  --diamondCode: string # Filter by diamond code.
  --digitalId: int # Filter by digital comic id. (format: int32)
  --upc: string # Filter by UPC.
  --isbn: string # Filter by ISBN.
  --ean: string # Filter by EAN.
  --issn: string # Filter by ISSN.
  --hasDigitalIssue: list # Include only results which are available digitally.
  --modifiedSince: string # Return only comics which have been modified since the specified date. (format: date)
  --creators: list # Return only comics which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only comics which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only comics which are part of the specified series (accepts a comma-separated list of ids).
  --events: list # Return only comics which take place in the specified events (accepts a comma-separated list of ids).
  --sharedAppearances: list # Return only comics in which the specified characters appear together (for example in which BOTH Spider-Man and Wolverine appear).
  --collaborators: list # Return only comics in which the specified creators worked together (for example in which BOTH Stan Lee and Jack Kirby did work).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "formatType" $formatType "scalar") (serialize-qp "noVariants" $noVariants "csv") (serialize-qp "dateDescriptor" $dateDescriptor "csv") (serialize-qp "dateRange" $dateRange "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "issueNumber" $issueNumber "scalar") (serialize-qp "diamondCode" $diamondCode "scalar") (serialize-qp "digitalId" $digitalId "scalar") (serialize-qp "upc" $upc "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "issn" $issn "scalar") (serialize-qp "hasDigitalIssue" $hasDigitalIssue "csv") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "sharedAppearances" $sharedAppearances "csv") (serialize-qp "collaborators" $collaborators "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/stories/($storyId)/comics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of creators filtered by a story id.
#
# GET /v1/public/stories/{storyId}/creators
# operationId: getCreatorCollection
export def "public-stories-creators get" [
  storyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string # Filter by creator first name (e.g. brian).
  --middleName: string # Filter by creator middle name (e.g. Michael).
  --lastName: string # Filter by creator last name (e.g. Bendis).
  --suffix: string # Filter by suffix or honorific (e.g. Jr., Sr.).
  --nameStartsWith: string # Filter by creator names that match critera (e.g. B, St L).
  --firstNameStartsWith: string # Filter by creator first names that match critera (e.g. B, St L).
  --middleNameStartsWith: string # Filter by creator middle names that match critera (e.g. Mi).
  --lastNameStartsWith: string # Filter by creator last names that match critera (e.g. Ben).
  --modifiedSince: string # Return only creators which have been modified since the specified date. (format: date)
  --comics: list # Return only creators who worked on in the specified comics (accepts a comma-separated list of ids).
  --series: list # Return only creators who worked on the specified series (accepts a comma-separated list of ids).
  --events: list # Return only creators who worked on comics that took place in the specified events (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "middleName" $middleName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "suffix" $suffix "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "firstNameStartsWith" $firstNameStartsWith "scalar") (serialize-qp "middleNameStartsWith" $middleNameStartsWith "scalar") (serialize-qp "lastNameStartsWith" $lastNameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "series" $series "csv") (serialize-qp "events" $events "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/stories/($storyId)/creators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of events filtered by a story id.
#
# GET /v1/public/stories/{storyId}/events
# operationId: getEventsCollection
export def "public-stories-events get" [
  storyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter the event list by name.
  --nameStartsWith: string # Return events with names that begin with the specified string (e.g. Sp).
  --modifiedSince: string # Return only events which have been modified since the specified date. (format: date)
  --creators: list # Return only events which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only events which feature the specified characters (accepts a comma-separated list of ids).
  --series: list # Return only events which are part of the specified series (accepts a comma-separated list of ids).
  --comics: list # Return only events which take place in the specified comics (accepts a comma-separated list of ids).
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "nameStartsWith" $nameStartsWith "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "series" $series "csv") (serialize-qp "comics" $comics "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/stories/($storyId)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches lists of series filtered by a story id.
#
# GET /v1/public/stories/{storyId}/series
# operationId: getStorySeriesCollection
export def "public-stories-series get" [
  storyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list # Return only series which have comics that take place during the specified events (accepts a comma-separated list of ids).
  --title: string # Filter by series title.
  --titleStartsWith: string # Return series with titles that begin with the specified string (e.g. Sp).
  --startYear: int # Return only series matching the specified start year. (format: int32)
  --modifiedSince: string # Return only series which have been modified since the specified date. (format: date)
  --comics: list # Return only series which contain the specified comics (accepts a comma-separated list of ids).
  --creators: list # Return only series which feature work by the specified creators (accepts a comma-separated list of ids).
  --characters: list # Return only series which feature the specified characters (accepts a comma-separated list of ids).
  --seriesType: string # Filter the series by publication frequency type.
  --contains: list # Return only series containing one or more comics with the specified format.
  --orderBy: list # Order the result set by a field or fields. Add a "-" to the value sort in descending order. Multiple values are given priority in the order in which they are passed.
  --limit: int # Limit the result set to the specified number of resources. (format: int32)
  --offset: int # Skip the specified number of resources in the result set. (format: int32)
]: nothing -> record<code: int, status: string, copyright: string, attributionText: string, attributionHTML: string, data: record<offset: int, limit: int, total: int, count: int, results: list<record>>, etag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "events" $events "csv") (serialize-qp "title" $title "scalar") (serialize-qp "titleStartsWith" $titleStartsWith "scalar") (serialize-qp "startYear" $startYear "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "comics" $comics "csv") (serialize-qp "creators" $creators "csv") (serialize-qp "characters" $characters "csv") (serialize-qp "seriesType" $seriesType "scalar") (serialize-qp "contains" $contains "csv") (serialize-qp "orderBy" $orderBy "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/public/stories/($storyId)/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
