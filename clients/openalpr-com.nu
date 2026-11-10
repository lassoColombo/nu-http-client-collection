# Auto-generated client for OpenALPR CarCheck API v3.0.1
# Source: https://api.apis.guru/v2/specs/openalpr.com/3.0.1/swagger.json
# Auth: --token flag or $env.OPENALPR_CARCHECK_API_TOKEN

const BASE_URL = "https://api.openalpr.com/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OPENALPR_CARCHECK_API_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.openalpr.com/v3"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def recognize-vehicle-completer [] { ["0" "1"] }
def return-image-completer [] { ["0" "1"] }
def is-cropped-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-config" "recognize-file" "recognize-bytes" "recognize-url" "commands"] | sort) } | get name | first)
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

# Get a list of available results for plate and vehicle recognition
#
# GET /config
# operationId: getConfig
export def "get-config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<countries: table<code: string, name: string>, vehicle_labels: record<bodytype: list<string>, color: list<string>, make: list<string>, makemodel: list<string>, orientation: list<string>, year: list<string>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/config" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Send an image for OpenALPR to analyze and provide metadata back The image is sent as a file using a form data POST
#
# POST /recognize
# operationId: recognizeFile
export def "recognize-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-key: string # The secret key used to authenticate your account. You can view your secret key by visiting https://cloud.openalpr.com/ (required)
  --recognize-vehicle: int@recognize-vehicle-completer # If set to 1, the vehicle will also be recognized in the image This requires an additional credit per request (default: 0)
  --country: string # Defines the training data used by OpenALPR. "us" analyzes North-American style plates. "eu" analyzes European-style plates. This field is required if using the "plate" task (required)
  --return-image: int@return-image-completer # If set to 1, the image you uploaded will be encoded in base64 and sent back along with the response (default: 0)
  --topn: int # The number of results you would like to be returned for plate candidates and vehicle classifications (default: 10)
  --is-cropped: int@is-cropped-completer # When providing a plate or vehicle that is already cropped, this performs a recognition against the full crop and does not attempt to localize the plate/vehicle (default: 0)
  image: path # The image file that you wish to analyze
]: any -> oneof<record<credit_cost: int, credits_monthly_total: int, credits_monthly_used: int, data_type: string, epoch_time: float, img_height: int, img_width: int, processing_time: record<plates: float, total: float, vehicles: float>, regions_of_interest: table<height: int, width: int, x: int, y: int>, results: table<candidates: list, confidence: float, coordinates: list, matches_template: int, plate: string, processing_time_ms: float, region: string, region_confidence: float, requested_topn: int, vehicle: record, vehicle_region: record>, vehicles: table<details: record, height: int, width: int, x: int, y: int>, version: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_key == null) { error make --unspanned { msg: "required query parameter 'secret_key' missing: pass --secret-key" } }
  if ($country == null) { error make --unspanned { msg: "required query parameter 'country' missing: pass --country" } }
  let qp = [(serialize-qp "secret_key" $secret_key "scalar") (serialize-qp "recognize_vehicle" $recognize_vehicle "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "return_image" $return_image "scalar") (serialize-qp "topn" $topn "scalar") (serialize-qp "is_cropped" $is_cropped "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recognize" $qp $auth.query)
  let req_body = {"image": $image} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body ["image"] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: ({"secret_key": $secret_key, "recognize_vehicle": $recognize_vehicle, "country": $country, "return_image": $return_image, "topn": $topn, "is_cropped": $is_cropped} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Send an image for OpenALPR to analyze and provide metadata back The image is sent as base64 encoded bytes.
#
# POST /recognize_bytes
# operationId: recognizeBytes
export def "recognize-bytes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --secret-key: string # The secret key used to authenticate your account. You can view your secret key by visiting https://cloud.openalpr.com/ (required)
  --recognize-vehicle: int@recognize-vehicle-completer # If set to 1, the vehicle will also be recognized in the image This requires an additional credit per request (default: 0)
  --country: string # Defines the training data used by OpenALPR. "us" analyzes North-American style plates. "eu" analyzes European-style plates. This field is required if using the "plate" task (required)
  --return-image: int@return-image-completer # If set to 1, the image you uploaded will be encoded in base64 and sent back along with the response (default: 0)
  --topn: int # The number of results you would like to be returned for plate candidates and vehicle classifications (default: 10)
  --body: string
]: any -> oneof<record<credit_cost: int, credits_monthly_total: int, credits_monthly_used: int, data_type: string, epoch_time: float, img_height: int, img_width: int, processing_time: record<plates: float, total: float, vehicles: float>, regions_of_interest: table<height: int, width: int, x: int, y: int>, results: table<candidates: list, confidence: float, coordinates: list, matches_template: int, plate: string, processing_time_ms: float, region: string, region_confidence: float, requested_topn: int, vehicle: record, vehicle_region: record>, vehicles: table<details: record, height: int, width: int, x: int, y: int>, version: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($secret_key == null) { error make --unspanned { msg: "required query parameter 'secret_key' missing: pass --secret-key" } }
  if ($country == null) { error make --unspanned { msg: "required query parameter 'country' missing: pass --country" } }
  let qp = [(serialize-qp "secret_key" $secret_key "scalar") (serialize-qp "recognize_vehicle" $recognize_vehicle "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "return_image" $return_image "scalar") (serialize-qp "topn" $topn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recognize_bytes" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"secret_key": $secret_key, "recognize_vehicle": $recognize_vehicle, "country": $country, "return_image": $return_image, "topn": $topn} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Send an image for OpenALPR to analyze and provide metadata back The image is sent as a URL. The OpenALPR service will download the image and process it
#
# POST /recognize_url
# operationId: recognizeUrl
export def "recognize-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-url: string # A URL to an image that you wish to analyze (required)
  --secret-key: string # The secret key used to authenticate your account. You can view your secret key by visiting https://cloud.openalpr.com/ (required)
  --recognize-vehicle: int@recognize-vehicle-completer # If set to 1, the vehicle will also be recognized in the image This requires an additional credit per request (default: 0)
  --country: string # Defines the training data used by OpenALPR. "us" analyzes North-American style plates. "eu" analyzes European-style plates. This field is required if using the "plate" task (required)
  --return-image: int@return-image-completer # If set to 1, the image you uploaded will be encoded in base64 and sent back along with the response (default: 0)
  --topn: int # The number of results you would like to be returned for plate candidates and vehicle classifications (default: 10)
]: nothing -> oneof<record<credit_cost: int, credits_monthly_total: int, credits_monthly_used: int, data_type: string, epoch_time: float, img_height: int, img_width: int, processing_time: record<plates: float, total: float, vehicles: float>, regions_of_interest: table<height: int, width: int, x: int, y: int>, results: table<candidates: list, confidence: float, coordinates: list, matches_template: int, plate: string, processing_time_ms: float, region: string, region_confidence: float, requested_topn: int, vehicle: record, vehicle_region: record>, vehicles: table<details: record, height: int, width: int, x: int, y: int>, version: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($image_url == null) { error make --unspanned { msg: "required query parameter 'image_url' missing: pass --image-url" } }
  if ($secret_key == null) { error make --unspanned { msg: "required query parameter 'secret_key' missing: pass --secret-key" } }
  if ($country == null) { error make --unspanned { msg: "required query parameter 'country' missing: pass --country" } }
  let qp = [(serialize-qp "image_url" $image_url "scalar") (serialize-qp "secret_key" $secret_key "scalar") (serialize-qp "recognize_vehicle" $recognize_vehicle "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "return_image" $return_image "scalar") (serialize-qp "topn" $topn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recognize_url" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"image_url": $image_url, "secret_key": $secret_key, "recognize_vehicle": $recognize_vehicle, "country": $country, "return_image": $return_image, "topn": $topn} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}
