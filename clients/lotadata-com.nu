# Auto-generated client for LotaData v2.0.0
# Source: https://api.apis.guru/v2/specs/lotadata.com/2.0.0/swagger.json
# Auth: --token flag or $env.LOTADATA_TOKEN

const BASE_URL = "https://api2.lotadata.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LOTADATA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api2.lotadata.com/v2"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def fieldset-completer [] { ["context" "detail" "minicontext" "summary"] }
def fieldset-completer-1 [] { ["context" "detail" "summary"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-events" "get-events-id" "get-places" "get-places-id" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "get-events" [
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
  --fieldset: string@fieldset-completer # Return results starting at specified offset (summary, context, detail) (required, default: context)
]: nothing -> oneof<record<events: table<_id: string, _type: string, activity: list, ambience: list, at: record, awayTeam: record, category: list, contactPoint: record, description: string, doorTime: string, duration: string, endApprox: bool, endDate: string, extTaxonomy: list, genre: list, headline: string, homeTeam: record, htmlDescription: string, image: record, inLanguage: record, name: string, noTime: bool, offers: list, onDemand: bool, performer: list, photo: list, startDate: string, superEvent: record, updated: string, url: string, workPerformed: list>, query: record<activity: list<string>, category: list<string>, limit: int>, stats: record<count: int, fieldset: string, runtime: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let fieldset = ($fieldset | default "context")
  let qp = [(serialize-qp "category" $category "multi") (serialize-qp "activity" $activity "scalar") (serialize-qp "ambience" $ambience "scalar") (serialize-qp "genre" $genre "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "from_day" $from_day "scalar") (serialize-qp "to_day" $to_day "scalar") (serialize-qp "capacity_min" $capacity_min "scalar") (serialize-qp "capacity_max" $capacity_max "scalar") (serialize-qp "center" $center "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "bbox" $bbox "multi") (serialize-qp "polygon" $polygon "multi") (serialize-qp "within" $within "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category": $category, "activity": $activity, "ambience": $ambience, "genre": $genre, "name": $name, "q": $q, "from_day": $from_day, "to_day": $to_day, "capacity_min": $capacity_min, "capacity_max": $capacity_max, "center": $center, "radius": $radius, "bbox": $bbox, "polygon": $polygon, "within": $within, "offset": $offset, "limit": $limit, "fieldset": $fieldset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Specific event details.
#
# GET /events/{id}
export def "get-events-id" [
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
]: nothing -> oneof<record<_id: string, _type: string, activity: table<_id: string, _type: string, name: string>, ambience: table<_id: string, _type: string, name: string>, at: record<_id: string, _type: string, address: record<country: string, formatted: string, locality: string, postalCode: string, region: string, street: string, unit: string>, geo: record<lat: float, lon: float>, geometry: any, location: record<domain: string, platform: string, url: string>, logo: record<_id: string, caption: string, height: int, url: string, width: int>, name: string, tag: list<record>>, awayTeam: record<_id: string, _type: string, name: string>, category: table<_id: string, _type: string, name: string>, contactPoint: record<displayPhone: string, email: string, facebookUrl: string, instagramName: string, lastfmUrl: string, soundcloudUrl: string, spotifyUrl: string, twitterName: string, url: string, youtubeUrl: string>, description: string, doorTime: string, duration: string, endApprox: bool, endDate: string, extTaxonomy: table<_id: string, _type: string, name: string>, genre: table<_id: string, _type: string, name: string>, headline: string, homeTeam: record<_id: string, _type: string, name: string>, htmlDescription: string, image: record<_id: string, caption: string, height: int, url: string, width: int>, inLanguage: record<_id: string, _type: string, name: string>, name: string, noTime: bool, offers: table<availability: string, category: string, donation: bool, fee: float, highPrice: float, inventory: record, name: string, price: float, priceCurrency: string, priceUnknown: bool, url: string>, onDemand: bool, performer: table<_id: string, _type: string, name: string>, photo: table<_id: string, caption: string, height: int, url: string, width: int>, startDate: string, superEvent: record<_id: string, name: string, startDate: string>, updated: string, url: string, workPerformed: table<_id: string, _type: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/events/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldset": $fieldset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Venues, landmarks, regions, these are all places to search.
#
# GET /places
export def "get-places" [
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
  --fieldset: string@fieldset-completer-1 # Return results starting at specified offset (summary, context, detail) (required, default: context)
]: nothing -> oneof<record<places: table<ambience: list, category: list, contact: record, function: list, openingHours: list, photo: list, _id: string, _type: string, address: record, geo: record, geometry: any, location: record, logo: record, name: string, tag: list>, query: record<address: record<country: string, formatted: string, locality: string, postalCode: string, region: string, street: string, unit: string>, category: list<string>, limit: int>, stats: record<count: int, fieldset: string, runtime: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let fieldset = ($fieldset | default "context")
  let qp = [(serialize-qp "category" $category "multi") (serialize-qp "function" $function "multi") (serialize-qp "ambience" $ambience "csv") (serialize-qp "tag" $tag "csv") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "exact" $exact "scalar") (serialize-qp "capacity_min" $capacity_min "scalar") (serialize-qp "capacity_max" $capacity_max "scalar") (serialize-qp "street" $street "scalar") (serialize-qp "locality" $locality "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "postal_code" $postal_code "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "center" $center "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "bbox" $bbox "multi") (serialize-qp "polygon" $polygon "multi") (serialize-qp "within" $within "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/places" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category": $category, "function": $function, "ambience": $ambience, "tag": $tag, "type": $type, "name": $name, "exact": $exact, "capacity_min": $capacity_min, "capacity_max": $capacity_max, "street": $street, "locality": $locality, "region": $region, "postal_code": $postal_code, "country": $country, "center": $center, "radius": $radius, "bbox": $bbox, "polygon": $polygon, "within": $within, "offset": $offset, "limit": $limit, "fieldset": $fieldset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get specific place details
#
# GET /places/{id}
export def "get-places-id" [
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
]: nothing -> oneof<record<ambience: table<_id: string, _type: string, name: string>, category: table<_id: string, _type: string, name: string>, contact: record<displayPhone: string, email: string, facebookUrl: string, instagramName: string, lastfmUrl: string, soundcloudUrl: string, spotifyUrl: string, twitterName: string, url: string, youtubeUrl: string>, function: table<_id: string, _type: string, name: string>, openingHours: table<closes: string, dayOfWeek: list, open247: bool, opens: string>, photo: table<_id: string, caption: string, height: int, url: string, width: int>, _id: string, _type: string, address: record<country: string, formatted: string, locality: string, postalCode: string, region: string, street: string, unit: string>, geo: record<lat: float, lon: float>, geometry: any, location: record<domain: string, platform: string, url: string>, logo: record<_id: string, caption: string, height: int, url: string, width: int>, name: string, tag: table<_id: string, _type: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fieldset" $fieldset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/places/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldset": $fieldset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
