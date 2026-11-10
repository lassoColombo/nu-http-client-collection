# Auto-generated client for Atmosphere API v1.1.1
# Source: https://api.apis.guru/v2/specs/amentum.space/atmosphere/1.1.1/openapi.json
# Auth: --token flag or $env.ATMOSPHERE_API_TOKEN

const BASE_URL = ""

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ATMOSPHERE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { [""] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["app-api-endpoints-jb2008-sample-atmosphere" "app-api-endpoints-nrlmsise00-sample-atmosphere" "app-api-wfs-endpoints-wfs-get-values" "commands"] | sort) } | get name | first)
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

# Compute atmospheric density and temperatures
#
# GET /jb2008
# operationId: app.api.endpoints.JB2008.sample_atmosphere
export def "app-api-endpoints-jb2008-sample-atmosphere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year in YYYY format (required, e.g. 2020)
  --month: int # Month in MM format (required, e.g. 5)
  --day: int # Day in DD format (required, e.g. 23)
  --altitude: float # Altitude in (km) (required, e.g. 300)
  --geodetic-latitude: float # GeodeticLatitude (deg) -90 to 90 deg (required, e.g. 42)
  --geodetic-longitude: float # GeodeticLongitude (deg) 0 to 360 deg (required, e.g. 42)
  --utc: float # Coordinated Universal Time (hrs) (required, e.g. 2)
]: nothing -> oneof<record<at_alt_temp: record<units: string, value: float>, exospheric_temp: record<units: string, value: float>, total_mass_density: record<units: string, value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  if ($altitude == null) { error make --unspanned { msg: "required query parameter 'altitude' missing: pass --altitude" } }
  if ($geodetic_latitude == null) { error make --unspanned { msg: "required query parameter 'geodetic_latitude' missing: pass --geodetic-latitude" } }
  if ($geodetic_longitude == null) { error make --unspanned { msg: "required query parameter 'geodetic_longitude' missing: pass --geodetic-longitude" } }
  if ($utc == null) { error make --unspanned { msg: "required query parameter 'utc' missing: pass --utc" } }
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "geodetic_latitude" $geodetic_latitude "scalar") (serialize-qp "geodetic_longitude" $geodetic_longitude "scalar") (serialize-qp "utc" $utc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jb2008" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "month": $month, "day": $day, "altitude": $altitude, "geodetic_latitude": $geodetic_latitude, "geodetic_longitude": $geodetic_longitude, "utc": $utc} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Compute atmospheric composition, density, and temperatures
#
# GET /nrlmsise00
# operationId: app.api.endpoints.NRLMSISE00.sample_atmosphere
export def "app-api-endpoints-nrlmsise00-sample-atmosphere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year in YYYY format (required, e.g. 2020)
  --month: int # Month in MM format (required, e.g. 5)
  --day: int # Day in DD format (required, e.g. 23)
  --altitude: float # Altitude in (km) (required, e.g. 300)
  --geodetic-latitude: float # GeodeticLatitude (deg) -90 to 90 deg (required, e.g. 42)
  --geodetic-longitude: float # GeodeticLongitude (deg) 0 to 360 deg (required, e.g. 42)
  --utc: float # Coordinated Universal Time (hrs) (required, e.g. 2)
  --f107a: float # (Optional) 81 day average of F10.7 flux (SFU) centered on the specified day. F107 and F107A values correspond to the 10.7 cm radio flux at the actual distance of Earth from Sun rather than radio flux at 1 AU. F107, F107A, AP effects can be neglected below 80 km. If unspecified, values provided by the US National Oceanic and Atmospheric Administration are retrieved automatically. (e.g. 120)
  --f107: float # (Optional) Daily F10.7 cm radio flux for previous day (SFU). F107 and F107A values correspond to the 10.7 cm radio flux at the actual distance of Earth from Sun rather than radio flux at 1 AU. F107, F107A, AP effects can be neglected below 80 km. If unspecified, values provided by the US National Oceanic and Atmospheric Administration are retrieved automatically. (e.g. 120)
  --ap: float # (Optional) The Ap-index provides a daily average level for geomagnetic activity F107, F107A, AP effects can be neglected below 80 km. If unspecified, the average of values in the 24 hours preceding the date-time are automatically calculated from data provided by GFZ German Research Centre for Geosciences. (e.g. 30)
]: nothing -> oneof<record<Ar_density: record<units: string, value: float>, H_density: record<units: string, value: float>, He_density: record<units: string, value: float>, N2_density: record<units: string, value: float>, N_density: record<units: string, value: float>, O2_density: record<units: string, value: float>, O_density: record<units: string, value: float>, anomalous_O_density: record<units: string, value: float>, ap: record<value: float>, at_alt_temp: record<units: string, value: float>, exospheric_temp: record<units: string, value: float>, f107: record<units: string, value: float>, f107a: record<units: string, value: float>, total_mass_density: record<units: string, value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  if ($altitude == null) { error make --unspanned { msg: "required query parameter 'altitude' missing: pass --altitude" } }
  if ($geodetic_latitude == null) { error make --unspanned { msg: "required query parameter 'geodetic_latitude' missing: pass --geodetic-latitude" } }
  if ($geodetic_longitude == null) { error make --unspanned { msg: "required query parameter 'geodetic_longitude' missing: pass --geodetic-longitude" } }
  if ($utc == null) { error make --unspanned { msg: "required query parameter 'utc' missing: pass --utc" } }
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "geodetic_latitude" $geodetic_latitude "scalar") (serialize-qp "geodetic_longitude" $geodetic_longitude "scalar") (serialize-qp "utc" $utc "scalar") (serialize-qp "f107a" $f107a "scalar") (serialize-qp "f107" $f107 "scalar") (serialize-qp "ap" $ap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nrlmsise00" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "month": $month, "day": $day, "altitude": $altitude, "geodetic_latitude": $geodetic_latitude, "geodetic_longitude": $geodetic_longitude, "utc": $utc, "f107a": $f107a, "f107": $f107, "ap": $ap} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Forecast winds, ion and molecular densities, and temperatures in the atmosphere
#
# GET /wam-ipe
# operationId: app.api_wfs.endpoints.WFS.get_values
export def "app-api-wfs-endpoints-wfs-get-values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: float # Latitude (deg) -90 to 90 deg (required, e.g. 42)
  --longitude: float # Longitude (deg) 0 to 360 deg or -180 to 180 deg (required, e.g. 42)
  --altitude: float # Altitude in (km) (required, e.g. 300)
  --year: int # Year in YYYY format (required, e.g. 2020)
  --month: int # Month in MM format (required, e.g. 5)
  --day: int # Day in DD format (required, e.g. 23)
  --hour: int # UTC Hour of the day in 24 hour format (required, e.g. 15)
  --minute: int # Minute of the given hour (required, e.g. 10)
]: nothing -> oneof<record<N2_density: record<units: string, value: float>, O2_density: record<units: string, value: float>, O_density: record<units: string, value: float>, eastward_wind_neutral: record<units: string, value: float>, northward_wind_neutral: record<units: string, value: float>, point: record<altitude: float, latitude: float, longitude: float>, temp_neutral: record<units: string, value: float>, total_mass_density: record<units: string, value: float>, upward_wind_neutral: record<units: string, value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($latitude == null) { error make --unspanned { msg: "required query parameter 'latitude' missing: pass --latitude" } }
  if ($longitude == null) { error make --unspanned { msg: "required query parameter 'longitude' missing: pass --longitude" } }
  if ($altitude == null) { error make --unspanned { msg: "required query parameter 'altitude' missing: pass --altitude" } }
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  if ($hour == null) { error make --unspanned { msg: "required query parameter 'hour' missing: pass --hour" } }
  if ($minute == null) { error make --unspanned { msg: "required query parameter 'minute' missing: pass --minute" } }
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "minute" $minute "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wam-ipe" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"latitude": $latitude, "longitude": $longitude, "altitude": $altitude, "year": $year, "month": $month, "day": $day, "hour": $hour, "minute": $minute} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
