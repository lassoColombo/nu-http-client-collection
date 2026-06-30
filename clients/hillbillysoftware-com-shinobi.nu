# Auto-generated client for shinobiapi vv1
# Source: https://api.apis.guru/v2/specs/hillbillysoftware.com/shinobi/v1/swagger.json
# Auth: --token flag or $env.SHINOBIAPI_TOKEN

const BASE_URL = "https://api.hillbillysoftware.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SHINOBIAPI_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.hillbillysoftware.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actors-search get" } } | get name | first)
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

# Returns data on queried actor/actress. Result set limited to 5 records
#
# GET /Actors/Search/{accesstoken}/{Query}
# operationId: Actor_Get
export def "actors-search get" [
  accesstoken: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<Bio: string, BirthYear: string, DeathYear: string, Gender: string, Name: string, PopularityIndex: string, ProfileImage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accesstoken | is-empty) { error make --unspanned { msg: "path parameter 'accesstoken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let full_url = (build-url $base ({accesstoken: (encode-path-segment $accesstoken), query: (encode-path-segment $query)} | format pattern "/Actors/Search/{accesstoken}/{query}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Add new actor or actress to database
#
# POST /AddActor
# operationId: AddActor_Post
export def "add-actor create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access-token: string
  --bio: string
  --birth-year: string
  --death-year: string
  --gender: string
  --name: string
  --popularity-index: string
  --profile-image: string
]: any -> record<Status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AddActor" $auth.query)
  let req_body = {"AccessToken": $access_token, "Bio": $bio, "BirthYear": $birth_year, "DeathYear": $death_year, "Gender": $gender, "Name": $name, "PopularityIndex": $popularity_index, "ProfileImage": $profile_image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Add new show to database
#
# POST /AddTVShow
# operationId: AddTVShow_Post
export def "add-tv-show create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access-token: string
  --episode-count: string
  --episode-runtime: string
  --genres: string
  --imdb-id: string
  --premier-year: string
  --seasons: string
  --show-image: string
  --show-status: string
  --synopsis: string
  --title: string
]: any -> record<Status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AddTVShow" $auth.query)
  let req_body = {"AccessToken": $access_token, "EpisodeCount": $episode_count, "EpisodeRuntime": $episode_runtime, "Genres": $genres, "ImdbID": $imdb_id, "PremierYear": $premier_year, "Seasons": $seasons, "ShowImage": $show_image, "ShowStatus": $show_status, "Synopsis": $synopsis, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Get known aliases for Movies or Television shows from passed imdbID
#
# GET /Aliases/ByID/{AccessToken}/{imdbID}
# operationId: AliasesByID_Get
export def "aliases-by-id get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Aka: string, ExternalIDs: list<record>, Name: string, OriginalName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Aliases/ByID/{access_token}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get known aliases for Movies or Television shows
#
# GET /Aliases/ByName/{AccessToken}/{Title}
# operationId: Aliases_Get
export def "aliases-by-name get" [
  access_token: string
  title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Aka: string, ExternalIDs: list<record>, Name: string, OriginalName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($title | is-empty) { error make --unspanned { msg: "path parameter 'Title' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), title: (encode-path-segment $title)} | format pattern "/Aliases/ByName/{access_token}/{title}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all awards by nominiee
#
# GET /Awards/ByWinner/{AccessToken}/{Nominee}
# operationId: AwardsbyWinner_Get
export def "awards-by-winner get-awardsby" [
  access_token: string
  nominee: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Category: string, Nominee: string, Type: string, Winner: string, Year: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($nominee | is-empty) { error make --unspanned { msg: "path parameter 'Nominee' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), nominee: (encode-path-segment $nominee)} | format pattern "/Awards/ByWinner/{access_token}/{nominee}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all awards for requested year
#
# GET /Awards/ByYear/{Year}
# operationId: awards_Get
export def "awards-by-year get" [
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Category: string, Nominee: string, Type: string, Winner: string, Year: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'Year' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/Awards/ByYear/{year}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets TV Schedule for selected data
#
# GET /Calendar/ByDate/{AccessToken}/{Date}/{Country}
# operationId: ScheduleByDate_Get
export def "calendar-by-date get-schedule" [
  access_token: string
  date: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'Date' must be non-empty" } }
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'Country' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), date: (encode-path-segment $date), country: (encode-path-segment $country)} | format pattern "/Calendar/ByDate/{access_token}/{date}/{country}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns list of available countries in calendar database
#
# GET /Calendar/Countries/{AccessToken}
# operationId: CalendarCountries_Get
export def "calendar-countries get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token)} | format pattern "/Calendar/Countries/{access_token}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets a list of available networks
#
# GET /Calendar/Networks/{AccessToken}
# operationId: CalendarNetworks_Get
export def "calendar-networks get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Country: string, Network: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token)} | format pattern "/Calendar/Networks/{access_token}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns list of seasons available in the calendar for show
#
# GET /Calendar/Seasons/{AccessToken}/{Name}
# operationId: CalendarShowSeasons_Get
export def "calendar-seasons get-show" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Year: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Calendar/Seasons/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get Calendar by showname and season
#
# GET /Calendar/Show/Season/{AccessToken}/{Name}/{Season}
# operationId: CalendarbyShownameSeason_Get
export def "calendar-show-season get-calendarby-showname" [
  access_token: string
  name: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'Season' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name), season: (encode-path-segment $season)} | format pattern "/Calendar/Show/Season/{access_token}/{name}/{season}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Will return show schedule for queried showname and year
#
# GET /Calendar/Show/{AccessToken}/{Name}/{Year}
# operationId: CalendarByShowName_Get
export def "calendar-show get-by" [
  access_token: string
  name: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'Year' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name), year: (encode-path-segment $year)} | format pattern "/Calendar/Show/{access_token}/{name}/{year}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Will return show schedule for today for all countries in database
#
# GET /Calendar/Today/{AccessToken}
# operationId: CalendarToday_Get
export def "calendar-today get" [
  access_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AirDate: string, AirTime: string, Country: string, DaysOn: string, Episode: string, ID: string, Image: string, Network: string, PremiereDate: string, Runtime: string, Season: string, ShowName: string, Summary: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token)} | format pattern "/Calendar/Today/{access_token}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns all shows queried actor/actress is or has been in
#
# GET /Cast/ActorBySearch/{AccessToken}/{Actor}
# operationId: ActorInShows_Get
export def "cast-actor-by-search get-in-shows" [
  access_token: string
  actor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($actor | is-empty) { error make --unspanned { msg: "path parameter 'Actor' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), actor: (encode-path-segment $actor)} | format pattern "/Cast/ActorBySearch/{access_token}/{actor}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns list of show actor is appearing in
#
# GET /Cast/ByActor/{AccessToken}/{Actor}
# operationId: CastByActor_Get
export def "cast-by-actor get" [
  access_token: string
  actor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($actor | is-empty) { error make --unspanned { msg: "path parameter 'Actor' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), actor: (encode-path-segment $actor)} | format pattern "/Cast/ByActor/{access_token}/{actor}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns all actors in queried tvshow
#
# GET /Cast/ByTVShow/{accesstoken}/{ShowName}
# operationId: ActorsInTVShow_Get
export def "cast-by-tv-show get-actors-in" [
  accesstoken: string
  show_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, Role: string, ShowName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accesstoken | is-empty) { error make --unspanned { msg: "path parameter 'accesstoken' must be non-empty" } }
  if ($show_name | is-empty) { error make --unspanned { msg: "path parameter 'ShowName' must be non-empty" } }
  let full_url = (build-url $base ({accesstoken: (encode-path-segment $accesstoken), show_name: (encode-path-segment $show_name)} | format pattern "/Cast/ByTVShow/{accesstoken}/{show_name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get crew list by ID
#
# GET /Crew/ByID/{AccessToken}/{ID}
# operationId: CrewByID_Get
export def "crew-by-id get" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), id: (encode-path-segment $id)} | format pattern "/Crew/ByID/{access_token}/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of productions searched person is/was involved in.
#
# GET /Crew/ByPerson/{AccessToken}/{PersonName}
# operationId: CrewByPerson_Get
export def "crew-by-person get" [
  access_token: string
  person_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($person_name | is-empty) { error make --unspanned { msg: "path parameter 'PersonName' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), person_name: (encode-path-segment $person_name)} | format pattern "/Crew/ByPerson/{access_token}/{person_name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get crew list by showname
#
# GET /Crew/ByShowName/{AccessToken}/{ShowName}
# operationId: CrewbyShowname_Get
export def "crew-by-show-name get-crewby" [
  access_token: string
  show_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($show_name | is-empty) { error make --unspanned { msg: "path parameter 'ShowName' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), show_name: (encode-path-segment $show_name)} | format pattern "/Crew/ByShowName/{access_token}/{show_name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns crew for queried show.
#
# GET /Crew/Search/{AccessToken}/{Phrase}
# operationId: Crew_Get
export def "crew-search get" [
  access_token: string
  phrase: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, Image: string, Name: string, ShowName: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($phrase | is-empty) { error make --unspanned { msg: "path parameter 'Phrase' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), phrase: (encode-path-segment $phrase)} | format pattern "/Crew/Search/{access_token}/{phrase}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all episodes for selected ID
#
# GET /Episodes/ByID/{AccessToken}/{ID}
# operationId: EpisodesByID_Get
export def "episodes-by-id get" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), id: (encode-path-segment $id)} | format pattern "/Episodes/ByID/{access_token}/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of episodes for specified imdbID and Season number
#
# GET /Episodes/BySeason/{AccessToken}/{ID}/{Season}
# operationId: EpisodesBySeason_Get
export def "episodes-by-season get" [
  access_token: string
  id: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'Season' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), id: (encode-path-segment $id), season: (encode-path-segment $season)} | format pattern "/Episodes/BySeason/{access_token}/{id}/{season}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets all episodes for selected show
#
# GET /Episodes/ByShowName/{AccessToken}/{Showname}
# operationId: Episodes_Get
export def "episodes-by-show-name get" [
  access_token: string
  showname: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Airdate: string, Airtime: string, EpisodeNo: string, Externals: list<record>, Image: string, Season: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($showname | is-empty) { error make --unspanned { msg: "path parameter 'Showname' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), showname: (encode-path-segment $showname)} | format pattern "/Episodes/ByShowName/{access_token}/{showname}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets latest season number based on show name
#
# GET /Episodes/LatestSeason/Show/{AccessToken}/{Name}
# operationId: EpisodesLastAvailableSeasonbyName_Get
export def "episodes-latest-season-show get-last-available-seasonby" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Season: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Episodes/LatestSeason/Show/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns last available season number in database, based on passed imdbID
#
# GET /Episodes/LatestSeason/{AccessToken}/{ID}
# operationId: EpisodesLastAvailableSeason_Get
export def "episodes-latest-season get-last-available" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<Season: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), id: (encode-path-segment $id)} | format pattern "/Episodes/LatestSeason/{access_token}/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns number of available seasons and episodes
#
# GET /Episodes/SeasonCount/{AccessToken}/{ID}
# operationId: EpisodesSeasonCount_Get
export def "episodes-season-count get" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<Episodes: string, Externals: table<ID: string, Name: string>, Seasons: string, Showname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'ID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), id: (encode-path-segment $id)} | format pattern "/Episodes/SeasonCount/{access_token}/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets list of avaiable IMDB ids from Movies and TV Show databases, you can use those to query other end points that need ID's
#
# GET /GetIMDBid/ByID/{AccessToken}/{Query}
# operationId: GetIMDBid_GetAsync
export def "get-imd-bid-by-id get-async" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<ID: string, ShinobiID: string, Title: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), query: (encode-path-segment $query)} | format pattern "/GetIMDBid/ByID/{access_token}/{query}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get images available for movie/tv show with passed imdbID
#
# GET /Images/ByID/{AccessToken}/{imdbID}
# operationId: Images_Get
export def "images-by-id get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Backdrops: list<string>, Posters: list<string>, Type: string, imdbID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Images/ByID/{access_token}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get images available for movie/tv show with passed query
#
# GET /Images/Search/{Accesstoken}/{Query}
# operationId: ImageSearch_Get
export def "images-search get" [
  accesstoken: string
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
  --accept: string@accept-completer # Response content type
  --strictmatch: oneof<nothing, bool>
]: nothing -> table<Backdrops: list<string>, Posters: list<string>, Type: string, imdbID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accesstoken | is-empty) { error make --unspanned { msg: "path parameter 'Accesstoken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let qp = [(serialize-qp "Strictmatch" $strictmatch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({accesstoken: (encode-path-segment $accesstoken), query: (encode-path-segment $query)} | format pattern "/Images/Search/{accesstoken}/{query}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Strictmatch": $strictmatch} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets available magnet hashes on passed date (yyyy-mm-dd). Feature not available on free plan, please donate to be able to use this feature.
#
# GET /Magnets/ByDate/{AccessToken}/{Date}
# operationId: MagnetsByDate_GetAsync
export def "magnets-by-date get-async" [
  access_token: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'Date' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), date: (encode-path-segment $date)} | format pattern "/Magnets/ByDate/{access_token}/{date}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns list of magnet hashes for passed IMDBID. Feature not available on free plan, please donate to be able to use this feature.
#
# GET /Magnets/ByIMDB/{AccessToken}/{imdbID}
# operationId: MagnetsByimdbID_GetAsync
export def "magnets-by-imdb get-byimdb-async" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Magnets/ByIMDB/{access_token}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Try and find magnet links for queried movie. Feature not available on free plan, please donate to be able to use this feature
#
# GET /Magnets/Search/{AccessToken}/{Query}
# operationId: magnetsMovieByID_GetAsync
export def "magnets-search get-movie-by-async" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), query: (encode-path-segment $query)} | format pattern "/Magnets/Search/{access_token}/{query}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns results based on query, Feature not available on free plan, please donate to be able to use this feature.
#
# GET /Magnets/TVShow/{AccessToken}/{TVShow}
# operationId: TVShowsearch_Get
export def "magnets-tv-show get-showsearch" [
  access_token: string
  tv_show: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Externals: list<record>, FirstSeenDate: string, Hash: string, Image: string, Name: string, Peers: string, Seeds: string, Size: string, Title: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($tv_show | is-empty) { error make --unspanned { msg: "path parameter 'TVShow' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), tv_show: (encode-path-segment $tv_show)} | format pattern "/Magnets/TVShow/{access_token}/{tv_show}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# GET /Movie/ByID/{accesstoken}/{imdbID}
#
# operationId: MovieID_Get
export def "movie-by-id get" [
  accesstoken: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ID: string, ImdbID: string, ReleaseYear: string, Runtime: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accesstoken | is-empty) { error make --unspanned { msg: "path parameter 'accesstoken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({accesstoken: (encode-path-segment $accesstoken), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Movie/ByID/{accesstoken}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Searches for movies, result set limited to 5 records
#
# GET /Movie/Search/{AccessToken}/{Query}
# operationId: MovieSearch_GetAsync
export def "movie-search get-async" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<ID: string, ImdbID: string, ReleaseYear: string, Runtime: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), query: (encode-path-segment $query)} | format pattern "/Movie/Search/{access_token}/{query}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns Albumart for passed AlbumID
#
# GET /Music/Albums/Art/{AccessToken}/{AlbumID}
# operationId: musicAlbumArt_Get
export def "music-albums-art get" [
  access_token: string
  album_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AlbumID: string, Albumname: string, Art: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'AlbumID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), album_id: (encode-path-segment $album_id)} | format pattern "/Music/Albums/Art/{access_token}/{album_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets CD art for passed MusicBrainzID
#
# GET /Music/Albums/CoverArt/{AccessToken}/{MBID}
# operationId: musicCDCovers_Get
export def "music-albums-cover-art get-cd" [
  access_token: string
  mbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<CoverImage: string, CoverThumbMedium: string, CoverThumbSmall: string, CoverType: string, MusicBrainzID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($mbid | is-empty) { error make --unspanned { msg: "path parameter 'MBID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), mbid: (encode-path-segment $mbid)} | format pattern "/Music/Albums/CoverArt/{access_token}/{mbid}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get Artist / Band information on MusicBrainzID
#
# GET /Music/Albums/MusicBrainzID/{AccessToken}/{MBID}
# operationId: MusicByMusicBrainz_Get
export def "music-albums-music-brainz-id get-by" [
  access_token: string
  mbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, WebSite: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($mbid | is-empty) { error make --unspanned { msg: "path parameter 'MBID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), mbid: (encode-path-segment $mbid)} | format pattern "/Music/Albums/MusicBrainzID/{access_token}/{mbid}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get albums from passed ArtistID
#
# GET /Music/Albums/{AccessToken}/{ArtistID}
# operationId: musicAlbums_Get
export def "music-albums get" [
  access_token: string
  artist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AlbumArt: string, AlbumID: string, ArtistID: string, Bibliography: string, Label: string, Name: string, Releaseyear: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($artist_id | is-empty) { error make --unspanned { msg: "path parameter 'ArtistID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), artist_id: (encode-path-segment $artist_id)} | format pattern "/Music/Albums/{access_token}/{artist_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieves artist / band Banner and logo based on ArtistID
#
# GET /Music/Artist/Art/ID/{AccessToken}/{ArtistID}
# operationId: musicCoverArt_Get
export def "music-artist-art-id get-cover" [
  access_token: string
  artist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ArtistID: string, Banner: string, Logo: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($artist_id | is-empty) { error make --unspanned { msg: "path parameter 'ArtistID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), artist_id: (encode-path-segment $artist_id)} | format pattern "/Music/Artist/Art/ID/{access_token}/{artist_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Retrieves artist / band Banner and logo based on artist or bandname
#
# GET /Music/Artist/Art/Name/{AccessToken}/{Name}
# operationId: musicCoverArtByName_Get
export def "music-artist-art-name get-cover-by" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ArtistID: string, Banner: string, Logo: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Music/Artist/Art/Name/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Provides extended information, which includes all known albums and music videos of artist / band
#
# GET /Music/Artist/Extended/{AccessToken}/{Name}
# operationId: musicArtistExtended_Get
export def "music-artist-extended get" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Albums: list<record>, ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, Videos: list<record>, WebSite: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Music/Artist/Extended/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get information about passed band name or artist
#
# GET /Music/Artist/{AccessToken}/{Name}
# operationId: Music_Get
export def "music-artist get" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<ArtistID: string, Banner: string, Biography: string, DisbandedYear: string, FormationYear: string, Genre: string, Logo: string, Members: string, MusicBrainzID: string, Name: string, SocialMedia: string, WebSite: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Music/Artist/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns all lyrics for requested AlbumID
#
# GET /Music/Lyrics/AlbumID/{AccessToken}/{AlbumID}
# operationId: musicLyricsbyAlbumID_Get
export def "music-lyrics-album-id get-lyricsby" [
  access_token: string
  album_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AlbumID: string, Artist: string, Lyrics: string, Song: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'AlbumID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), album_id: (encode-path-segment $album_id)} | format pattern "/Music/Lyrics/AlbumID/{access_token}/{album_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get lyrics for band or artist (record set limited to 25)
#
# GET /Music/Lyrics/ByName/{AccessToken}/{Name}
# operationId: musicLyrics_Get
export def "music-lyrics-by-name get" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AlbumID: string, Artist: string, Lyrics: string, Song: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Music/Lyrics/ByName/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get lyrics on song title
#
# GET /Music/Lyrics/BySong/{AccessToken}/{Song}
# operationId: musicLyricsBySong_Get
export def "music-lyrics-by-song get" [
  access_token: string
  song: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AlbumID: string, Artist: string, Lyrics: string, Song: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($song | is-empty) { error make --unspanned { msg: "path parameter 'Song' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), song: (encode-path-segment $song)} | format pattern "/Music/Lyrics/BySong/{access_token}/{song}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get all tracks from requested album
#
# GET /Music/Tracks/{AccessToken}/{AlbumID}
# operationId: musicTracks_Get
export def "music-tracks get" [
  access_token: string
  album_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AlbumID: string, ArtistID: string, Length: string, TrackName: string, TrackNo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'AlbumID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), album_id: (encode-path-segment $album_id)} | format pattern "/Music/Tracks/{access_token}/{album_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Lists all videos available for this Artist / Band
#
# GET /Music/Videos/{AccessToken}/{ArtistID}
# operationId: MusiVideos_Get
export def "music-videos get-musi" [
  access_token: string
  artist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<AlbumID: string, ArtistID: string, Decription: string, Video: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($artist_id | is-empty) { error make --unspanned { msg: "path parameter 'ArtistID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), artist_id: (encode-path-segment $artist_id)} | format pattern "/Music/Videos/{access_token}/{artist_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns ratings from various resources(IMDB,Rotten Tomatoes, metaCritics, TVMaze etc) of passed IMDBid
#
# GET /Rating/ByID/{AccessToken}/{imdbID}
# operationId: Rating_Get
export def "rating-by-id get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<EpisoDate: string, IMDB: string, MetaCritics: string, Name: string, RottenTomatoes: string, RottenTomatoesAudienceScore: string, TVDB: string, TVMaze: string, Trakt: string, imdbID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Rating/ByID/{access_token}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# GET /Rating/ByName/{AccessToken}/{Name}
#
# operationId: RatingByName_Get
export def "rating-by-name get" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<EpisoDate: string, IMDB: string, MetaCritics: string, Name: string, RottenTomatoes: string, RottenTomatoesAudienceScore: string, TVDB: string, TVMaze: string, Trakt: string, imdbID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Rating/ByName/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns status of queried show (query can be IMDB, TVDB, or showname)
#
# GET /Status/{AccessToken}/{Query}
# operationId: ShowStatus_Get
export def "status get-show" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<Enddate: string, ID: string, Title: string, YearsOn: string, imdbID: string, status: string, tvdbID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), query: (encode-path-segment $query)} | format pattern "/Status/{access_token}/{query}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Returns TVShow information based on IMDBid
#
# GET /TV/ByID/{accesstoken}/{imdbID}
# operationId: TVShowID_Get
export def "tv-by-id get-show" [
  accesstoken: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # imdbID of show you want info on
]: nothing -> record<EpisodeCount: string, EpisodeRuntime: string, Externals: table<ID: string, Name: string>, ID: string, ReleaseYear: string, Seasons: string, ShowImage: string, ShowStatus: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($accesstoken | is-empty) { error make --unspanned { msg: "path parameter 'accesstoken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({accesstoken: (encode-path-segment $accesstoken), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/TV/ByID/{accesstoken}/{imdb_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns results based on query, result set limited to 5 records
#
# GET /TV/ByName/{AccessToken}/{Query}
# operationId: TVShowByName_Get
export def "tv-by-name get-show" [
  access_token: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<EpisodeCount: string, EpisodeRuntime: string, Externals: list<record>, ID: string, ReleaseYear: string, Seasons: string, ShowImage: string, ShowStatus: string, Synopsis: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'Query' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), query: (encode-path-segment $query)} | format pattern "/TV/ByName/{access_token}/{query}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get Trailers for passed imdbID
#
# GET /Trailers/ByID/{AccessToken}/{imdbID}
# operationId: TrailersbyID_Get
export def "trailers-by-id get-trailersby" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Episode: string, Key: string, MediaType: string, Season: string, Site: string, TrailerName: string, TrailerSize: string, TrailerType: string, YouTubeEmbeddedCode: string, YouTubeURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Trailers/ByID/{access_token}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get trailer count for passed ID
#
# GET /Trailers/CountByID/{AccessToken}/{imdbID}
# operationId: TrailerCountByID_Get
export def "trailers-count-by-id get" [
  access_token: string
  imdb_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($imdb_id | is-empty) { error make --unspanned { msg: "path parameter 'imdbID' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), imdb_id: (encode-path-segment $imdb_id)} | format pattern "/Trailers/CountByID/{access_token}/{imdb_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get trailer count for passed name (Movie title or TVShow name)
#
# GET /Trailers/CountByName/{AccessToken}/{Name}
# operationId: TrailerCountByName_Get
export def "trailers-count-by-name get" [
  access_token: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'Name' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), name: (encode-path-segment $name)} | format pattern "/Trailers/CountByName/{access_token}/{name}") $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Gets trailers by search phrase (limited to 10 records)
#
# GET /Trailers/Search/{AccessToken}/{Phrase}
# operationId: TrailerSearch_Get
export def "trailers-search get" [
  access_token: string
  phrase: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<Episode: string, Key: string, MediaType: string, Season: string, Site: string, TrailerName: string, TrailerSize: string, TrailerType: string, YouTubeEmbeddedCode: string, YouTubeURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($access_token | is-empty) { error make --unspanned { msg: "path parameter 'AccessToken' must be non-empty" } }
  if ($phrase | is-empty) { error make --unspanned { msg: "path parameter 'Phrase' must be non-empty" } }
  let full_url = (build-url $base ({access_token: (encode-path-segment $access_token), phrase: (encode-path-segment $phrase)} | format pattern "/Trailers/Search/{access_token}/{phrase}") $auth.query)
  let accept_val = ($accept | default "application/json")
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
