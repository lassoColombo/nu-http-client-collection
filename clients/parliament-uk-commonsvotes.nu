# Auto-generated client for Commons Votes API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/commonsvotes/v1/swagger.json
# Auth: --token flag or $env.COMMONS_VOTES_API_TOKEN

const BASE_URL = "http://commonsvotes-api.parliament.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COMMONS_VOTES_API_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["http://commonsvotes-api.parliament.uk" "https://commonsvotes-api.parliament.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AyeCount: int, AyeTellers: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Ayes: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Date: string, DivisionId: int, DoubleMajorityAyeCount: int, DoubleMajorityNoCount: int, EVELCountry: string, EVELType: string, FriendlyDescription: string, FriendlyTitle: string, IsDeferred: bool, NoCount: int, NoTellers: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, NoVoteRecorded: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Noes: table<ListAs: string, MemberFrom: string, MemberId: int, Name: string, Party: string, PartyAbbreviation: string, PartyColour: string, ProxyName: string, SubParty: string>, Number: int, PublicationUpdated: string, RemoteVotingEnd: string, RemoteVotingStart: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({division_id: $division_id, format: $format} | format pattern "/data/division/{division_id}.{format}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return Divisions results grouped by party
#
# GET /data/divisions.{format}/groupedbyparty
# operationId: Divisions_GetDivisionsGroupsByParty
export def "data-divisions-format-groupedbyparty get-divisions-groups" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let qp = [(serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: $format} | format pattern "/data/divisions.{format}/groupedbyparty") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let qp = [(serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.skip" $query_parameters_skip "scalar") (serialize-qp "queryParameters.take" $query_parameters_take "scalar") (serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: $format} | format pattern "/data/divisions.{format}/membervoting") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let qp = [(serialize-qp "queryParameters.skip" $query_parameters_skip "scalar") (serialize-qp "queryParameters.take" $query_parameters_take "scalar") (serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: $format} | format pattern "/data/divisions.{format}/search") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query-parameters-search-term: string # Divisions containing search term within title or number
  --query-parameters-member-id: int # Divisions returning Member with Member ID voting records (format: int32)
  --query-parameters-include-when-member-was-teller: oneof<nothing, bool> # Divisions where member was a teller as well as if they actually voted
  --query-parameters-start-date: string # Divisions where division date in one or after date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-end-date: string # Divisions where division date in one or before date provided. Date format is yyyy-MM-dd (format: date-time)
  --query-parameters-division-number: int # Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint (format: int32)
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queryParameters.searchTerm" $query_parameters_search_term "scalar") (serialize-qp "queryParameters.memberId" $query_parameters_member_id "scalar") (serialize-qp "queryParameters.includeWhenMemberWasTeller" $query_parameters_include_when_member_was_teller "scalar") (serialize-qp "queryParameters.startDate" $query_parameters_start_date "scalar") (serialize-qp "queryParameters.endDate" $query_parameters_end_date "scalar") (serialize-qp "queryParameters.divisionNumber" $query_parameters_division_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: $format} | format pattern "/data/divisions.{format}/searchTotalResults") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
