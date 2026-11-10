# Auto-generated client for Transportation Laws and Incentives v0.1.0
# Source: https://api.apis.guru/v2/specs/nrel.gov/transportation-incentives-laws/0.1.0/openapi.json
# Auth: --token flag or $env.TRANSPORTATION_LAWS_AND_INCENTIVES_TOKEN

const BASE_URL = "http://localhost/api/transportation-incentives-laws"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TRANSPORTATION_LAWS_AND_INCENTIVES_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/api/transportation-incentives-laws"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def output-format-completer [] { ["csv" "json" "xml"] }
def output-format-completer-1 [] { ["json" "xml"] }
def type-completer [] { ["incentive" "regulation" "tech" "user"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["transportation-incentives-laws-all" "transportation-incentives-laws-categories" "transportation-incentives-laws-pocs" "transportation-incentives-laws-id" "commands"] | sort) } | get name | first)
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

# Return a full list of laws and incentives that match your query.
#
# GET /v1.{output_format}
# operationId: transportation_incentives_laws_all
export def "transportation-incentives-laws-all" [
  output_format: string@output-format-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API Key (required, default: DEMO_KEY)
  --limit: int # Limit the number of laws returned (default: 10)
  --jurisdiction: string # Return laws for the given Jurisdiction. Jurisdiction must be given as a two character state code (eg, 'CO' for Colorado). A single jurisdiction, or a comma-separate list of multiple jurisdiction, may be given. Use the code 'US' for federal laws and the code 'DC' for Washington D.C.
  --technology: string # Search by the technology type. A single type, or a comma-separate list of multiple types, may be given. Values and what they stand for are as follows: 'BIOD' for Biodiesel, 'ETH' for Ethanol / Flexible Fuel Vehicles, 'NG' for Natural Gas / Natural Gas Vehicles, 'LPG' for Liquefied Petroleum Gas (Propane) / Propane Vehicles, 'HY' for Hydrogen / Fuel Cell Electric Vehicles, 'ELEC' for All-Electric Vehicles (EVs), 'PHEV' for Plug-In Hybrid Electric Vehicles (PHEVs), 'HEV' for Hybrid Electric Vehicles (HEVs), 'NEVS' for Neighborhood Electric Vehicles (NEVs), 'RD' for Renewable Diesel, 'AFTMKTCONV' for Aftermarket Conversions, 'EFFEC' for Fuel Economy / Efficiency, 'IR' for Idle Reduction, 'AUTONOMOUS' for Connected and Autonomous Vehicles, and 'OTHER' for Other.
  --incentive-type: string # Search by the incentive type. A single type, or a comma-separate list of multiple types, may be given. Values and what they stand for are as follows: 'GNT' for Grants, 'TAX' for Tax Incentives, 'LOANS' for Loans and Leases, 'RBATE' for Rebates, 'EXEM' for Exemptions, 'TOU' for Time-of-Use Rate, and 'OTHER' for Other.
  --regulation-type: string # Search by the regulation type. A single type, or a comma-separate list of multiple types, may be given. Values and what they stand for are as follows: 'REQ' for Acquisition / Fuel Use, 'DREST' for Driving / Idling, 'REGIS' for Registration / Licensing, 'EVFEE' for EV Registration Fee, 'FUEL' for Fuel Taxes, 'STD' for Fuel Production / Quality, 'RFS' for Renewable Fuel Standard / Mandate, 'AIRQEMISSIONS' for Air Quality / Emissions, 'CCEINIT' for Climate Change / Energy Initiatives, 'UTILITY' for Utility Definition, 'BUILD' for Building Codes, 'RTC' for Right-to-Charge, and 'OTHER' for Other.
  --user-type: string # Search by the user type. A single type, or a comma-separate list of multiple types, may be given. Values and what they stand for are as follows: 'FLEET' for Commercial, 'GOV' for Government Entity, 'TRIBAL' for Tribal Government, 'IND' for Personal Vehicle Owner or Driver, 'STATION' for Alternative Fuel Infrastructure Operator, 'AFP' for Alternative Fuel Producer, 'PURCH' for Alternative Fuel Purchaser, 'MAN' for Alternative Fuel Vehicle (AFV) Manufacturer or Retrofitter, 'MUD' for Multi-Unit Dwelling, 'TRANS' for Transit, and 'OTHER' for Other.
  --poc: oneof<nothing, bool> # Include points of contacts in the return value. (default: false)
  --recent: oneof<nothing, bool> # Return only recently added or updated laws and incentives (default: false)
  --expired: oneof<nothing, bool> # The 'true' value returns only expired, repealed, or archived laws and incentives. The default 'false' value returns only current laws and incentives. (default: false)
  --law-type: string # Search by the law type. A single type, or a comma-separate list of multiple types, may be given. Values are as follows: 'STATEINC' for State Incentives, 'UPINC ' for Utility/Private Incentives, 'LAWREG' for Laws and Regulations, 'INC' for Incentives, 'PROG' for Programs, 'LUP' for Last Updated, 'OVIEW' for Overview, and 'HILITE' for Highlights.
  --keyword: string # Search laws by keyword in title or text.
  --local: oneof<nothing, bool> # Show only local examples of laws and incentives. (default: false)
]: nothing -> oneof<record<inputs: any, metadata: record<count: int, version: string>, result: table<agency: string, amended_date: string, archived_date: string, categories: list, contacts: list, enacted_date: string, expired_date: string, id: int, is_recent: bool, plaintext: string, recent_update_or_new: string, references: list, repealed_date: string, seq_num: int, significant_update_date: string, state: string, text: string, title: string, topics: list, type: string, types: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'output_format' must be non-empty" } }
  let api_key = ($api_key | default "DEMO_KEY")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "jurisdiction" $jurisdiction "scalar") (serialize-qp "technology" $technology "scalar") (serialize-qp "incentive_type" $incentive_type "scalar") (serialize-qp "regulation_type" $regulation_type "scalar") (serialize-qp "user_type" $user_type "scalar") (serialize-qp "poc" $poc "scalar") (serialize-qp "recent" $recent "scalar") (serialize-qp "expired" $expired "scalar") (serialize-qp "law_type" $law_type "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "local" $local "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/v1.{output_format}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "limit": $limit, "jurisdiction": $jurisdiction, "technology": $technology, "incentive_type": $incentive_type, "regulation_type": $regulation_type, "user_type": $user_type, "poc": $poc, "recent": $recent, "expired": $expired, "law_type": $law_type, "keyword": $keyword, "local": $local} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return the law categories for a given category type.
