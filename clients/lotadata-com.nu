# Auto-generated client for LotaData v2.0.0
# Source: https://api.apis.guru/v2/specs/lotadata.com/2.0.0/swagger.json
# Auth: --token flag or $env.LOTADATA_TOKEN

const BASE_URL = "https://api2.lotadata.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOTADATA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api2.lotadata.com/v2"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def fieldset-completer [] { ["context" "detail" "minicontext" "summary"] }
def fieldset-completer-1 [] { ["context" "detail" "summary"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "events list" } } | get name | first)
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

# Find event occurrences in the area. Returns results at specific place and time, event groups are expanded for every occurrence.
#
# GET /events
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: list<string> # List of required EventCategory ids (Tier 1)
  --activity: string # List of required activity type ids (compliment to category)
  --ambience: string # List of required ambience ids
  --genre: string # List of required genre ids
  --name: string # Matching on event and place names
  --q: string # Text query matching titles, description, various text, tags, category
  --from-day: string # Start on or after date specified (2015-10-16)
  --to-day: string # Start on or before date specified (2015-10-16)
  --capacity-min: float # Min capacity at location (format: integer)
  --capacity-max: float # Min capacity at location (format: integer)
  --center: string # latitude,longitude of the origin point
  --radius: int # Distance from origin in meters
  --bbox: list<string> # Corner of a bounding box (lat,lng). Requires 0 or 2 pairs
  --polygon: list<string> # Closed custom polygon. Ordered list of lat,lng pairs
  --within: string # Search within specified geopolitical place id
  --offset: int # Return results starting at specified offset
  --limit: int # Max results to return
  --fieldset: string@fieldset-completer # Return results starting at specified offset (summary, context, detail) (default: context)
]: nothing -> record<events: table<_id: string, _type: string, activity: list, ambience: list, at: record, awayTeam: record, category: list, contactPoint: record, description: string, doorTime: string, duration: string, endApprox: bool, endDate: string, extTaxonomy: list, genre: list, headline: string, homeTeam: record, htmlDescription: string, image: record, inLanguage: record, name: string, noTime: bool, offers: list, onDemand: bool, performer: list, photo: list, startDate: string, superEvent: record, updated: string, url: string, workPerformed: list>, query: record<activity: list<string>, category: list<string>, limit: int>, stats: record<count: int, fieldset: string, runtime: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "multi") (serialize-qp "activity" $activity "scalar") (serialize-qp "ambience" $ambience "scalar") (serialize-qp "genre" $genre "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "from_day" $from_day "scalar") (serialize-qp "to_day" $to_day "scalar") (serialize-qp "capacity_min" $capacity_min "scalar") (serialize-qp "capacity_max" $capacity_max "scalar") (serialize-qp "center" $center "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "bbox" $bbox "multi") (serialize-qp "polygon" $polygon "multi") (serialize-qp "within" $within "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "activity": $activity, "ambience": $ambience, "genre": $genre, "name": $name, "q": $q, "from_day": $from_day, "to_day": $to_day, "capacity_min": $capacity_min, "capacity_max": $capacity_max, "center": $center, "radius": $radius, "bbox": $bbox, "polygon": $polygon, "within": $within, "offset": $offset, "limit": $limit, "fieldset": $fieldset} | compact), body: null}
}

# Get Specific event details.
#
# GET /events/{id}
export def "events get" [
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
  --fieldset: string@fieldset-completer # default: summary
]: nothing -> record<_id: string, _type: string, activity: table<_id: string, _type: string, name: string>, ambience: table<_id: string, _type: string, name: string>, at: record<_id: string, _type: string, address: record<country: string, formatted: string, locality: string, postalCode: string, region: string, street: string, unit: string>, geo: record<lat: float, lon: float>, geometry: any, location: record<domain: string, platform: string, url: string>, logo: record<_id: string, caption: string, height: int, url: string, width: int>, name: string, tag: list<record>>, awayTeam: record<_id: string, _type: string, name: string>, category: table<_id: string, _type: string, name: string>, contactPoint: record<displayPhone: string, email: string, facebookUrl: string, instagramName: string, lastfmUrl: string, soundcloudUrl: string, spotifyUrl: string, twitterName: string, url: string, youtubeUrl: string>, description: string, doorTime: string, duration: string, endApprox: bool, endDate: string, extTaxonomy: table<_id: string, _type: string, name: string>, genre: table<_id: string, _type: string, name: string>, headline: string, homeTeam: record<_id: string, _type: string, name: string>, htmlDescription: string, image: record<_id: string, caption: string, height: int, url: string, width: int>, inLanguage: record<_id: string, _type: string, name: string>, name: string, noTime: bool, offers: table<availability: string, category: string, donation: bool, fee: float, highPrice: float, inventory: record, name: string, price: float, priceCurrency: string, priceUnknown: bool, url: string>, onDemand: bool, performer: table<_id: string, _type: string, name: string>, photo: table<_id: string, caption: string, height: int, url: string, width: int>, startDate: string, superEvent: record<_id: string, name: string, startDate: string>, updated: string, url: string, workPerformed: table<_id: string, _type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fieldset": $fieldset} | compact), body: null}
}

