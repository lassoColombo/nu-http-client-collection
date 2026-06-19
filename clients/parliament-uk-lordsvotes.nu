# Auto-generated client for Lords Votes API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/lordsvotes/v1/openapi.json
# Auth: --token flag or $env.LORDS_VOTES_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LORDS_VOTES_API_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def total-votes-cast-comparator-completer [] { ["EqualTo" "GreaterThan" "GreaterThanOrEqualTo" "LessThan" "LessThanOrEqualTo"] }
def majority-comparator-completer [] { ["EqualTo" "GreaterThan" "GreaterThanOrEqualTo" "LessThan" "LessThanOrEqualTo"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "data-divisions-groupedbyparty get" } } | get name | first)
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

# Return Divisions results grouped by party
#
# GET /data/Divisions/groupedbyparty
export def "data-divisions-groupedbyparty get" [
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
  --search-term: string # Divisions containing search term within title or number (nullable)
  --member-id: int # Divisions returning Member with Member ID voting records (nullable, format: int32)
  --include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted (nullable)
  --start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (nullable, format: int32)
  --total-votes-cast-comparator: string@total-votes-cast-comparator-completer # comparison operator to use
  --total-votes-cast-value-to-compare: int # value to compare to with the operator provided (format: int32)
  --majority-comparator: string@majority-comparator-completer # comparison operator to use
  --majority-value-to-compare: int # value to compare to with the operator provided (format: int32)
]: nothing -> record<content: table<partyName: string, voteCount: int>, contentCount: int, date: string, divisionId: int, notContent: table<partyName: string, voteCount: int>, notContentCount: int, number: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchTerm" $search_term "scalar") (serialize-qp "MemberId" $member_id "scalar") (serialize-qp "IncludeWhenMemberWasTeller" $include_when_member_was_teller "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "DivisionNumber" $division_number "scalar") (serialize-qp "TotalVotesCast.Comparator" $total_votes_cast_comparator "scalar") (serialize-qp "TotalVotesCast.ValueToCompare" $total_votes_cast_value_to_compare "scalar") (serialize-qp "Majority.Comparator" $majority_comparator "scalar") (serialize-qp "Majority.ValueToCompare" $majority_value_to_compare "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/Divisions/groupedbyparty" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SearchTerm": $search_term, "MemberId": $member_id, "IncludeWhenMemberWasTeller": $include_when_member_was_teller, "StartDate": $start_date, "EndDate": $end_date, "DivisionNumber": $division_number, "TotalVotesCast.Comparator": $total_votes_cast_comparator, "TotalVotesCast.ValueToCompare": $total_votes_cast_value_to_compare, "Majority.Comparator": $majority_comparator, "Majority.ValueToCompare": $majority_value_to_compare} | compact), body: null}
}

