# Auto-generated client for setlist.fm API v1.0
# Source: https://api.apis.guru/v2/specs/setlist.fm/1.0/swagger.json
# Auth: --token flag or $env.SETLIST_FM_API_TOKEN

const BASE_URL = "https://localhost/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SETLIST_FM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "1-0-artist get" } } | get name | first)
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

# .
#
# GET /1.0/artist/{mbid}
# operationId: resource__1.0_artist__mbid__getArtist_GET
export def "1-0-artist get" [
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
]: nothing -> record<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mbid | is-empty) { error make --unspanned { msg: "path parameter 'mbid' must be non-empty" } }
  let full_url = (build-url $base ({mbid: (encode-path-segment $mbid)} | format pattern "/1.0/artist/{mbid}") $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# .
#
# GET /1.0/artist/{mbid}/setlists
# operationId: resource__1.0_artist__mbid__setlists_getArtistSetlists_GET
export def "1-0-artist-setlists get" [
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
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mbid | is-empty) { error make --unspanned { msg: "path parameter 'mbid' must be non-empty" } }
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mbid: (encode-path-segment $mbid)} | format pattern "/1.0/artist/{mbid}/setlists") $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"p": $p} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a city by its unique geoId.
#
# GET /1.0/city/{geoId}
# operationId: resource__1.0_city__geoId__getCity_GET
export def "1-0-city get-geo" [
  geo_id: string
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
]: nothing -> record<coords: record<lat: float, long: float>, country: record<code: string, name: string>, id: string, name: string, state: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($geo_id | is-empty) { error make --unspanned { msg: "path parameter 'geoId' must be non-empty" } }
  let full_url = (build-url $base ({geo_id: (encode-path-segment $geo_id)} | format pattern "/1.0/city/{geo_id}") $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# Search for artists.
#
# GET /1.0/search/artists
# operationId: resource__1.0_search_artists_getArtists_GET
export def "1-0-search-artists get" [
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
  --artist-mbid: string # the artist's Musicbrainz Identifier (mbid)
  --artist-name: string # the artist's name
  --artist-tmid: int # the artist's Ticketmaster Identifier (tmid)
  --p: int # the number of the result page you'd like to have (default: 1)
  --qp-sort: string # the sort of the result, either sortName (default) or relevance (default: sortName)
]: nothing -> record<artist: table<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string>, itemsPerPage: float, page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artistMbid" $artist_mbid "scalar") (serialize-qp "artistName" $artist_name "scalar") (serialize-qp "artistTmid" $artist_tmid "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/artists" $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"artistMbid": $artist_mbid, "artistName": $artist_name, "artistTmid": $artist_tmid, "p": $p, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for a city.
#
# GET /1.0/search/cities
# operationId: resource__1.0_search_cities_getCities_GET
export def "1-0-search-cities get" [
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
  --country: string # the city's country
  --name: string # name of the city
  --p: int # the number of the result page you'd like to have (default: 1)
  --state: string # state the city lies in
  --state-code: string # state code the city lies in
]: nothing -> record<cities: table<coords: record, country: record, id: string, name: string, state: string, stateCode: string>, itemsPerPage: float, page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stateCode" $state_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/cities" $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country, "name": $name, "p": $p, "state": $state, "stateCode": $state_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a complete list of all supported countries.
#
# GET /1.0/search/countries
# operationId: resource__1.0_search_countries_getCountries_GET
export def "1-0-search-countries get" [
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
]: nothing -> record<country: table<code: string, name: string>, itemsPerPage: float, page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1.0/search/countries" $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# Search for setlists.
#
# GET /1.0/search/setlists
# operationId: resource__1.0_search_setlists_getSetlists_GET
export def "1-0-search-setlists get" [
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
  --artist-mbid: string # the artist's Musicbrainz Identifier (mbid)
  --artist-name: string # the artist's name
  --artist-tmid: int # the artist's Ticketmaster Identifier (tmid)
  --city-id: string # the city's geoId
  --city-name: string # the name of the city
  --country-code: string # the country code
  --date: string # the date of the event (format dd-MM-yyyy)
  --last-fm: int # the event's Last.fm Event ID (deprecated)
  --last-updated: string # the date and time (UTC) when this setlist was last updated (format yyyyMMddHHmmss) - either edited or reverted. search will return setlists that were updated on or after this date
  --p: int # the number of the result page (default: 1)
  --state: string # the state
  --state-code: string # the state code
  --tour-name: string
  --venue-id: string # the venue id
  --venue-name: string # the name of the venue
  --year: string # the year of the event
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artistMbid" $artist_mbid "scalar") (serialize-qp "artistName" $artist_name "scalar") (serialize-qp "artistTmid" $artist_tmid "scalar") (serialize-qp "cityId" $city_id "scalar") (serialize-qp "cityName" $city_name "scalar") (serialize-qp "countryCode" $country_code "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lastFm" $last_fm "scalar") (serialize-qp "lastUpdated" $last_updated "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stateCode" $state_code "scalar") (serialize-qp "tourName" $tour_name "scalar") (serialize-qp "venueId" $venue_id "scalar") (serialize-qp "venueName" $venue_name "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/setlists" $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"artistMbid": $artist_mbid, "artistName": $artist_name, "artistTmid": $artist_tmid, "cityId": $city_id, "cityName": $city_name, "countryCode": $country_code, "date": $date, "lastFm": $last_fm, "lastUpdated": $last_updated, "p": $p, "state": $state, "stateCode": $state_code, "tourName": $tour_name, "venueId": $venue_id, "venueName": $venue_name, "year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for venues.
#
# GET /1.0/search/venues
# operationId: resource__1.0_search_venues_getVenues_GET
export def "1-0-search-venues get" [
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
  --city-id: string # the city's geoId
  --city-name: string # name of the city where the venue is located
  --country: string # the city's country
  --name: string # name of the venue
  --p: int # the number of the result page you'd like to have (default: 1)
  --state: string # the city's state
  --state-code: string # the city's state code
]: nothing -> record<itemsPerPage: float, page: float, total: float, venue: table<city: record, id: string, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cityId" $city_id "scalar") (serialize-qp "cityName" $city_name "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stateCode" $state_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/venues" $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cityId": $city_id, "cityName": $city_name, "country": $country, "name": $name, "p": $p, "state": $state, "stateCode": $state_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# .
#
# GET /1.0/setlist/version/{versionId}
# operationId: resource__1.0_setlist_version__versionId__getSetlistVersion_GET
export def "1-0-setlist-version get" [
  version_id: string
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
]: nothing -> record<artist: record<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string>, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: table<encore: float, name: string, song: list>, tour: record<name: string>, url: string, venue: record<city: record<coords: record, country: record, id: string, name: string, state: string, stateCode: string>, id: string, name: string, url: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'versionId' must be non-empty" } }
  let full_url = (build-url $base ({version_id: (encode-path-segment $version_id)} | format pattern "/1.0/setlist/version/{version_id}") $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# .
#
# GET /1.0/setlist/{setlistId}
# operationId: resource__1.0_setlist__setlistId__getSetlist_GET
export def "1-0-setlist get" [
  setlist_id: string
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
]: nothing -> record<artist: record<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string>, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: table<encore: float, name: string, song: list>, tour: record<name: string>, url: string, venue: record<city: record<coords: record, country: record, id: string, name: string, state: string, stateCode: string>, id: string, name: string, url: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($setlist_id | is-empty) { error make --unspanned { msg: "path parameter 'setlistId' must be non-empty" } }
  let full_url = (build-url $base ({setlist_id: (encode-path-segment $setlist_id)} | format pattern "/1.0/setlist/{setlist_id}") $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# Get a user by userId.
#
# GET /1.0/user/{userId}
# operationId: resource__1.0_user__userId__getUser_GET
export def "1-0-user get" [
  user_id: string
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
]: nothing -> record<about: string, flickr: string, fullname: string, lastFm: string, mySpace: string, twitter: string, url: string, userId: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/1.0/user/{user_id}") $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# .
#
# GET /1.0/user/{userId}/attended
# operationId: resource__1.0_user__userId__attended_getUserAttendedSetlists_GET
export def "1-0-user-attended get-setlists" [
  user_id: string
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
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/1.0/user/{user_id}/attended") $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"p": $p} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# .
#
# GET /1.0/user/{userId}/edited
# operationId: resource__1.0_user__userId__edited_getUserEditedSetlists_GET
export def "1-0-user-edited get-setlists" [
  user_id: string
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
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/1.0/user/{user_id}/edited") $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"p": $p} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a venue by its unique id.
#
# GET /1.0/venue/{venueId}
# operationId: resource__1.0_venue__venueId__getVenue_GET
export def "1-0-venue get" [
  venue_id: string
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
]: nothing -> record<city: record<coords: record<lat: float, long: float>, country: record<code: string, name: string>, id: string, name: string, state: string, stateCode: string>, id: string, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($venue_id | is-empty) { error make --unspanned { msg: "path parameter 'venueId' must be non-empty" } }
  let full_url = (build-url $base ({venue_id: (encode-path-segment $venue_id)} | format pattern "/1.0/venue/{venue_id}") $auth.query)
  let accept_val = ($accept | default "application/xml")
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

# .
#
# GET /1.0/venue/{venueId}/setlists
# operationId: resource__1.0_venue__venueId__setlists_getVenueSetlists_GET
export def "1-0-venue-setlists get" [
  venue_id: string
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
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($venue_id | is-empty) { error make --unspanned { msg: "path parameter 'venueId' must be non-empty" } }
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({venue_id: (encode-path-segment $venue_id)} | format pattern "/1.0/venue/{venue_id}/setlists") $qp $auth.query)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"p": $p} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