# Venues, landmarks, regions, these are all places to search.
#
# GET /places
export def "places list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: list<string> # List of required PlaceCategory ids (Tier 1)
  --function: list<string> # List of required PlaceFunction ids (Tier 2)
  --ambience: list<string> # List of required ambience ids
  --tag: list<string> # List of required tags
  --type: string # Specific PlaceType to return
  --name: string # Match on place names
  --exact: oneof<nothing, bool> # Require an exact name match
  --capacity-min: float # Min capacity at location (format: integer)
  --capacity-max: float # Min capacity at location (format: integer)
  --street: string # Address of the place or street component of the address
  --locality: string # city, town, or neighborhood of the place
  --region: string # region or state
  --postal-code: string # Postal or zip code
  --country: string # country component of the address
  --center: string # latitude,longitude of the origin point
  --radius: int # Distance from origin in meters
  --bbox: list<string> # Corner of a bounding box (lat,lng). Requires 0 or 2 pairs
  --polygon: list<string> # Closed custom polygon. Ordered list of lat,lng pairs
  --within: string # Search within specified geopolitical place id
  --offset: int # Return results starting at specified offset
  --limit: int # Max results to return
  --fieldset: string@fieldset-completer-1 # Return results starting at specified offset (summary, context, detail) (default: context)
]: nothing -> record<places: table<ambience: list, category: list, contact: record, function: list, openingHours: list, photo: list, _id: string, _type: string, address: record, geo: record, geometry: any, location: record, logo: record, name: string, tag: list>, query: record<address: record<country: string, formatted: string, locality: string, postalCode: string, region: string, street: string, unit: string>, category: list<string>, limit: int>, stats: record<count: int, fieldset: string, runtime: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "multi") (serialize-qp "function" $function "multi") (serialize-qp "ambience" $ambience "csv") (serialize-qp "tag" $tag "csv") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exact" $exact "scalar") (serialize-qp "capacity_min" $capacity_min "scalar") (serialize-qp "capacity_max" $capacity_max "scalar") (serialize-qp "street" $street "scalar") (serialize-qp "locality" $locality "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "center" $center "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "bbox" $bbox "multi") (serialize-qp "polygon" $polygon "multi") (serialize-qp "within" $within "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "function": $function, "ambience": $ambience, "tag": $tag, "type": $type, "name": $name, "exact": $exact, "capacity_min": $capacity_min, "capacity_max": $capacity_max, "street": $street, "locality": $locality, "region": $region, "postal_code": $postal_code, "country": $country, "center": $center, "radius": $radius, "bbox": $bbox, "polygon": $polygon, "within": $within, "offset": $offset, "limit": $limit, "fieldset": $fieldset} | compact), body: null}
}

# Get specific place details
#
# GET /places/{id}
export def "places get" [
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
  --fieldset: string@fieldset-completer # default: summary
]: nothing -> record<ambience: table<_id: string, _type: string, name: string>, category: table<_id: string, _type: string, name: string>, contact: record<displayPhone: string, email: string, facebookUrl: string, instagramName: string, lastfmUrl: string, soundcloudUrl: string, spotifyUrl: string, twitterName: string, url: string, youtubeUrl: string>, function: table<_id: string, _type: string, name: string>, openingHours: table<closes: string, dayOfWeek: list, open247: bool, opens: string>, photo: table<_id: string, caption: string, height: int, url: string, width: int>, _id: string, _type: string, address: record<country: string, formatted: string, locality: string, postalCode: string, region: string, street: string, unit: string>, geo: record<lat: float, lon: float>, geometry: any, location: record<domain: string, platform: string, url: string>, logo: record<_id: string, caption: string, height: int, url: string, width: int>, name: string, tag: table<_id: string, _type: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/places/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fieldset": $fieldset} | compact), body: null}
}
