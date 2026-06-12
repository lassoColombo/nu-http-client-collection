# Auto-generated client for setlist.fm API v1.0
# Source: https://api.apis.guru/v2/specs/setlist.fm/1.0/swagger.json
# Auth: --token flag or $env.SETLIST_FM_API_TOKEN

const BASE_URL = "https://localhost/rest"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SETLIST_FM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "10-artist GET" } } | get name | first)
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
export def "10-artist GET" [
  mbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1.0/artist/($mbid)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# .
#
# GET /1.0/artist/{mbid}/setlists
# operationId: resource__1.0_artist__mbid__setlists_getArtistSetlists_GET
export def "10-artist-setlists GET" [
  mbid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1.0/artist/($mbid)/setlists" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a city by its unique geoId.
#
# GET /1.0/city/{geoId}
# operationId: resource__1.0_city__geoId__getCity_GET
export def "10-city GET" [
  geoId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<coords: record<lat: float, long: float>, country: record<code: string, name: string>, id: string, name: string, state: string, stateCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1.0/city/($geoId)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for artists.
#
# GET /1.0/search/artists
# operationId: resource__1.0_search_artists_getArtists_GET
export def "10-search-artists GET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --artistMbid: string # the artist's Musicbrainz Identifier (mbid)
  --artistName: string # the artist's name
  --artistTmid: int # the artist's Ticketmaster Identifier (tmid)
  --p: int # the number of the result page you'd like to have (default: 1)
  --qp-sort: string # the sort of the result, either sortName (default) or relevance (default: sortName)
]: nothing -> record<artist: table<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string>, itemsPerPage: float, page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artistMbid" $artistMbid "scalar") (serialize-qp "artistName" $artistName "scalar") (serialize-qp "artistTmid" $artistTmid "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/artists" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a city.
#
# GET /1.0/search/cities
# operationId: resource__1.0_search_cities_getCities_GET
export def "10-search-cities GET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --country: string # the city's country
  --name: string # name of the city
  --p: int # the number of the result page you'd like to have (default: 1)
  --state: string # state the city lies in
  --stateCode: string # state code the city lies in
]: nothing -> record<cities: table<coords: record, country: record, id: string, name: string, state: string, stateCode: string>, itemsPerPage: float, page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stateCode" $stateCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/cities" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a complete list of all supported countries.
#
# GET /1.0/search/countries
# operationId: resource__1.0_search_countries_getCountries_GET
export def "10-search-countries GET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<country: table<code: string, name: string>, itemsPerPage: float, page: float, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1.0/search/countries")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for setlists.
#
# GET /1.0/search/setlists
# operationId: resource__1.0_search_setlists_getSetlists_GET
export def "10-search-setlists GET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --artistMbid: string # the artist's Musicbrainz Identifier (mbid)
  --artistName: string # the artist's name
  --artistTmid: int # the artist's Ticketmaster Identifier (tmid)
  --cityId: string # the city's geoId
  --cityName: string # the name of the city
  --countryCode: string # the country code
  --date: string # the date of the event (format dd-MM-yyyy)
  --lastFm: int # the event's Last.fm Event ID (deprecated)
  --lastUpdated: string # the date and time (UTC) when this setlist was last updated (format yyyyMMddHHmmss) - either edited or reverted. search will return setlists that were updated on or after this date
  --p: int # the number of the result page (default: 1)
  --state: string # the state
  --stateCode: string # the state code
  --tourName: string
  --venueId: string # the venue id
  --venueName: string # the name of the venue
  --year: string # the year of the event
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artistMbid" $artistMbid "scalar") (serialize-qp "artistName" $artistName "scalar") (serialize-qp "artistTmid" $artistTmid "scalar") (serialize-qp "cityId" $cityId "scalar") (serialize-qp "cityName" $cityName "scalar") (serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lastFm" $lastFm "scalar") (serialize-qp "lastUpdated" $lastUpdated "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stateCode" $stateCode "scalar") (serialize-qp "tourName" $tourName "scalar") (serialize-qp "venueId" $venueId "scalar") (serialize-qp "venueName" $venueName "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/setlists" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for venues.
#
# GET /1.0/search/venues
# operationId: resource__1.0_search_venues_getVenues_GET
export def "10-search-venues GET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --cityId: string # the city's geoId
  --cityName: string # name of the city where the venue is located
  --country: string # the city's country
  --name: string # name of the venue
  --p: int # the number of the result page you'd like to have (default: 1)
  --state: string # the city's state
  --stateCode: string # the city's state code
]: nothing -> record<itemsPerPage: float, page: float, total: float, venue: table<city: record, id: string, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cityId" $cityId "scalar") (serialize-qp "cityName" $cityName "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "stateCode" $stateCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.0/search/venues" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# .
#
# GET /1.0/setlist/version/{versionId}
# operationId: resource__1.0_setlist_version__versionId__getSetlistVersion_GET
export def "10-setlist-version GET" [
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<artist: record<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string>, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: table<encore: float, name: string, song: list>, tour: record<name: string>, url: string, venue: record<city: record<coords: record, country: record, id: string, name: string, state: string, stateCode: string>, id: string, name: string, url: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1.0/setlist/version/($versionId)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# .
#
# GET /1.0/setlist/{setlistId}
# operationId: resource__1.0_setlist__setlistId__getSetlist_GET
export def "10-setlist GET" [
  setlistId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<artist: record<disambiguation: string, mbid: string, name: string, sortName: string, tmid: float, url: string>, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: table<encore: float, name: string, song: list>, tour: record<name: string>, url: string, venue: record<city: record<coords: record, country: record, id: string, name: string, state: string, stateCode: string>, id: string, name: string, url: string>, versionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1.0/setlist/($setlistId)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user by userId.
#
# GET /1.0/user/{userId}
# operationId: resource__1.0_user__userId__getUser_GET
export def "10-user GET" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<about: string, flickr: string, fullname: string, lastFm: string, mySpace: string, twitter: string, url: string, userId: string, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1.0/user/($userId)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# .
#
# GET /1.0/user/{userId}/attended
# operationId: resource__1.0_user__userId__attended_getUserAttendedSetlists_GET
export def "10-user-attended GET" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1.0/user/($userId)/attended" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# .
#
# GET /1.0/user/{userId}/edited
# operationId: resource__1.0_user__userId__edited_getUserEditedSetlists_GET
export def "10-user-edited GET" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1.0/user/($userId)/edited" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a venue by its unique id.
#
# GET /1.0/venue/{venueId}
# operationId: resource__1.0_venue__venueId__getVenue_GET
export def "10-venue GET" [
  venueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<city: record<coords: record<lat: float, long: float>, country: record<code: string, name: string>, id: string, name: string, state: string, stateCode: string>, id: string, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1.0/venue/($venueId)")
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# .
#
# GET /1.0/venue/{venueId}/setlists
# operationId: resource__1.0_venue__venueId__setlists_getVenueSetlists_GET
export def "10-venue-setlists GET" [
  venueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --p: int # the number of the result page (default: 1)
]: nothing -> record<itemsPerPage: float, page: float, setlist: table<artist: record, eventDate: string, id: string, info: string, lastFmEventId: float, lastUpdated: string, set: list, tour: record, url: string, venue: record, versionId: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1.0/venue/($venueId)/setlists" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
