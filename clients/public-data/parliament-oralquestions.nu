# Auto-generated client for House of Commons Oral and Written Questions API vv1
# Source: https://api.apis.guru/v2/specs/parliament.uk/oralquestions/v1/openapi.json
# Auth: --token flag or $env.HOUSE_OF_COMMONS_ORAL_AND_WRITTEN_QUESTIONS_API_TOKEN

const BASE_URL = "http://oralquestionsandmotions-api.parliament.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HOUSE_OF_COMMONS_ORAL_AND_WRITTEN_QUESTIONS_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://oralquestionsandmotions-api.parliament.uk" "https://oralquestionsandmotions-api.parliament.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def parametersorderBy-completer [] { ["DateTabledAsc" "DateTabledDesc" "SignatureCountAsc" "SignatureCountDesc" "TitleAsc" "TitleDesc"] }
def accept-completer-1 [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def parametersquestionType-completer [] { ["Substantive" "Topical"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "early-day-motion Get" } } | get name | first)
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
export def "early-day-motion Get" [
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
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/EarlyDayMotion/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --parametersedmIds: list # Early Day Motions with an ID in the list provided.
  --parametersuINWithAmendmentSuffix: string # Early Day Motions with an UINWithAmendmentSuffix provided.
  --parameterssearchTerm: string # Early Day Motions where the title includes the search term provided.
  --parameterscurrentStatusDateStart: string # Early Day Motions where the current status has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameterscurrentStatusDateEnd: string # Early Day Motions where the current status has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersisPrayer: oneof<nothing, bool> # Early Day Motions which are a prayer against a Negative Statutory Instrument.
  --parametersmemberId: int # Return Early Day Motions tabled by Member with ID provided. (format: int32)
  --parametersincludeSponsoredByMember: oneof<nothing, bool> # Include Early Day Motions sponsored by Member specified
  --parameterstabledStartDate: string # Early Day Motions where the date tabled is on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parameterstabledEndDate: string # Early Day Motions where the date tabled is on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersstatuses: list # Early Day Motions where current status is in the selected list.
  --parametersorderBy: string@parametersorderBy-completer # Order results by date tabled, title or signature count. Default is date tabled.
  --parametersskip: int # The number of records to skip from the first, default is 0. (format: int32)
  --parameterstake: int # The number of records to return, default is 25, maximum is 100. (format: int32)
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters.edmIds" $parametersedmIds "multi") (serialize-qp "parameters.uINWithAmendmentSuffix" $parametersuINWithAmendmentSuffix "scalar") (serialize-qp "parameters.searchTerm" $parameterssearchTerm "scalar") (serialize-qp "parameters.currentStatusDateStart" $parameterscurrentStatusDateStart "scalar") (serialize-qp "parameters.currentStatusDateEnd" $parameterscurrentStatusDateEnd "scalar") (serialize-qp "parameters.isPrayer" $parametersisPrayer "scalar") (serialize-qp "parameters.memberId" $parametersmemberId "scalar") (serialize-qp "parameters.includeSponsoredByMember" $parametersincludeSponsoredByMember "scalar") (serialize-qp "parameters.tabledStartDate" $parameterstabledStartDate "scalar") (serialize-qp "parameters.tabledEndDate" $parameterstabledEndDate "scalar") (serialize-qp "parameters.statuses" $parametersstatuses "multi") (serialize-qp "parameters.orderBy" $parametersorderBy "scalar") (serialize-qp "parameters.skip" $parametersskip "scalar") (serialize-qp "parameters.take" $parameterstake "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EarlyDayMotions/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of oral questions
#
# GET /oralquestions/list
# operationId: PublishedOralQuestion_Get
export def "oralquestions-list Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --parametersansweringDateStart: string # Oral Questions where the answering date has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersansweringDateEnd: string # Oral Questions where the answering date has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersquestionType: string@parametersquestionType-completer # Oral Questions where the question type is the selected type, substantive or topical.
  --parametersoralQuestionTimeId: int # Oral Questions where the question is within the question time with the ID provided (format: int32)
  --parametersaskingMemberIds: list # The ID of the member asking the question. Lists of member IDs for each house are available <a href="http://data.parliament.uk/membersdataplatform/services/mnis/members/query/house=Commons" target="_blank">Commons</a> and <a href="http://data.parliament.uk/membersdataplatform/services/mnis/members/query/house=Lords" target="_blank">Lords</a>.
  --parametersuINs: list # The UIN for the question - note that UINs reset at the start of each Parliamentary session.
  --parametersansweringBodyIds: list # Which answering body is to respond. A list of answering bodies can be found <a target="_blank" href="http://data.parliament.uk/membersdataplatform/services/mnis/referencedata/AnsweringBodies/">here</a>.
  --parametersskip: int # The number of records to skip from the first, default is 0. (format: int32)
  --parameterstake: int # The number of records to return, default is 25, maximum is 100. (format: int32)
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters.answeringDateStart" $parametersansweringDateStart "scalar") (serialize-qp "parameters.answeringDateEnd" $parametersansweringDateEnd "scalar") (serialize-qp "parameters.questionType" $parametersquestionType "scalar") (serialize-qp "parameters.oralQuestionTimeId" $parametersoralQuestionTimeId "scalar") (serialize-qp "parameters.askingMemberIds" $parametersaskingMemberIds "multi") (serialize-qp "parameters.uINs" $parametersuINs "multi") (serialize-qp "parameters.answeringBodyIds" $parametersansweringBodyIds "multi") (serialize-qp "parameters.skip" $parametersskip "scalar") (serialize-qp "parameters.take" $parameterstake "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oralquestions/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of oral question times
#
# GET /oralquestiontimes/list
# operationId: PublishedOralQuestionTime_Get
export def "oralquestiontimes-list Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --parametersansweringDateStart: string # Oral Questions Time where the answering date has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersansweringDateEnd: string # Oral Questions Time where the answering date has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersdeadlineDateStart: string # Oral Questions Time where the deadline date has been set on or after the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersdeadlineDateEnd: string # Oral Questions Time where the deadline date has been set on or before the date provided. Date format YYYY-MM-DD. (format: date-time)
  --parametersoralQuestionTimeId: int # Identifier of the OQT (format: int32)
  --parametersansweringBodyIds: list # Which answering body is to respond. A list of answering bodies can be found <a target="_blank" href="http://data.parliament.uk/membersdataplatform/services/mnis/referencedata/AnsweringBodies/">here</a>.
  --parametersskip: int # The number of records to skip from the first, default is 0. (format: int32)
  --parameterstake: int # The number of records to return, default is 25, maximum is 100. (format: int32)
]: nothing -> record<Errors: list<string>, PagingInfo: record<GlobalStatusCounts: list<record>, GlobalTotal: int, Skip: int, StatusCounts: list<record>, Take: int, Total: int>, Response: table<Answer: string, AnsweredWhen: string, AnsweringBody: string, AnsweringBodyId: int, AnsweringMinister: record, AnsweringMinisterId: int, AnsweringMinisterTitle: string, AskingMember: record, AskingMemberId: int, DueForAnswer: string, Id: int, QuestionText: string, QuestionType: string, TabledWhen: string, UIN: int>, StatusCode: string, Success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters.answeringDateStart" $parametersansweringDateStart "scalar") (serialize-qp "parameters.answeringDateEnd" $parametersansweringDateEnd "scalar") (serialize-qp "parameters.deadlineDateStart" $parametersdeadlineDateStart "scalar") (serialize-qp "parameters.deadlineDateEnd" $parametersdeadlineDateEnd "scalar") (serialize-qp "parameters.oralQuestionTimeId" $parametersoralQuestionTimeId "scalar") (serialize-qp "parameters.answeringBodyIds" $parametersansweringBodyIds "multi") (serialize-qp "parameters.skip" $parametersskip "scalar") (serialize-qp "parameters.take" $parameterstake "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oralquestiontimes/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
