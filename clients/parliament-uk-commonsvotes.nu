# Auto-generated client for Commons Votes API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/commonsvotes/v1/swagger.json
# Auth: --token flag or $env.COMMONS_VOTES_API_TOKEN

const BASE_URL = "http://commonsvotes-api.parliament.uk"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o COMMONS_VOTES_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://commonsvotes-api.parliament.uk" "https://commonsvotes-api.parliament.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "data-division get" } } | get name | first)
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

# Return a Division
#
# GET /data/division/{divisionId}.{format}
# operationId: Divisions_GetDivisionById
export def "data-division get" [
  division_id: int
  format: string
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
]: nothing -> record<AyeCount: int, AyeTellers: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Ayes: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Date: string, DivisionId: int, DoubleMajorityAyeCount: int, DoubleMajorityNoCount: int, EVELCountry: string, EVELType: string, FriendlyDescription: string, FriendlyTitle: string, IsDeferred: bool, NoCount: int, NoTellers: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, NoVoteRecorded: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Noes: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Number: int, PublicationUpdated: string, RemoteVotingEnd: string, RemoteVotingStart: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($division_id | is-empty) { error make --unspanned { msg: "path parameter 'divisionId' must be non-empty" } }
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({division_id: (encode-path-segment $division_id), format: (encode-path-segment $format)} | format pattern "/data/division/{division_id}.{format}") $auth.query)
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

# Return Divisions results grouped by party
#
# GET /data/divisions.{format}/groupedbyparty
# operationId: Divisions_GetDivisionsGroupsByParty
export def "data-divisions-format-groupedbyparty get-groups-by-party" [
  format: string
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
  --query-parameters-search-term: string # Divisions containing search term within title or number
  --query-parameters-member-id: int # Divisions returning Member with Member ID voting records (format: int32)
  --query-parameters-include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted
  --query-parameters-start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (format: int32)
]: nothing -> table<AyeCount: int, Ayes: list<record>, Date: string, DivisionId: int, NoCount: int, Noes: list<record>, Number: int, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/data/divisions.{format}/groupedbyparty") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"queryParameters.searchTerm": $query_parameters_search_term, "queryParameters.memberId": $query_parameters_member_id, "queryParameters.includeWhenMemberWasTeller": $query_parameters_include_when_member_was_teller, "queryParameters.startDate": $query_parameters_start_date, "queryParameters.endDate": $query_parameters_end_date, "queryParameters.divisionNumber": $query_parameters_division_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return voting records for a Member
#
# GET /data/divisions.{format}/membervoting
# operationId: Divisions_GetVotingRecordsForMember
export def "data-divisions-format-membervoting get-voting-records-for-member" [
  format: string
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
  --query-parameters-member-id: int # Id number of a Member whose voting records are to be returned (format: int32)
  --query-parameters-skip: int # The number of records to skip. Default is 0 (format: int32)
  --query-parameters-take: int # The number of records to return per page. Default is 25 (format: int32)
  --query-parameters-search-term: string # Divisions containing search term within title or number
  --query-parameters-include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted
  --query-parameters-start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (format: int32)
]: nothing -> table<MemberId: int, MemberVotedAye: bool, MemberWasTeller: bool, PublishedDivision: record<AyeCount: int, AyeTellers: list, Ayes: list, Date: string, DivisionId: int, DoubleMajorityAyeCount: int, DoubleMajorityNoCount: int, EVELCountry: string, EVELType: string, FriendlyDescription: string, FriendlyTitle: string, IsDeferred: bool, NoCount: int, NoTellers: list, NoVoteRecorded: list, Noes: list, Number: int, PublicationUpdated: string, RemoteVotingEnd: string, RemoteVotingStart: string, Title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.skip" $query_parameters_skip "scalar") (serialize-qp "queryParameters.take" $query_parameters_take "scalar") (serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/data/divisions.{format}/membervoting") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"queryParameters.memberId": $query_parameters_member_id, "queryParameters.skip": $query_parameters_skip, "queryParameters.take": $query_parameters_take, "queryParameters.searchTerm": $query_parameters_search_term, "queryParameters.includeWhenMemberWasTeller": $query_parameters_include_when_member_was_teller, "queryParameters.startDate": $query_parameters_start_date, "queryParameters.endDate": $query_parameters_end_date, "queryParameters.divisionNumber": $query_parameters_division_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return a list of Divisions
#
# GET /data/divisions.{format}/search
# operationId: Divisions_SearchDivisions
export def "data-divisions-format-search list" [
  format: string
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
  --query-parameters-skip: int # The number of records to skip. Default is 0 (format: int32)
  --query-parameters-take: int # The number of records to return per page. Default is 25 (format: int32)
  --query-parameters-search-term: string # Divisions containing search term within title or number
  --query-parameters-member-id: int # Divisions returning Member with Member ID voting records (format: int32)
  --query-parameters-include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted
  --query-parameters-start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (format: int32)
]: nothing -> table<AyeCount: int, AyeTellers: list<record>, Ayes: list<record>, Date: string, DivisionId: int, DoubleMajorityAyeCount: int, DoubleMajorityNoCount: int, EVELCountry: string, EVELType: string, FriendlyDescription: string, FriendlyTitle: string, IsDeferred: bool, NoCount: int, NoTellers: list<record>, NoVoteRecorded: list<record>, Noes: list<record>, Number: int, PublicationUpdated: string, RemoteVotingEnd: string, RemoteVotingStart: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "queryParameters.skip" $query_parameters_skip "scalar") (serialize-qp "queryParameters.take" $query_parameters_take "scalar") (serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/data/divisions.{format}/search") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"queryParameters.skip": $query_parameters_skip, "queryParameters.take": $query_parameters_take, "queryParameters.searchTerm": $query_parameters_search_term, "queryParameters.memberId": $query_parameters_member_id, "queryParameters.includeWhenMemberWasTeller": $query_parameters_include_when_member_was_teller, "queryParameters.startDate": $query_parameters_start_date, "queryParameters.endDate": $query_parameters_end_date, "queryParameters.divisionNumber": $query_parameters_division_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return total results count
#
# GET /data/divisions.{format}/searchTotalResults
# operationId: Divisions_SearchTotalResults
export def "data-divisions-format-search-total-results list" [
  format: string
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
  --query-parameters-search-term: string # Divisions containing search term within title or number
  --query-parameters-member-id: int # Divisions returning Member with Member ID voting records (format: int32)
  --query-parameters-include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted
  --query-parameters-start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (format: int32)
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/data/divisions.{format}/searchTotalResults") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"queryParameters.searchTerm": $query_parameters_search_term, "queryParameters.memberId": $query_parameters_member_id, "queryParameters.includeWhenMemberWasTeller": $query_parameters_include_when_member_was_teller, "queryParameters.startDate": $query_parameters_start_date, "queryParameters.endDate": $query_parameters_end_date, "queryParameters.divisionNumber": $query_parameters_division_number} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
