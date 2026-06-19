# Auto-generated client for Written Questions Service API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/writtenquestions/v1/openapi.json
# Auth: --token flag or $env.WRITTEN_QUESTIONS_SERVICE_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WRITTEN_QUESTIONS_SERVICE_API_TOKEN | default "" }
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
def house-completer [] { ["Bicameral" "Commons" "Lords"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def answered-completer [] { ["Answered" "Any" "Unanswered"] }
def question-status-completer [] { ["AllQuestions" "AnsweredOnly" "NotAnswered"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dailyreports-dailyreports get" } } | get name | first)
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

# Returns a list of daily reports
#
# GET /api/dailyreports/dailyreports
export def "dailyreports-dailyreports get" [
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
  --date-from: string # Daily report with report date on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --date-to: string # Daily report with report date on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --house: string@house-completer # Daily report relating to the House specified. Defaults to Bicameral
  --skip: int # Number of records to skip, default is 0 (nullable, format: int32)
  --take: int # Number of records to take, default is 20 (nullable, format: int32)
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "house" $house "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dailyreports/dailyreports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"dateFrom": $date_from, "dateTo": $date_to, "house": $house, "skip": $skip, "take": $take} | compact), body: null}
}

# Returns a list of written questions
#
# GET /api/writtenquestions/questions
export def "writtenquestions-questions get" [
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
  --asking-member-id: int # Written questions asked by member with member ID specified (nullable, format: int32)
  --answering-member-id: int # Written questions answered by member with member ID specified (nullable, format: int32)
  --tabled-when-from: string # Written questions tabled on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --tabled-when-to: string # Written questions tabled on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --answered: string@answered-completer # Written questions that have been answered, unanswered or either.
  --answered-when-from: string # Written questions answered on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --answered-when-to: string # Written questions answered on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --question-status: string@question-status-completer # Written questions with the status specified
  --include-withdrawn: oneof<nothing, bool> # Include written questions that have been withdrawn
  --expand-member: oneof<nothing, bool> # Expand the details of Members in the results
  --corrected-when-from: string # Written questions corrected on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --corrected-when-to: string # Written questions corrected on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --search-term: string # Written questions / statements containing the search term specified, searches item content (nullable)
  --u-in: string # Written questions / statements with the uin specified (nullable)
  --answering-bodies: list<int> # Written questions / statements relating to the answering bodies with the IDs specified (nullable)
  --members: list<int> # Written questions / statements relating to the members with the IDs specified (nullable)
  --house: string@house-completer # Written questions / statements relating to the House specified
  --skip: int # Number of records to skip, default is 0 (nullable, format: int32)
  --take: int # Number of records to take, default is 20 (nullable, format: int32)
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "askingMemberId" $asking_member_id "scalar") (serialize-qp "answeringMemberId" $answering_member_id "scalar") (serialize-qp "tabledWhenFrom" $tabled_when_from "scalar") (serialize-qp "tabledWhenTo" $tabled_when_to "scalar") (serialize-qp "answered" $answered "scalar") (serialize-qp "answeredWhenFrom" $answered_when_from "scalar") (serialize-qp "answeredWhenTo" $answered_when_to "scalar") (serialize-qp "questionStatus" $question_status "scalar") (serialize-qp "includeWithdrawn" $include_withdrawn "scalar") (serialize-qp "expandMember" $expand_member "scalar") (serialize-qp "correctedWhenFrom" $corrected_when_from "scalar") (serialize-qp "correctedWhenTo" $corrected_when_to "scalar") (serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "uIN" $u_in "scalar") (serialize-qp "answeringBodies" $answering_bodies "multi") (serialize-qp "members" $members "multi") (serialize-qp "house" $house "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/writtenquestions/questions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"askingMemberId": $asking_member_id, "answeringMemberId": $answering_member_id, "tabledWhenFrom": $tabled_when_from, "tabledWhenTo": $tabled_when_to, "answered": $answered, "answeredWhenFrom": $answered_when_from, "answeredWhenTo": $answered_when_to, "questionStatus": $question_status, "includeWithdrawn": $include_withdrawn, "expandMember": $expand_member, "correctedWhenFrom": $corrected_when_from, "correctedWhenTo": $corrected_when_to, "searchTerm": $search_term, "uIN": $u_in, "answeringBodies": $answering_bodies, "members": $members, "house": $house, "skip": $skip, "take": $take} | compact), body: null}
}

# Returns a written question
#
# GET /api/writtenquestions/questions/{date}/{uin}
export def "writtenquestions-questions get-by-date-uin" [
  date: string
  uin: string
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
  --expand-member: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<answerIsCorrection: bool, answerIsHolding: bool, answerText: string, answeringBodyId: int, answeringBodyName: string, answeringMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, answeringMemberId: int, askingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, askingMemberId: int, attachmentCount: int, attachments: list<record>, comparableAnswerText: string, correctingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, correctingMemberId: int, dateAnswerCorrected: string, dateAnswered: string, dateForAnswer: string, dateHoldingAnswer: string, dateTabled: string, groupedQuestions: list<string>, groupedQuestionsDates: list<record>, heading: string, house: string, id: int, isNamedDay: bool, isWithdrawn: bool, memberHasInterest: bool, originalAnswerText: string, questionText: string, uin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($uin | is-empty) { error make --unspanned { msg: "path parameter 'uin' must be non-empty" } }
  let qp = [(serialize-qp "expandMember" $expand_member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({date: (encode-path-segment $date), uin: (encode-path-segment $uin)} | format pattern "/api/writtenquestions/questions/{date}/{uin}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expandMember": $expand_member} | compact), body: null}
}

# Returns a written question
#
# GET /api/writtenquestions/questions/{id}
export def "writtenquestions-questions get-by-id" [
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
  --expand-member: oneof<nothing, bool> # Expand the details of Members in the result
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<answerIsCorrection: bool, answerIsHolding: bool, answerText: string, answeringBodyId: int, answeringBodyName: string, answeringMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, answeringMemberId: int, askingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, askingMemberId: int, attachmentCount: int, attachments: list<record>, comparableAnswerText: string, correctingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, correctingMemberId: int, dateAnswerCorrected: string, dateAnswered: string, dateForAnswer: string, dateHoldingAnswer: string, dateTabled: string, groupedQuestions: list<string>, groupedQuestionsDates: list<record>, heading: string, house: string, id: int, isNamedDay: bool, isWithdrawn: bool, memberHasInterest: bool, originalAnswerText: string, questionText: string, uin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expandMember" $expand_member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/writtenquestions/questions/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expandMember": $expand_member} | compact), body: null}
}

# Returns a list of written statements
#
# GET /api/writtenstatements/statements
export def "writtenstatements-statements get" [
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
  --made-when-from: string # Written statements made on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --made-when-to: string # Written statements made on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --search-term: string # Written questions / statements containing the search term specified, searches item content (nullable)
  --u-in: string # Written questions / statements with the uin specified (nullable)
  --answering-bodies: list<int> # Written questions / statements relating to the answering bodies with the IDs specified (nullable)
  --members: list<int> # Written questions / statements relating to the members with the IDs specified (nullable)
  --house: string@house-completer # Written questions / statements relating to the House specified
  --skip: int # Number of records to skip, default is 0 (nullable, format: int32)
  --take: int # Number of records to take, default is 20 (nullable, format: int32)
  --expand-member: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "madeWhenFrom" $made_when_from "scalar") (serialize-qp "madeWhenTo" $made_when_to "scalar") (serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "uIN" $u_in "scalar") (serialize-qp "answeringBodies" $answering_bodies "multi") (serialize-qp "members" $members "multi") (serialize-qp "house" $house "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "expandMember" $expand_member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/writtenstatements/statements" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"madeWhenFrom": $made_when_from, "madeWhenTo": $made_when_to, "searchTerm": $search_term, "uIN": $u_in, "answeringBodies": $answering_bodies, "members": $members, "house": $house, "skip": $skip, "take": $take, "expandMember": $expand_member} | compact), body: null}
}

# Returns a written statemnet
#
# GET /api/writtenstatements/statements/{date}/{uin}
export def "writtenstatements-statements get-by-date-uin" [
  date: string
  uin: string
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
  --expand-member: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<answeringBodyId: int, answeringBodyName: string, attachments: list<record>, dateMade: string, hasAttachments: bool, hasLinkedStatements: bool, house: string, id: int, linkedStatements: list<record>, member: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, memberId: int, memberRole: string, noticeNumber: int, text: string, title: string, uin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($uin | is-empty) { error make --unspanned { msg: "path parameter 'uin' must be non-empty" } }
  let qp = [(serialize-qp "expandMember" $expand_member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({date: (encode-path-segment $date), uin: (encode-path-segment $uin)} | format pattern "/api/writtenstatements/statements/{date}/{uin}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expandMember": $expand_member} | compact), body: null}
}

# Returns a written statement
#
# GET /api/writtenstatements/statements/{id}
export def "writtenstatements-statements get-by-id" [
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
  --expand-member: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "expandMember" $expand_member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/writtenstatements/statements/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expandMember": $expand_member} | compact), body: null}
}
