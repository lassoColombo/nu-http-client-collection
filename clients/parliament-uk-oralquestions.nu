# Auto-generated client for House of Commons Oral and Written Questions API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/oralquestions/v1/openapi.json
# Auth: --token flag or $env.HOUSE_OF_COMMONS_ORAL_AND_WRITTEN_QUESTIONS_API_TOKEN

const BASE_URL = "http://oralquestionsandmotions-api.parliament.uk"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o HOUSE_OF_COMMONS_ORAL_AND_WRITTEN_QUESTIONS_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://oralquestionsandmotions-api.parliament.uk" "https://oralquestionsandmotions-api.parliament.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def parameters-order-by-completer [] { ["DateTabledAsc" "DateTabledDesc" "SignatureCountAsc" "SignatureCountDesc" "TitleAsc" "TitleDesc"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def parameters-question-type-completer [] { ["Substantive" "Topical"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "early-day-motion get-published" } } | get name | first)
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

# Returns a single Early Day Motion by ID
#
# GET /EarlyDayMotion/{id}
# operationId: PublishedEarlyDayMotion_Get
export def "early-day-motion get-published" [
  id: int
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
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/EarlyDayMotion/{id}") $auth.query)
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

# Returns a list of Early Day Motions
#
# GET /EarlyDayMotions/list
export def "early-day-motions-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --parameters-edm-ids: list<int> # Early Day Motions with an ID in the list provided.
  --parameters-u-in-with-amendment-suffix: string # Early Day Motions with an UINWithAmendmentSuffix provided.
  --parameters-search-term: string # Early Day Motions where the title includes the search term provided.
  --parameters-current-status-date-start: string # Early Day Motions where the current status has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-current-status-date-end: string # Early Day Motions where the current status has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-is-prayer: oneof<nothing, bool> # Early Day Motions which are a prayer against a Negative Statutory Instrument.
  --parameters-member-id: int # Return Early Day Motions tabled by Member with ID provided. (format: int32)
  --parameters-include-sponsored-by-member: oneof<nothing, bool> # Include Early Day Motions sponsored by Member specified
  --parameters-tabled-start-date: string # Early Day Motions where the date tabled is on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-tabled-end-date: string # Early Day Motions where the date tabled is on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-statuses: list<string> # Early Day Motions where current status is in the selected list.
  --parameters-order-by: string@parameters-order-by-completer # Order results by date tabled, title or signature count. Default is date tabled.
  --parameters-skip: int # The number of records to skip from the first, default is 0. (format: int32)
  --parameters-take: int # The number of records to return, default is 25, maximum is 100. (format: int32)
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters.edmIds" $parameters_edm_ids "multi") (serialize-qp "parameters.uINWithAmendmentSuffix" $parameters_u_in_with_amendment_suffix "scalar") (serialize-qp "parameters.searchTerm" $parameters_search_term "scalar") (serialize-qp "parameters.currentStatusDateStart" $parameters_current_status_date_start "scalar") (serialize-qp "parameters.currentStatusDateEnd" $parameters_current_status_date_end "scalar") (serialize-qp "parameters.isPrayer" $parameters_is_prayer "scalar") (serialize-qp "parameters.memberId" $parameters_member_id "scalar") (serialize-qp "parameters.includeSponsoredByMember" $parameters_include_sponsored_by_member "scalar") (serialize-qp "parameters.tabledStartDate" $parameters_tabled_start_date "scalar") (serialize-qp "parameters.tabledEndDate" $parameters_tabled_end_date "scalar") (serialize-qp "parameters.statuses" $parameters_statuses "multi") (serialize-qp "parameters.orderBy" $parameters_order_by "scalar") (serialize-qp "parameters.skip" $parameters_skip "scalar") (serialize-qp "parameters.take" $parameters_take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EarlyDayMotions/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parameters.edmIds": $parameters_edm_ids, "parameters.uINWithAmendmentSuffix": $parameters_u_in_with_amendment_suffix, "parameters.searchTerm": $parameters_search_term, "parameters.currentStatusDateStart": $parameters_current_status_date_start, "parameters.currentStatusDateEnd": $parameters_current_status_date_end, "parameters.isPrayer": $parameters_is_prayer, "parameters.memberId": $parameters_member_id, "parameters.includeSponsoredByMember": $parameters_include_sponsored_by_member, "parameters.tabledStartDate": $parameters_tabled_start_date, "parameters.tabledEndDate": $parameters_tabled_end_date, "parameters.statuses": $parameters_statuses, "parameters.orderBy": $parameters_order_by, "parameters.skip": $parameters_skip, "parameters.take": $parameters_take} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of oral questions
#
# GET /oralquestions/list
# operationId: PublishedOralQuestion_Get
export def "oralquestions-list get-published-oral-question" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --parameters-answering-date-start: string # Oral Questions where the answering date has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-answering-date-end: string # Oral Questions where the answering date has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-question-type: string@parameters-question-type-completer # Oral Questions where the question type is the selected type, substantive or topical.
  --parameters-oral-question-time-id: int # Oral Questions where the question is within the question time with the ID provided (format: int32)
  --parameters-asking-member-ids: list<int> # The ID of the member asking the question. Lists of member IDs for each house are available Commons (http://data.parliament.uk/membersdataplatform/services/mnis/members/query/house=Commons) and Lords (http://data.parliament.uk/membersdataplatform/services/mnis/members/query/house=Lords).
  --parameters-u-i-ns: list<int> # The UIN for the question - note that UINs reset at the start of each Parliamentary session.
  --parameters-answering-body-ids: list<int> # Which answering body is to respond. A list of answering bodies can be found here (http://data.parliament.uk/membersdataplatform/services/mnis/referencedata/AnsweringBodies/).
  --parameters-skip: int # The number of records to skip from the first, default is 0. (format: int32)
  --parameters-take: int # The number of records to return, default is 25, maximum is 100. (format: int32)
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters.answeringDateStart" $parameters_answering_date_start "scalar") (serialize-qp "parameters.answeringDateEnd" $parameters_answering_date_end "scalar") (serialize-qp "parameters.questionType" $parameters_question_type "scalar") (serialize-qp "parameters.oralQuestionTimeId" $parameters_oral_question_time_id "scalar") (serialize-qp "parameters.askingMemberIds" $parameters_asking_member_ids "multi") (serialize-qp "parameters.uINs" $parameters_u_i_ns "multi") (serialize-qp "parameters.answeringBodyIds" $parameters_answering_body_ids "multi") (serialize-qp "parameters.skip" $parameters_skip "scalar") (serialize-qp "parameters.take" $parameters_take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oralquestions/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parameters.answeringDateStart": $parameters_answering_date_start, "parameters.answeringDateEnd": $parameters_answering_date_end, "parameters.questionType": $parameters_question_type, "parameters.oralQuestionTimeId": $parameters_oral_question_time_id, "parameters.askingMemberIds": $parameters_asking_member_ids, "parameters.uINs": $parameters_u_i_ns, "parameters.answeringBodyIds": $parameters_answering_body_ids, "parameters.skip": $parameters_skip, "parameters.take": $parameters_take} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of oral question times
#
# GET /oralquestiontimes/list
# operationId: PublishedOralQuestionTime_Get
export def "oralquestiontimes-list get-published-oral-question-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --parameters-answering-date-start: string # Oral Questions Time where the answering date has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-answering-date-end: string # Oral Questions Time where the answering date has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-deadline-date-start: string # Oral Questions Time where the deadline date has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-deadline-date-end: string # Oral Questions Time where the deadline date has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameters-oral-question-time-id: int # Identifier of the OQT (format: int32)
  --parameters-answering-body-ids: list<int> # Which answering body is to respond. A list of answering bodies can be found here (http://data.parliament.uk/membersdataplatform/services/mnis/referencedata/AnsweringBodies/).
  --parameters-skip: int # The number of records to skip from the first, default is 0. (format: int32)
  --parameters-take: int # The number of records to return, default is 25, maximum is 100. (format: int32)
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters.answeringDateStart" $parameters_answering_date_start "scalar") (serialize-qp "parameters.answeringDateEnd" $parameters_answering_date_end "scalar") (serialize-qp "parameters.deadlineDateStart" $parameters_deadline_date_start "scalar") (serialize-qp "parameters.deadlineDateEnd" $parameters_deadline_date_end "scalar") (serialize-qp "parameters.oralQuestionTimeId" $parameters_oral_question_time_id "scalar") (serialize-qp "parameters.answeringBodyIds" $parameters_answering_body_ids "multi") (serialize-qp "parameters.skip" $parameters_skip "scalar") (serialize-qp "parameters.take" $parameters_take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oralquestiontimes/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"parameters.answeringDateStart": $parameters_answering_date_start, "parameters.answeringDateEnd": $parameters_answering_date_end, "parameters.deadlineDateStart": $parameters_deadline_date_start, "parameters.deadlineDateEnd": $parameters_deadline_date_end, "parameters.oralQuestionTimeId": $parameters_oral_question_time_id, "parameters.answeringBodyIds": $parameters_answering_body_ids, "parameters.skip": $parameters_skip, "parameters.take": $parameters_take} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
