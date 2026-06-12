# Auto-generated client for Written Questions Service API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/writtenquestions/v1/openapi.json
# Auth: --token flag or $env.WRITTEN_QUESTIONS_SERVICE_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WRITTEN_QUESTIONS_SERVICE_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def house-completer [] { ["Bicameral" "Commons" "Lords"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def answered-completer [] { ["Answered" "Any" "Unanswered"] }
def questionStatus-completer [] { ["AllQuestions" "AnsweredOnly" "NotAnswered"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dateFrom: string # Daily report with report date on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --dateTo: string # Daily report with report date on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --house: string@house-completer # Daily report relating to the House specified. Defaults to Bicameral
  --skip: int # Number of records to skip, default is 0 (nullable, format: int32)
  --take: int # Number of records to take, default is 20 (nullable, format: int32)
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "house" $house "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/dailyreports/dailyreports" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --askingMemberId: int # Written questions asked by member with member ID specified (nullable, format: int32)
  --answeringMemberId: int # Written questions answered by member with member ID specified (nullable, format: int32)
  --tabledWhenFrom: string # Written questions tabled on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --tabledWhenTo: string # Written questions tabled on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --answered: string@answered-completer # Written questions that have been answered, unanswered or either.
  --answeredWhenFrom: string # Written questions answered on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --answeredWhenTo: string # Written questions answered on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --questionStatus: string@questionStatus-completer # Written questions with the status specified
  --includeWithdrawn: oneof<nothing, bool> # Include written questions that have been withdrawn
  --expandMember: oneof<nothing, bool> # Expand the details of Members in the results
  --correctedWhenFrom: string # Written questions corrected on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --correctedWhenTo: string # Written questions corrected on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --searchTerm: string # Written questions / statements containing the search term specified, searches item content (nullable)
  --uIN: string # Written questions / statements with the uin specified (nullable)
  --answeringBodies: list # Written questions / statements relating to the answering bodies with the IDs specified (nullable)
  --members: list # Written questions / statements relating to the members with the IDs specified (nullable)
  --house: string@house-completer # Written questions / statements relating to the House specified
  --skip: int # Number of records to skip, default is 0 (nullable, format: int32)
  --take: int # Number of records to take, default is 20 (nullable, format: int32)
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "askingMemberId" $askingMemberId "scalar") (serialize-qp "answeringMemberId" $answeringMemberId "scalar") (serialize-qp "tabledWhenFrom" $tabledWhenFrom "scalar") (serialize-qp "tabledWhenTo" $tabledWhenTo "scalar") (serialize-qp "answered" $answered "scalar") (serialize-qp "answeredWhenFrom" $answeredWhenFrom "scalar") (serialize-qp "answeredWhenTo" $answeredWhenTo "scalar") (serialize-qp "questionStatus" $questionStatus "scalar") (serialize-qp "includeWithdrawn" $includeWithdrawn "scalar") (serialize-qp "expandMember" $expandMember "scalar") (serialize-qp "correctedWhenFrom" $correctedWhenFrom "scalar") (serialize-qp "correctedWhenTo" $correctedWhenTo "scalar") (serialize-qp "searchTerm" $searchTerm "scalar") (serialize-qp "uIN" $uIN "scalar") (serialize-qp "answeringBodies" $answeringBodies "multi") (serialize-qp "members" $members "multi") (serialize-qp "house" $house "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/writtenquestions/questions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expandMember: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<answerIsCorrection: bool, answerIsHolding: bool, answerText: string, answeringBodyId: int, answeringBodyName: string, answeringMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, answeringMemberId: int, askingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, askingMemberId: int, attachmentCount: int, attachments: list<record>, comparableAnswerText: string, correctingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, correctingMemberId: int, dateAnswerCorrected: string, dateAnswered: string, dateForAnswer: string, dateHoldingAnswer: string, dateTabled: string, groupedQuestions: list<string>, groupedQuestionsDates: list<record>, heading: string, house: string, id: int, isNamedDay: bool, isWithdrawn: bool, memberHasInterest: bool, originalAnswerText: string, questionText: string, uin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expandMember" $expandMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/writtenquestions/questions/($date)/($uin)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expandMember: oneof<nothing, bool> # Expand the details of Members in the result
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<answerIsCorrection: bool, answerIsHolding: bool, answerText: string, answeringBodyId: int, answeringBodyName: string, answeringMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, answeringMemberId: int, askingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, askingMemberId: int, attachmentCount: int, attachments: list<record>, comparableAnswerText: string, correctingMember: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, correctingMemberId: int, dateAnswerCorrected: string, dateAnswered: string, dateForAnswer: string, dateHoldingAnswer: string, dateTabled: string, groupedQuestions: list<string>, groupedQuestionsDates: list<record>, heading: string, house: string, id: int, isNamedDay: bool, isWithdrawn: bool, memberHasInterest: bool, originalAnswerText: string, questionText: string, uin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expandMember" $expandMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/writtenquestions/questions/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --madeWhenFrom: string # Written statements made on or after the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --madeWhenTo: string # Written statements made on or before the date specified. Date format yyyy-mm-dd (nullable, format: date-time)
  --searchTerm: string # Written questions / statements containing the search term specified, searches item content (nullable)
  --uIN: string # Written questions / statements with the uin specified (nullable)
  --answeringBodies: list # Written questions / statements relating to the answering bodies with the IDs specified (nullable)
  --members: list # Written questions / statements relating to the members with the IDs specified (nullable)
  --house: string@house-completer # Written questions / statements relating to the House specified
  --skip: int # Number of records to skip, default is 0 (nullable, format: int32)
  --take: int # Number of records to take, default is 20 (nullable, format: int32)
  --expandMember: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "madeWhenFrom" $madeWhenFrom "scalar") (serialize-qp "madeWhenTo" $madeWhenTo "scalar") (serialize-qp "searchTerm" $searchTerm "scalar") (serialize-qp "uIN" $uIN "scalar") (serialize-qp "answeringBodies" $answeringBodies "multi") (serialize-qp "members" $members "multi") (serialize-qp "house" $house "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "take" $take "scalar") (serialize-qp "expandMember" $expandMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/writtenstatements/statements" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expandMember: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<links: table<href: string, method: string, rel: string>, value: record<answeringBodyId: int, answeringBodyName: string, attachments: list<record>, dateMade: string, hasAttachments: bool, hasLinkedStatements: bool, house: string, id: int, linkedStatements: list<record>, member: record<id: int, listAs: string, memberFrom: string, name: string, party: string, partyAbbreviation: string, partyColour: string, thumbnailUrl: string>, memberId: int, memberRole: string, noticeNumber: int, text: string, title: string, uin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expandMember" $expandMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/writtenstatements/statements/($date)/($uin)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expandMember: oneof<nothing, bool> # Expand the details of Members in the results
]: nothing -> record<results: table<links: list, value: record>, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expandMember" $expandMember "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/writtenstatements/statements/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