#
# GET /v1/category-list.{output_format}
# operationId: transportation_incentives_laws_categories
export def "transportation-incentives-laws-categories" [
  output_format: string@output-format-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API Key (required, default: DEMO_KEY)
  --type: string@type-completer # Search by the category type.
]: nothing -> oneof<record<inputs: any, metadata: record<count: int, version: string>, result: table<category_type: string, code: string, help_text: string, sort_order: string, title: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'output_format' must be non-empty" } }
  let api_key = ($api_key | default "DEMO_KEY")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/v1/category-list.{output_format}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the points of contact for a given jurisdiction.
#
# GET /v1/pocs.{output_format}
# operationId: transportation_incentives_laws_pocs
export def "transportation-incentives-laws-pocs" [
  output_format: string@output-format-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API Key (required, default: DEMO_KEY)
  --jurisdiction: string # Return the points of contact for the given Jurisdiction. Jurisdiction must be given as a two character state code (eg, 'CO' for Colorado). A single jurisdiction, or a comma-separate list of multiple jurisdiction, may be given. Use the code 'US' for federal laws and the code 'DC' for Washington D.C. (required)
]: nothing -> oneof<record<inputs: any, metadata: record<count: int, version: string>, result: table<agency: string, email: string, fax: string, name: string, state: string, telephone: string, title: string, web_page: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'output_format' must be non-empty" } }
  let api_key = ($api_key | default "DEMO_KEY")
  if ($jurisdiction == null) { error make --unspanned { msg: "required query parameter 'jurisdiction' missing: pass --jurisdiction" } }
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "jurisdiction" $jurisdiction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/v1/pocs.{output_format}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "jurisdiction": $jurisdiction} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetch the details of a specific law given the law's ID.
#
# GET /v1/{id}.{output_format}
# operationId: transportation_incentives_laws_id
export def "transportation-incentives-laws-id" [
  id: int
  output_format: string@output-format-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # API Key (required, default: DEMO_KEY)
  --poc: oneof<nothing, bool> # Include points of contacts in the return value. (default: false)
  --expired: oneof<nothing, bool> # The 'true' value returns a record no matter its status (current, expired, archived, or repealed). The default 'false' value returns only current laws and incentives. (default: false)
]: nothing -> oneof<record<inputs: any, metadata: record<count: int, version: string>, result: record<agency: string, amended_date: string, archived_date: string, categories: list<record>, contacts: list<record>, enacted_date: string, expired_date: string, id: int, is_recent: bool, plaintext: string, recent_update_or_new: string, references: list<record>, repealed_date: string, seq_num: int, significant_update_date: string, state: string, text: string, title: string, topics: list<record>, type: string, types: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'output_format' must be non-empty" } }
  let api_key = ($api_key | default "DEMO_KEY")
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "poc" $poc "scalar") (serialize-qp "expired" $expired "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), output_format: (encode-path-segment $output_format)} | format pattern "/v1/{id}.{output_format}") $qp $auth.query)
  let accept_val = "*/*"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api_key": $api_key, "poc": $poc, "expired": $expired} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