# Return voting records for a Member
#
# GET /data/Divisions/membervoting
export def "data-divisions-membervoting get" [
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
  --member-id: int # Id number of a Member whose voting records are to be returned (format: int32)
  --search-term: string # Divisions containing search term within title or number (nullable)
  --include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted (nullable)
  --start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (nullable, format: int32)
  --total-votes-cast-comparator: string@total-votes-cast-comparator-completer # comparison operator to use
  --total-votes-cast-value-to-compare: int # value to compare to with the operator provided (format: int32)
  --majority-comparator: string@majority-comparator-completer # comparison operator to use
  --majority-value-to-compare: int # value to compare to with the operator provided (format: int32)
  --skip: int # The number of records to skip. Must be a positive integer. Default is 0 (format: int32, default: 0)
  --take: int # The number of records to return per page. Must be more than 0. Default is 25 (format: int32, default: 25)
]: nothing -> record<memberId: int, memberWasContent: bool, memberWasTeller: bool, publishedDivision: record<amendmentMotionNotes: string, authoritativeContentCount: int, authoritativeNotContentCount: int, contentTellers: list<record>, contents: list<record>, date: string, divisionHadTellers: bool, divisionId: int, divisionWasExclusivelyRemote: bool, isGovernmentContent: bool, isGovernmentWin: bool, isHouse: bool, isWhipped: bool, memberContentCount: int, memberNotContentCount: int, notContentTellers: list<record>, notContents: list<record>, notes: string, number: int, remoteVotingEnd: string, remoteVotingStart: string, sponsoringMemberId: int, tellerContentCount: int, tellerNotContentCount: int, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MemberId" $member_id "scalar") (serialize-qp "SearchTerm" $search_term "scalar") (serialize-qp "IncludeWhenMemberWasTeller" $include_when_member_was_teller "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "DivisionNumber" $division_number "scalar") (serialize-qp "TotalVotesCast.Comparator" $total_votes_cast_comparator "scalar") (serialize-qp "TotalVotesCast.ValueToCompare" $total_votes_cast_value_to_compare "scalar") (serialize-qp "Majority.Comparator" $majority_comparator "scalar") (serialize-qp "Majority.ValueToCompare" $majority_value_to_compare "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/Divisions/membervoting" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"MemberId": $member_id, "SearchTerm": $search_term, "IncludeWhenMemberWasTeller": $include_when_member_was_teller, "StartDate": $start_date, "EndDate": $end_date, "DivisionNumber": $division_number, "TotalVotesCast.Comparator": $total_votes_cast_comparator, "TotalVotesCast.ValueToCompare": $total_votes_cast_value_to_compare, "Majority.Comparator": $majority_comparator, "Majority.ValueToCompare": $majority_value_to_compare, "skip": $skip, "take": $take} | compact), body: null}
}

# Return a list of Divisions
#
# GET /data/Divisions/search
export def "data-divisions-search get" [
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
  --search-term: string # Divisions containing search term within title or number (nullable)
  --member-id: int # Divisions returning Member with Member ID voting records (nullable, format: int32)
  --include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted (nullable)
  --start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (nullable, format: int32)
  --total-votes-cast-comparator: string@total-votes-cast-comparator-completer # comparison operator to use
  --total-votes-cast-value-to-compare: int # value to compare to with the operator provided (format: int32)
  --majority-comparator: string@majority-comparator-completer # comparison operator to use
  --majority-value-to-compare: int # value to compare to with the operator provided (format: int32)
  --skip: int # The number of records to skip. Must be a positive integer. Default is 0 (format: int32, default: 0)
  --take: int # The number of records to return per page. Must be more than 0. Default is 25 (format: int32, default: 25)
]: nothing -> table<amendmentMotionNotes: string, authoritativeContentCount: int, authoritativeNotContentCount: int, contentTellers: list<record>, contents: list<record>, date: string, divisionHadTellers: bool, divisionId: int, divisionWasExclusivelyRemote: bool, isGovernmentContent: bool, isGovernmentWin: bool, isHouse: bool, isWhipped: bool, memberContentCount: int, memberNotContentCount: int, notContentTellers: list<record>, notContents: list<record>, notes: string, number: int, remoteVotingEnd: string, remoteVotingStart: string, sponsoringMemberId: int, tellerContentCount: int, tellerNotContentCount: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchTerm" $search_term "scalar") (serialize-qp "MemberId" $member_id "scalar") (serialize-qp "IncludeWhenMemberWasTeller" $include_when_member_was_teller "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "DivisionNumber" $division_number "scalar") (serialize-qp "TotalVotesCast.Comparator" $total_votes_cast_comparator "scalar") (serialize-qp "TotalVotesCast.ValueToCompare" $total_votes_cast_value_to_compare "scalar") (serialize-qp "Majority.Comparator" $majority_comparator "scalar") (serialize-qp "Majority.ValueToCompare" $majority_value_to_compare "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/Divisions/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SearchTerm": $search_term, "MemberId": $member_id, "IncludeWhenMemberWasTeller": $include_when_member_was_teller, "StartDate": $start_date, "EndDate": $end_date, "DivisionNumber": $division_number, "TotalVotesCast.Comparator": $total_votes_cast_comparator, "TotalVotesCast.ValueToCompare": $total_votes_cast_value_to_compare, "Majority.Comparator": $majority_comparator, "Majority.ValueToCompare": $majority_value_to_compare, "skip": $skip, "take": $take} | compact), body: null}
}

