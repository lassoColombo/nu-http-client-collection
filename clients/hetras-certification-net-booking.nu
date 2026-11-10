# Auto-generated client for hetras Booking API Version 0 v0
# Source: https://api.apis.guru/v2/specs/hetras-certification.net/booking/v0/swagger.json
# Auth: --token flag or $env.HETRAS_BOOKING_API_VERSION_0_TOKEN

const BASE_URL = "https://api.hetras-certification.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o HETRAS_BOOKING_API_VERSION_0_TOKEN | default "" }
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

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.hetras-certification.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def expand-completer [] { ["Breakdown" "None"] }
def accept-completer [] { ["application/json" "text/json"] }
def expand-completer-1 [] { ["RoomTypes"] }
def inlinecount-completer [] { ["AllPages" "None"] }
def status-completer [] { ["Cancelled" "Definite" "Tentative"] }
def date-filter-completer [] { ["ArrivalDate" "CreationDate" "DepartureDate" "ModificationDate" "StayDate"] }
def exclude-completer [] { ["Customers"] }
def payment-method-completer [] { ["Cash" "ChargeToCompany" "Check" "CreditCard" "DebitCard" "DigitalPayment" "Miscellaneous" "None" "Token" "Voucher" "WireTransfer"] }
def expand-completer-2 [] { ["None" "RoomRates"] }
def exclude-completer-1 [] { ["Customers" "None"] }
def condition-completer [] { ["Any" "Clean" "CleanNotInspected" "Dirty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["addons-get" "availability-get" "blocks-get-blocks-async" "blocks-get-blocks-count-async" "blocks-get-single-block-async" "bookings-get-bookings" "bookings-create-booking" "bookings-get-bookings-count" "bookings-get-booking" "bookings-get-reservation" "bookings-patch" "bookings-post-room-assignment" "bookings-cancel-reservation" "bookings-check-in" "bookings-check-out" "bookings-payment-token" "bookings-terminal-authorization" "daily-rates-get-daily-rates" "rates-get" "commands"] | sort) } | get name | first)
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

# Get a list of offers for addon services for the specified guest stay details.
#
# GET /api/booking/v0/addons
# operationId: Addons_Get
export def "addons-get" [
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
  --hotel-id: int # Specifies the hotel id to request offers for. (required, format: int32)
  --arrival-date: string # Date from when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". (required, format: date-time)
  --departure-date: string # Date until when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". This is usually the departure date of the reservation. (required, format: date-time)
  --channel-code: string # Channel Code the rate plan needs to be configured for. (required)
  --adults: string # Number of adults per room. (required, format: byte)
  --rooms: string # Number of rooms. (required, format: byte)
  --room-type: string # Only return offers for the specified room type code. (required)
  --rate-plan-code: string # Only return offers for the specified rate plan code. (required)
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<addon_services: table<breakdown: list, code: string, description: string, frequency: string, name: string, rate_mode: string, total_stay: record>, adults: int, arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plan: record<code: string, description: string, name: string>, room: record<description: string, name: string, room_number: int, type: string>, rooms: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hotel_id == null) { error make --unspanned { msg: "required query parameter 'hotelId' missing: pass --hotel-id" } }
  if ($arrival_date == null) { error make --unspanned { msg: "required query parameter 'arrivalDate' missing: pass --arrival-date" } }
  if ($departure_date == null) { error make --unspanned { msg: "required query parameter 'departureDate' missing: pass --departure-date" } }
  if ($channel_code == null) { error make --unspanned { msg: "required query parameter 'channelCode' missing: pass --channel-code" } }
  if ($adults == null) { error make --unspanned { msg: "required query parameter 'adults' missing: pass --adults" } }
  if ($rooms == null) { error make --unspanned { msg: "required query parameter 'rooms' missing: pass --rooms" } }
  if ($room_type == null) { error make --unspanned { msg: "required query parameter 'roomType' missing: pass --room-type" } }
  if ($rate_plan_code == null) { error make --unspanned { msg: "required query parameter 'ratePlanCode' missing: pass --rate-plan-code" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "arrivalDate" $arrival_date "scalar") (serialize-qp "departureDate" $departure_date "scalar") (serialize-qp "channelCode" $channel_code "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "rooms" $rooms "scalar") (serialize-qp "roomType" $room_type "scalar") (serialize-qp "ratePlanCode" $rate_plan_code "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/addons" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "arrivalDate": $arrival_date, "departureDate": $departure_date, "channelCode": $channel_code, "adults": $adults, "rooms": $rooms, "roomType": $room_type, "ratePlanCode": $rate_plan_code, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the availability and occupancy for a specific hotel and timespan.
#
# GET /api/booking/v0/availability
# operationId: Availability_Get
export def "availability-get" [
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
  --hotel-id: int # Specifies the hotel id to request the availability for. (required, format: int32)
  --from: string # Defines the first business day you would like to get availability numbers for. (required, format: date-time)
  --to: string # Defines the last business day you would like to get availability numbers for. The maximum time span between from´and to is limited to 365 days. (required, format: date-time)
  --expand: string@expand-completer-1 # You can expand the room types breakdown per business day for the availibility numbers if need be.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_count: int, _links: record, daily_availabilities: table<business_day: string, house_level: record, room_types: list>, hotel: record<code: string, id: int, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hotel_id == null) { error make --unspanned { msg: "required query parameter 'hotelId' missing: pass --hotel-id" } }
  if ($from == null) { error make --unspanned { msg: "required query parameter 'from' missing: pass --from" } }
  if ($to == null) { error make --unspanned { msg: "required query parameter 'to' missing: pass --to" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/availability" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "from": $from, "to": $to, "expand": $expand, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets a list of blocks.
#
# GET /api/booking/v0/blocks
# operationId: Blocks_GetBlocksAsync
export def "blocks-get-blocks-async" [
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
  --hotel-id: int # Only return blocks for this specific hotel. (format: int32)
  --group-code: string # Filter the blocks by the specified group code
  --from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --rate-plan-codes: list<string> # Return all blocks that have related the specified comma-separated rate plans.
  --count-details: oneof<nothing, bool> # If true it will include also details of block count per each room type.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "groupCode" $group_code "scalar") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "countDetails" $count_details "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/blocks" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "groupCode": $group_code, "from": $from, "to": $to, "status": $status, "ratePlanCodes": $rate_plan_codes, "countDetails": $count_details, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get total blocks count that match the given filter criteria.
#
# GET /api/booking/v0/blocks/$count
# operationId: Blocks_GetBlocksCountAsync
export def "blocks-get-blocks-count-async" [
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
  --hotel-id: int # Only return blocks for this specific hotel. (format: int32)
  --group-code: string # Filter the blocks by the specified group code
  --from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --rate-plan-codes: list<string> # Return all blocks that have related the specified comma-separated rate plans.
  --count-details: oneof<nothing, bool> # If true it will include also details of block count per each room type.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_count: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "groupCode" $group_code "scalar") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "countDetails" $count_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/blocks/$count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "groupCode": $group_code, "from": $from, "to": $to, "status": $status, "ratePlanCodes": $rate_plan_codes, "countDetails": $count_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the details for a specific block.
#
# GET /api/booking/v0/blocks/{blockCode}
# operationId: Blocks_GetSingleBlockAsync
export def "blocks-get-single-block-async" [
  block_code: string
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($block_code | is-empty) { error make --unspanned { msg: "path parameter 'blockCode' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({block_code: (encode-path-segment $block_code)} | format pattern "/api/booking/v0/blocks/{block_code}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Find bookings matching the given filter criteria.
#
# GET /api/booking/v0/bookings
# operationId: Bookings_GetBookings
export def "bookings-get-bookings" [
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
  --hotel-id: int # Only return bookings for this specific hotel. (format: int32)
  --cancellation-id: string # Return bookings for this cancellation id.
  --reservation-number: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customer-name: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-email: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-id: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --room-number: string # Return all bookings having the specified room number assigned.
  --external-id: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --company-name: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --company-id: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --company-email: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --block-code: string # Return all bookings where the block code matches the specified value.
  --reservation-statuses: list<string> # Return all bookings where the reservation status is one of the specified values.
  --market-codes: list<string> # Return all bookings where the market code is one of the specified values.
  --channel-codes: list<string> # Return all bookings where the channel code is one of the specified values.
  --sub-channel-codes: list<string> # Return all bookings where the subchannel code is one of the specified values.
  --room-types: list<string> # Return all bookings where the room type is one of the specified values.
  --rate-plan-codes: list<string> # Return all bookings where the rate plan code is one of the specified values.
  --labels: list<string> # Return all reservations with at least one of the specified labels.
  --from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or later. (format: date-time)
  --to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or earlier. (format: date-time)
  --date-filter: string@date-filter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_count: int, _links: record, bookings: table<_links: record, confirmation_id: string, created: string, reservations: list, updated: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "cancellationId" $cancellation_id "scalar") (serialize-qp "reservationNumber" $reservation_number "scalar") (serialize-qp "customerName" $customer_name "scalar") (serialize-qp "customerEmail" $customer_email "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "roomNumber" $room_number "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "companyName" $company_name "scalar") (serialize-qp "companyId" $company_id "scalar") (serialize-qp "companyEmail" $company_email "scalar") (serialize-qp "blockCode" $block_code "scalar") (serialize-qp "reservationStatuses" $reservation_statuses "csv") (serialize-qp "marketCodes" $market_codes "csv") (serialize-qp "channelCodes" $channel_codes "csv") (serialize-qp "subChannelCodes" $sub_channel_codes "csv") (serialize-qp "roomTypes" $room_types "csv") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "labels" $labels "csv") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "dateFilter" $date_filter "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "cancellationId": $cancellation_id, "reservationNumber": $reservation_number, "customerName": $customer_name, "customerEmail": $customer_email, "customerId": $customer_id, "roomNumber": $room_number, "externalId": $external_id, "companyName": $company_name, "companyId": $company_id, "companyEmail": $company_email, "blockCode": $block_code, "reservationStatuses": $reservation_statuses, "marketCodes": $market_codes, "channelCodes": $channel_codes, "subChannelCodes": $sub_channel_codes, "roomTypes": $room_types, "ratePlanCodes": $rate_plan_codes, "labels": $labels, "from": $from, "to": $to, "dateFilter": $date_filter, "exclude": $exclude, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Create a new booking.
#
# POST /api/booking/v0/bookings
# operationId: Bookings_CreateBooking
export def "bookings-create-booking" [
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
  --send-confirmation: oneof<nothing, bool> # Whether to send a confirmation email to the primary guest
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --addons: list<string> # A list of addon service codes that should be booked for all reservations of this booking
  --adults: int # The number of adults per room (format: int32)
  --arrival-date: string # The arrival date of the guests (format: date-time)
  --channel-code: string # The channel code for this reservation. You can find available channels in the codes for the hotel.
  --comment: string # The comment you want to add for this reservation
  --company: record # shape: {company_id?: string}
  --contact: record # shape: {customer_id?: string}
  --departure-date: string # The departure date of the guests (format: date-time)
  --external-id: string # The external id for this reservation. You can put here your own id used by you or the external system you integrate hetras with
  --group-code: string # The group code based on which the reservation will be created.
  --guarantee: record # shape: {guarantee_type?: "PM4Hold"|"PM6Hold"|"GuaranteeToCreditCard"|"GuaranteeToGuestAccount"|"GuaranteeByTravelAgent"|"GuaranteeByCompany"|"Deposit"|"Voucher"|"Prepayment"|"NonGuaranteed"|"Tentative"|"Waitlist", token?: record}
  --guests: list # A list of guests with some basic guest details — item shape: {consent_subscribe?: list<string>, consent_unsubscribe?: list<string>, customer_id?: string, email?: string, first_name?: string, gender?: "Unspecified"|"Male"|"Female", last_name?: string, mailing_address?: record, nationality?: string, phone?: string, primary?: bool, title?: string}
  hotel_id: int # The id of the hotel this reservation is valid for (format: int32)
  --payment-method: string@payment-method-completer # The payment method for this reservation
  --prepay-discount: float # If you create a booking for a rateplan requiring prepayment this amount will be deducted from the booking value before the prepayment will be taken. This feature is useful when the booker redeems a gift voucher and you want to only capture the remaining amount from the guest´s credit card (format: double)
  --rate-plan: string # The rate plan code this reservation is related to
  --room-type: string # The room type code this reservation is related to
  --rooms: int # The number of rooms this reservation is for. After a multi-room booking is done there will be one reservation in hetras for all rooms. The hotel staff then will split this reservation into one reservation per room to be able to check in the guests (format: int32)
  --travel-agent: record # shape: {company_id?: string}
]: any -> oneof<record<_warnings: list<string>, confirmation_id: string, reservation_id: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "sendConfirmation" $send_confirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings" $qp $auth.query)
  let req_body = {"addons": $addons, "adults": $adults, "arrival_date": $arrival_date, "channel_code": $channel_code, "comment": $comment, "company": $company, "contact": $contact, "departure_date": $departure_date, "external_id": $external_id, "group_code": $group_code, "guarantee": $guarantee, "guests": $guests, "hotel_id": $hotel_id, "payment_method": $payment_method, "prepay_discount": $prepay_discount, "rate_plan": $rate_plan, "room_type": $room_type, "rooms": $rooms, "travel_agent": $travel_agent} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"sendConfirmation": $send_confirmation} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get total count of bookings matchung the given filter criteria.
#
# GET /api/booking/v0/bookings/$count
# operationId: Bookings_GetBookingsCount
export def "bookings-get-bookings-count" [
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
  --hotel-id: int # Only return bookings for this specific hotel. (format: int32)
  --cancellation-id: string # Return bookings for this cancellation id.
  --reservation-number: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customer-name: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-email: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-id: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --room-number: string # Return all bookings having the specified room number assigned.
  --external-id: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --company-name: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --company-id: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --company-email: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --block-code: string # Return all bookings where the block code matches the specified value.
  --reservation-statuses: list<string> # Return all bookings where the reservation status is one of the specified values.
  --market-codes: list<string> # Return all bookings where the market code is one of the specified values.
  --channel-codes: list<string> # Return all bookings where the channel code is one of the specified values.
  --sub-channel-codes: list<string> # Return all bookings where the subchannel code is one of the specified values.
  --room-types: list<string> # Return all bookings where the room type is one of the specified values.
  --rate-plan-codes: list<string> # Return all bookings where the rate plan code is one of the specified values.
  --labels: list<string> # Return all reservations with at least one of the specified labels.
  --from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or later. (format: date-time)
  --to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or earlier. (format: date-time)
  --date-filter: string@date-filter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_count: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "cancellationId" $cancellation_id "scalar") (serialize-qp "reservationNumber" $reservation_number "scalar") (serialize-qp "customerName" $customer_name "scalar") (serialize-qp "customerEmail" $customer_email "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "roomNumber" $room_number "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "companyName" $company_name "scalar") (serialize-qp "companyId" $company_id "scalar") (serialize-qp "companyEmail" $company_email "scalar") (serialize-qp "blockCode" $block_code "scalar") (serialize-qp "reservationStatuses" $reservation_statuses "csv") (serialize-qp "marketCodes" $market_codes "csv") (serialize-qp "channelCodes" $channel_codes "csv") (serialize-qp "subChannelCodes" $sub_channel_codes "csv") (serialize-qp "roomTypes" $room_types "csv") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "labels" $labels "csv") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "dateFilter" $date_filter "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings/$count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "cancellationId": $cancellation_id, "reservationNumber": $reservation_number, "customerName": $customer_name, "customerEmail": $customer_email, "customerId": $customer_id, "roomNumber": $room_number, "externalId": $external_id, "companyName": $company_name, "companyId": $company_id, "companyEmail": $company_email, "blockCode": $block_code, "reservationStatuses": $reservation_statuses, "marketCodes": $market_codes, "channelCodes": $channel_codes, "subChannelCodes": $sub_channel_codes, "roomTypes": $room_types, "ratePlanCodes": $rate_plan_codes, "labels": $labels, "from": $from, "to": $to, "dateFilter": $date_filter, "exclude": $exclude} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Load all reservations for one booking by confirmation id.
#
# GET /api/booking/v0/bookings/{confirmationId}
# operationId: Bookings_GetBooking
export def "bookings-get-booking" [
  confirmation_id: string
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
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<reservations: table<_warnings: list, addon_services: list, adults: int, arrival_date: string, balance: float, block: record, cancellation_id: string, cancellation_policies: list, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record, confirmation_id: string, contact: record, created: string, currency: string, departure_date: string, external_id: string, general_policies: list, guarantee: record, guests: list, hotel_id: int, labels: list, market_code: string, noshow_policy: record, payment_method: string, rate_plan: record, reservation_number: int, reservation_status: string, room: record, room_rates: list, rooms: int, services: list, subchannel_code: string, total_stay: record, updated: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id)} | format pattern "/api/booking/v0/bookings/{confirmation_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "exclude": $exclude} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Load a specific reservation from a booking.
#
# GET /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# operationId: Bookings_GetReservation
export def "bookings-get-reservation" [
  confirmation_id: string
  reservation_number: int
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
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_warnings: list<string>, addon_services: list<string>, adults: int, arrival_date: string, balance: float, block: record<_links: record, code: string, name: string>, cancellation_id: string, cancellation_policies: table<description: string, fee: float, fee_date: string>, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record<company_id: string>, confirmation_id: string, contact: record<_links: record, customer_id: string>, created: string, currency: string, departure_date: string, external_id: string, general_policies: table<description: string, name: string>, guarantee: record<guarantee_type: string, valid_token: bool>, guests: table<_links: record, customer_id: string, email: string, first_name: string, gender: string, last_name: string, mailing_address: record, nationality: string, phone: string, primary: bool, subscribed_consents: list, title: string>, hotel_id: int, labels: list<string>, market_code: string, noshow_policy: record<description: string, fee: float>, payment_method: string, rate_plan: record<code: string, description: string, name: string>, reservation_number: int, reservation_status: string, room: record<_links: record, description: string, name: string, number: string, room_type: record<_links: record, code: string, description: string, name: string>>, room_rates: table<addon_services: list, date: string, excluded_tax: float, included_services: list, included_tax: float, rate: float, room_type: string>, rooms: int, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>, subchannel_code: string, total_stay: record<addon_services: list<record>, excluded_tax: float, included_services: list<string>, included_tax: float, rate: float>, updated: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "exclude": $exclude} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Partially updates a reservation.
#
# PATCH /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# operationId: Bookings_Patch
export def "bookings-patch" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --body: list
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Assign a room to a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/assign_room
# operationId: Bookings_PostRoomAssignment
export def "bookings-post-room-assignment" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --amenities: list<string> # Ensure the assigned room will have all the amenities specified. You can provide a comma seperated list of amenity codes.
  --condition: string@condition-completer # Here you can define to limit the list of assignable rooms based on their current condition. This is only applicable if the underlying reservation is due to arrive on the current business day. If not set by default only clean rooms will be assigned.
  --include-out-of-service: oneof<nothing, bool> # Sometimes you might want to assign rooms which are out of service (small repair needed) if no other rooms are available anymore. If you set include_out_of_service to true even those rooms will be considered. The default is false.
  --locations: list<string> # Ensure the assigned room will have at least one of the specified locations. You can provide a comma seperated list of location codes.
  --respect-guest-preferences: oneof<nothing, bool> # Defines if the preferences for locations, amenities and views of the primary guest should be taken into account. All defined preferences in the guest profile override any of the criteria defined in the request body. The default is false.
  --room-number: string # If you define a specific room number this room will be assigned if not assigned to another reservation, has proper room type and is not OutOfOrder or OutOfInventory for the stay duration of the underlying reservaton. If set all other filter criteria will be ignored.
  --views: list<string> # Ensure the assigned room will have at least one of the specified views. You can provide a comma seperated list of view codes.
]: any -> oneof<record<_warnings: list<string>, room_number: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/assign_room") $auth.query)
  let req_body = {"amenities": $amenities, "condition": $condition, "include_out_of_service": $include_out_of_service, "locations": $locations, "respect_guest_preferences": $respect_guest_preferences, "room_number": $room_number, "views": $views} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel one reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/cancel
# operationId: Bookings_CancelReservation
export def "bookings-cancel-reservation" [
  confirmation_id: string
  reservation_number: int
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
  --send-confirmation: oneof<nothing, bool> # Whether to send a confirmation email to the primary guest
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_warnings: list<string>, balance: float, cancellation_fee: float, cancellation_id: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "sendConfirmation" $send_confirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/cancel") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"sendConfirmation": $send_confirmation} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Performs a check in operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_in
# operationId: Bookings_CheckIn
export def "bookings-check-in" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --client-identity: string # Client identity
]: any -> oneof<record<_warnings: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/check_in") $auth.query)
  let req_body = {"client_identity": $client_identity} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Performs a check out operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_out
# operationId: Bookings_CheckOut
export def "bookings-check-out" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_warnings: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/check_out") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Post a payment token for a reservation.
#
# PUT /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/payment_token
# operationId: Bookings_PaymentToken
export def "bookings-payment-token" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --authorization: record # shape: {amount?: float, expiry_date?: string, merchant_reference: string, reference: string, shopper_reference: string}
  --no-authorization-required: oneof<nothing, bool> # Whether hetras should skip authorization using the provided token when no authorization details are supplied. Optional flag, defaults to false.
  payment_token: string # The token you get from the payment service provider
]: any -> oneof<record<_warnings: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/payment_token") $auth.query)
  let req_body = {"authorization": $authorization, "no_authorization_required": $no_authorization_required, "payment_token": $payment_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Performs a chip and pin credit card authorization for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/pre_authorize
# operationId: Bookings_TerminalAuthorization
export def "bookings-terminal-authorization" [
  confirmation_id: string
  reservation_number: int
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
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
  --amount-to-authorize: float # The amount to authorize (format: double)
  --client-identity: string # Client identity
]: any -> oneof<record<_warnings: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/pre_authorize") $auth.query)
  let req_body = {"amount_to_authorize": $amount_to_authorize, "client_identity": $client_identity} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a list of daily rates given a hotel Id, a channel code and a date range.
#
# GET /api/booking/v0/daily_rates
# operationId: DailyRates_GetDailyRates
export def "daily-rates-get-daily-rates" [
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
  --hotel-id: int # Define the hotel id to request the availability for. (required, format: int32)
  --from: string # Define the first business day you would like to get availability numbers for. The day should not be in the past. (required, format: date-time)
  --to: string # Define the last business day you would like to get rates for (inclusive). The maximum time span between 'From' and 'To' is limited to 365 days. This can't be less than the 'From' date. (required, format: date-time)
  --channel-code: string # Define the channel code in order to look up the rates for. (required)
  --expand: list<string> # Define the sections you want to expand and get informed about rates for.
  --rate-plan-codes: list<string> # Define the codes of rate plans to show in the response. A list of comma ',' separated rate plan codes.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<_count: int, _links: record, daily_rates: table<business_day: string, offers: list>, hotel: record<_links: record, code: string, id: int, name: string>, policies: record<cancellation_policies: list<record>, guarantee_types: list<record>, noshow_policies: list<record>>, rateplans: table<_links: record, code: string, currency: string, name: string>, room_types: table<_links: record, code: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hotel_id == null) { error make --unspanned { msg: "required query parameter 'hotelId' missing: pass --hotel-id" } }
  if ($from == null) { error make --unspanned { msg: "required query parameter 'from' missing: pass --from" } }
  if ($to == null) { error make --unspanned { msg: "required query parameter 'to' missing: pass --to" } }
  if ($channel_code == null) { error make --unspanned { msg: "required query parameter 'channelCode' missing: pass --channel-code" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "channelCode" $channel_code "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/daily_rates" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "from": $from, "to": $to, "channelCode": $channel_code, "expand": $expand, "ratePlanCodes": $rate_plan_codes, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Get a list of room offers for the specified guest stay details.
#
# GET /api/booking/v0/rates
# operationId: Rates_Get
export def "rates-get" [
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
  --hotel-id: int # Specifies the hotel id to request offers for. (required, format: int32)
  --arrival-date: string # Date of arrival for the guest in the ISO-8601 format "YYYY-MM-DD". (required, format: date-time)
  --departure-date: string # Date of departure for the guest in the ISO-8601 format "YYYY-MM-DD". (required, format: date-time)
  --channel-code: string # Channel Code the rate plan needs to be configured for. (required)
  --adults: string # Number of adults per room. (required, format: byte)
  --rooms: string # Number of rooms (default is 1). (format: byte)
  --room-type: string # Only return offers with rates for the specified room type code.
  --rate-plan-code: string # Only return offers for the specified room type code.
  --group-code: string # Only return offers for the specified group code.
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --app-id: string # Application identifier (required)
  --app-key: string # Application key. (required)
]: nothing -> oneof<record<arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plans: table<code: string, description: string, name: string>, room_offers: table<offers: list, room_type: string>, rooms: table<description: string, name: string, room_number: int, type: string>, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($hotel_id == null) { error make --unspanned { msg: "required query parameter 'hotelId' missing: pass --hotel-id" } }
  if ($arrival_date == null) { error make --unspanned { msg: "required query parameter 'arrivalDate' missing: pass --arrival-date" } }
  if ($departure_date == null) { error make --unspanned { msg: "required query parameter 'departureDate' missing: pass --departure-date" } }
  if ($channel_code == null) { error make --unspanned { msg: "required query parameter 'channelCode' missing: pass --channel-code" } }
  if ($adults == null) { error make --unspanned { msg: "required query parameter 'adults' missing: pass --adults" } }
  if ($app_id == null) { error make --unspanned { msg: "required header parameter 'App-Id' missing: pass --app-id" } }
  if ($app_key == null) { error make --unspanned { msg: "required header parameter 'App-Key' missing: pass --app-key" } }
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "arrivalDate" $arrival_date "scalar") (serialize-qp "departureDate" $departure_date "scalar") (serialize-qp "channelCode" $channel_code "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "rooms" $rooms "scalar") (serialize-qp "roomType" $room_type "scalar") (serialize-qp "ratePlanCode" $rate_plan_code "scalar") (serialize-qp "groupCode" $group_code "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/rates" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"hotelId": $hotel_id, "arrivalDate": $arrival_date, "departureDate": $departure_date, "channelCode": $channel_code, "adults": $adults, "rooms": $rooms, "roomType": $room_type, "ratePlanCode": $rate_plan_code, "groupCode": $group_code, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
