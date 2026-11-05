# Auto-generated client for Space Radiation API v1.1.2
# Source: https://api.apis.guru/v2/specs/amentum.space/space_radiation/1.1.2/openapi.json
# Auth: --token flag or $env.SPACE_RADIATION_API_TOKEN

const BASE_URL = ""

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SPACE_RADIATION_API_TOKEN | default "" }
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
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { [""] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def model-completer [] { ["AE9" "AP9" "SPME" "SPMH" "SPMHE" "SPMO"] }
def coord-sys-completer [] { ["GDZ" "GEI" "GEO"] }
def coord-units-completer [] { ["KM" "RE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["app-api-endpoints-gcr-calculate-dlr-flux" "app-api-endpoints-trapped-radiation-calculate-flux-mean" "app-api-endpoints-trapped-radiation-calculate-flux-percentile" "commands"] | sort) } | get name | first)
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

# Calculate particle flux
#
# GET /gcr/flux_dlr
# operationId: app.api.endpoints.GCR.calculate_dlr_flux
export def "app-api-endpoints-gcr-calculate-dlr-flux" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # required, e.g. 2017
  --month: int # required, e.g. 1
  --day: int # required, e.g. 1
  --z: float # Particle atomic number (required, e.g. 6)
  --energy: float # Particle energy in MeV/n Valid range: [0, 106] MeV/n (required, e.g. 100)
]: nothing -> oneof<record<flux: record<units: string, value: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  if ($z == null) { error make --unspanned { msg: "required query parameter 'z' missing: pass --z" } }
  if ($energy == null) { error make --unspanned { msg: "required query parameter 'energy' missing: pass --energy" } }
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "z" $z "scalar") (serialize-qp "energy" $energy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gcr/flux_dlr" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "month": $month, "day": $day, "z": $z, "energy": $energy} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Calculate mean particle flux
#
# GET /trapped/flux_mean
# operationId: app.api.endpoints.TrappedRadiation.calculate_flux_mean
export def "app-api-endpoints-trapped-radiation-calculate-flux-mean" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string@model-completer # Which model to use: - Energetic electrons (AE9) - Energetic protons (AP9) - Space plasma model for electrons (SPME) - for hydrogen (SPMH) - for helium (SPMHE) - for oxygen (SPMO) (required, e.g. AE9)
  --coord-sys: string@coord-sys-completer # Coordinate system to use: - Geodetic/WGS84 (GDZ) - Geocentric Cartesian (GEO) - Geocentric Earth Inertial (GEI) See "Bhavnani, K. H., & Vancour, R. P. (1991). Coordinate systems for space and geophysical applications" for coord system definitions. (required, e.g. GEI)
  --coord-units: string@coord-units-completer # Coordinate units to use: km (KM) or Earth Radii (RE) (required, e.g. KM)
  --coord1: float # First coordinate value to specify position. Ordering for GEI, GEO coords:X, Y, Z Ordering for GDZ coords: Alt, Lat, Long Valid ranges for latitude: -90, 90 Valid ranges for longitude: 0, 360 (required, e.g. 3216.6)
  --coord2: float # Second coordinate value. (required, e.g. 35426)
  --coord3: float # Third coordinate value. (required, e.g. 603.4)
  --year: int # required, e.g. 2017
  --month: int # required, e.g. 1
  --day: int # required, e.g. 1
  --hour: int # required, e.g. 0
  --minute: int # required, e.g. 0
  --second: int # required, e.g. 0
]: nothing -> oneof<record<energies: record<data: list<float>, units: string>, flux: record<data: list<float>, units: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($model == null) { error make --unspanned { msg: "required query parameter 'model' missing: pass --model" } }
  if ($coord_sys == null) { error make --unspanned { msg: "required query parameter 'coord_sys' missing: pass --coord-sys" } }
  if ($coord_units == null) { error make --unspanned { msg: "required query parameter 'coord_units' missing: pass --coord-units" } }
  if ($coord1 == null) { error make --unspanned { msg: "required query parameter 'coord1' missing: pass --coord1" } }
  if ($coord2 == null) { error make --unspanned { msg: "required query parameter 'coord2' missing: pass --coord2" } }
  if ($coord3 == null) { error make --unspanned { msg: "required query parameter 'coord3' missing: pass --coord3" } }
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  if ($hour == null) { error make --unspanned { msg: "required query parameter 'hour' missing: pass --hour" } }
  if ($minute == null) { error make --unspanned { msg: "required query parameter 'minute' missing: pass --minute" } }
  if ($second == null) { error make --unspanned { msg: "required query parameter 'second' missing: pass --second" } }
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "coord_sys" $coord_sys "scalar") (serialize-qp "coord_units" $coord_units "scalar") (serialize-qp "coord1" $coord1 "scalar") (serialize-qp "coord2" $coord2 "scalar") (serialize-qp "coord3" $coord3 "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "minute" $minute "scalar") (serialize-qp "second" $second "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trapped/flux_mean" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"model": $model, "coord_sys": $coord_sys, "coord_units": $coord_units, "coord1": $coord1, "coord2": $coord2, "coord3": $coord3, "year": $year, "month": $month, "day": $day, "hour": $hour, "minute": $minute, "second": $second} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Calculate percentile particle flux
#
# GET /trapped/flux_percentile
# operationId: app.api.endpoints.TrappedRadiation.calculate_flux_percentile
export def "app-api-endpoints-trapped-radiation-calculate-flux-percentile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string@model-completer # Which model to use: - Energetic electrons (AE9) - Energetic protons (AP9) - Space plasma model for electrons (SPME) - for hydrogen (SPMH) - for helium (SPMHE) - for oxygen (SPMO) (required, e.g. AE9)
  --coord-sys: string@coord-sys-completer # Coordinate system to use: - Geodetic/WGS84 (GDZ) - Geocentric Cartesian (GEO) - Geocentric Earth Inertial (GEI) See "Bhavnani, K. H., & Vancour, R. P. (1991). Coordinate systems for space and geophysical applications" for coord system definitions. (required, e.g. GEI)
  --coord-units: string@coord-units-completer # Coordinate units to use: km (KM) or Earth Radii (RE) (required, e.g. KM)
  --coord1: float # First coordinate value to specify position. Ordering for GEI, GEO coords:X, Y, Z Ordering for GDZ coords: Alt, Lat, Long Valid ranges for latitude: -90, 90 Valid ranges for longitude: 0, 360 (required, e.g. 3216.6)
  --coord2: float # Second coordinate value. (required, e.g. 35426)
  --coord3: float # Third coordinate value. (required, e.g. 603.4)
  --year: int # required, e.g. 2017
  --month: int # required, e.g. 1
  --day: int # required, e.g. 1
  --hour: int # required, e.g. 0
  --minute: int # required, e.g. 0
  --second: int # required, e.g. 0
  --percentile: int # Integer percentile at which to calc flux (50 is the median value). (required, e.g. 50)
]: nothing -> oneof<record<energies: record<data: list<float>, units: string>, flux: record<data: list<float>, units: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($model == null) { error make --unspanned { msg: "required query parameter 'model' missing: pass --model" } }
  if ($coord_sys == null) { error make --unspanned { msg: "required query parameter 'coord_sys' missing: pass --coord-sys" } }
  if ($coord_units == null) { error make --unspanned { msg: "required query parameter 'coord_units' missing: pass --coord-units" } }
  if ($coord1 == null) { error make --unspanned { msg: "required query parameter 'coord1' missing: pass --coord1" } }
  if ($coord2 == null) { error make --unspanned { msg: "required query parameter 'coord2' missing: pass --coord2" } }
  if ($coord3 == null) { error make --unspanned { msg: "required query parameter 'coord3' missing: pass --coord3" } }
  if ($year == null) { error make --unspanned { msg: "required query parameter 'year' missing: pass --year" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'month' missing: pass --month" } }
  if ($day == null) { error make --unspanned { msg: "required query parameter 'day' missing: pass --day" } }
  if ($hour == null) { error make --unspanned { msg: "required query parameter 'hour' missing: pass --hour" } }
  if ($minute == null) { error make --unspanned { msg: "required query parameter 'minute' missing: pass --minute" } }
  if ($second == null) { error make --unspanned { msg: "required query parameter 'second' missing: pass --second" } }
  if ($percentile == null) { error make --unspanned { msg: "required query parameter 'percentile' missing: pass --percentile" } }
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "coord_sys" $coord_sys "scalar") (serialize-qp "coord_units" $coord_units "scalar") (serialize-qp "coord1" $coord1 "scalar") (serialize-qp "coord2" $coord2 "scalar") (serialize-qp "coord3" $coord3 "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "minute" $minute "scalar") (serialize-qp "second" $second "scalar") (serialize-qp "percentile" $percentile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trapped/flux_percentile" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"model": $model, "coord_sys": $coord_sys, "coord_units": $coord_units, "coord1": $coord1, "coord2": $coord2, "coord3": $coord3, "year": $year, "month": $month, "day": $day, "hour": $hour, "minute": $minute, "second": $second, "percentile": $percentile} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