# Return total results count
#
# GET /data/Divisions/searchTotalResults
export def "data-divisions-search-total-results get" [
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
  --search-term: string # Divisions containing search term within title or number (nullable)
  --member-id: int # Divisions returning Member with Member ID voting records (nullable, format: int32)
  --include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted (nullable)
  --start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (nullable, format: date-time)
  --division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (nullable, format: int32)
  --total-votes-cast-comparator: string@total-votes-cast-comparator-completer # comparison operator to use
  --total-votes-cast-value-to-compare: int # value to compare to with the operator provided (format: int32)
  --majority-comparator: string@majority-comparator-completer # comparison operator to use
  --majority-value-to-compare: int # value to compare to with the operator provided (format: int32)
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchTerm" $search_term "scalar") (serialize-qp "MemberId" $member_id "scalar") (serialize-qp "IncludeWhenMemberWasTeller" $include_when_member_was_teller "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "DivisionNumber" $division_number "scalar") (serialize-qp "TotalVotesCast.Comparator" $total_votes_cast_comparator "scalar") (serialize-qp "TotalVotesCast.ValueToCompare" $total_votes_cast_value_to_compare "scalar") (serialize-qp "Majority.Comparator" $majority_comparator "scalar") (serialize-qp "Majority.ValueToCompare" $majority_value_to_compare "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/data/Divisions/searchTotalResults" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"SearchTerm": $search_term, "MemberId": $member_id, "IncludeWhenMemberWasTeller": $include_when_member_was_teller, "StartDate": $start_date, "EndDate": $end_date, "DivisionNumber": $division_number, "TotalVotesCast.Comparator": $total_votes_cast_comparator, "TotalVotesCast.ValueToCompare": $total_votes_cast_value_to_compare, "Majority.Comparator": $majority_comparator, "Majority.ValueToCompare": $majority_value_to_compare} | compact), body: null}
}

# Return a Division
#
# GET /data/Divisions/{divisionId}
export def "data-divisions get" [
  division_id: int
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
]: nothing -> record<amendmentMotionNotes: string, authoritativeContentCount: int, authoritativeNotContentCount: int, contentTellers: table<listAs: string, memberFrom: string, memberId: int, name: string, party: string, partyAbbreviation: string, partyColour: string, partyIsMainParty: bool>, contents: table<listAs: string, memberFrom: string, memberId: int, name: string, party: string, partyAbbreviation: string, partyColour: string, partyIsMainParty: bool>, date: string, divisionHadTellers: bool, divisionId: int, divisionWasExclusivelyRemote: bool, isGovernmentContent: bool, isGovernmentWin: bool, isHouse: bool, isWhipped: bool, memberContentCount: int, memberNotContentCount: int, notContentTellers: table<listAs: string, memberFrom: string, memberId: int, name: string, party: string, partyAbbreviation: string, partyColour: string, partyIsMainParty: bool>, notContents: table<listAs: string, memberFrom: string, memberId: int, name: string, party: string, partyAbbreviation: string, partyColour: string, partyIsMainParty: bool>, notes: string, number: int, remoteVotingEnd: string, remoteVotingStart: string, sponsoringMemberId: int, tellerContentCount: int, tellerNotContentCount: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($division_id | is-empty) { error make --unspanned { msg: "path parameter 'divisionId' must be non-empty" } }
  let full_url = (build-url $base ({division_id: (encode-path-segment $division_id)} | format pattern "/data/Divisions/{division_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
