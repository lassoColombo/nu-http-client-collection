# Auto-generated client for Infermedica API vv2
# Source: https://api.apis.guru/v2/specs/infermedica.com/v2/swagger.json
# Auth: --token flag or $env.INFERMEDICA_API_TOKEN

const BASE_URL = "https://api.infermedica.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INFERMEDICA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.infermedica.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def age-unit-completer [] { ["month" "year"] }
def sex-completer [] { ["female" "male"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "concepts list" } } | get name | first)
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

# GET /concepts
#
# operationId: getConcepts
export def "concepts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # ids
  --types: string # types
]: nothing -> table<common_name: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar") (serialize-qp "types" $types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/concepts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# GET /concepts/{id}
#
# operationId: getConcept
export def "concepts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<common_name: string, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/concepts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all conditions
#
# GET /conditions
# operationId: getAllConditions
export def "conditions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --enable-triage-5: oneof<nothing, bool> # enable 5-level triage values
]: nothing -> table<acuteness: string, categories: list<string>, common_name: string, extras: record, id: string, name: string, prevalence: string, severity: string, sex_filter: string, triage_level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "enable_triage_5" $enable_triage_5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conditions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get condition by id
#
# GET /conditions/{id}
# operationId: getCondition
export def "conditions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --enable-triage-5: oneof<nothing, bool> # enable 5-level triage values
]: nothing -> record<acuteness: string, categories: list<string>, common_name: string, extras: record, id: string, name: string, prevalence: string, severity: string, sex_filter: string, triage_level: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "enable_triage_5" $enable_triage_5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conditions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query diagnostic engine
#
# POST /diagnosis
# operationId: computeDiagnosis
# --evidence item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
export def "diagnosis create-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  age: record # e.g. 18
  --evidence: list # item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
  --extras: record
  sex: string@sex-completer
]: any -> record<conditions: table<common_name: string, id: string, name: string, probability: float>, extras: record, question: record<extras: record, items: list<record>, text: string, type: string>, should_stop: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/diagnosis")
  let req_body = {"age": $age, "evidence": $evidence, "extras": $extras, "sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Query diagnostic engine for explanation
#
# POST /explain
# operationId: computeExplanation
# --evidence item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
export def "explain create-compute-explanation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  age: record # e.g. 18
  --evidence: list # item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
  --extras: record
  sex: string@sex-completer
  target: string # target condition id (e.g. c_1)
]: any -> record<conflicting_evidence: table<common_name: string, id: string, name: string>, supporting_evidence: table<common_name: string, id: string, name: string>, unconfirmed_evidence: table<common_name: string, id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/explain")
  let req_body = {"age": $age, "evidence": $evidence, "extras": $extras, "sex": $sex, "target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get database information
#
# GET /info
# operationId: getDatabaseInfo
export def "info get-database" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
]: nothing -> record<api_version: string, conditions_count: int, lab_tests_count: int, risk_factors_count: int, symptoms_count: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all lab tests
#
# GET /lab_tests
# operationId: getAllLabTests
export def "lab-tests get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
]: nothing -> table<category: string, common_name: string, id: string, name: string, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lab_tests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get lab test by id
#
# GET /lab_tests/{id}
# operationId: getLabTest
export def "lab-tests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
]: nothing -> record<category: string, common_name: string, id: string, name: string, results: table<id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/lab_tests/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Find observation matching given phrase
#
# GET /lookup
# operationId: getMatchingObservation
export def "lookup get-matching-observation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # phrase to match
  --sex: string@sex-completer # sex filter
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
]: nothing -> record<id: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phrase" $phrase "scalar") (serialize-qp "sex" $sex "scalar") (serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Find mentions of observations in given text
#
# POST /parse
# operationId: getMentions
export def "parse get-mentions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --concept-types: list<string> # list of concept types that should be captured
  --context: list<string> # ordered list of ids of present symptoms that were already captured and can be used as context
  --correct-spelling: oneof<nothing, bool> # correct spelling of input text before proper analysis
  --include-tokens: oneof<nothing, bool> # include tokenization details in output
  text: string # user text to process
]: any -> record<mentions: table<choice_id: string, common_name: string, head_position: int, id: string, name: string, orth: string, positions: list>, obvious: bool, tokens: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/parse")
  let req_body = {"concept_types": $concept_types, "context": $context, "correct_spelling": $correct_spelling, "include_tokens": $include_tokens, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Query diagnostic engine for question rationale
#
# POST /rationale
# operationId: computeRationale
# --evidence item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
export def "rationale create-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  age: record # e.g. 18
  --evidence: list # item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
  --extras: record
  sex: string@sex-completer
]: any -> record<condition_params: table<common_name: string, id: string, name: string>, observation_params: table<common_name: string, id: string, name: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rationale")
  let req_body = {"age": $age, "evidence": $evidence, "extras": $extras, "sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Query the diagnostic engine for possible red flag symptoms
#
# POST /red_flags
# operationId: computeRedFlags
# --evidence item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
export def "red-flags create-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # maximum number of results (format: int32, default: 8)
  age: record # e.g. 18
  --evidence: list # item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
  --extras: record
  sex: string@sex-completer
]: any -> table<common_name: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/red_flags" $qp)
  let req_body = {"age": $age, "evidence": $evidence, "extras": $extras, "sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List all risk factors
#
# GET /risk_factors
# operationId: getAllRiskFactors
export def "risk-factors get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --enable-triage-5: oneof<nothing, bool> # enable 5-level triage values
]: nothing -> table<category: string, common_name: string, extras: record, id: string, image_source: string, image_url: string, name: string, sex_filter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "enable_triage_5" $enable_triage_5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/risk_factors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get risk factor by id
#
# GET /risk_factors/{id}
# operationId: getRiskFactor
export def "risk-factors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --enable-triage-5: oneof<nothing, bool> # enable 5-level triage values
]: nothing -> record<category: string, common_name: string, extras: record, id: string, image_source: string, image_url: string, name: string, question: string, sex_filter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "enable_triage_5" $enable_triage_5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/risk_factors/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Find observations matching given phrase
#
# GET /search
# operationId: getMatchingObservations
export def "search get-matching-observations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phrase: string # phrase to match
  --sex: string@sex-completer # sex filter
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --max-results: int # maximum number of results (format: int32, default: 8)
  --type: list<string> # type of results
]: nothing -> table<id: string, label: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "phrase" $phrase "scalar") (serialize-qp "sex" $sex "scalar") (serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "type" $type "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query diagnostic engine for related symptoms
#
# POST /suggest
# operationId: getSuggestions
# --evidence item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
export def "suggest get-suggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: int # maximum number of results (format: int32, default: 8)
  --age: record # e.g. 18
  --evidence: list # item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
  --extras: record
  --sex: string@sex-completer
]: any -> table<common_name: string, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_results" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/suggest" $qp)
  let req_body = {"age": $age, "evidence": $evidence, "extras": $extras, "sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List all symptoms
#
# GET /symptoms
# operationId: getAllSymptoms
export def "symptoms get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --enable-triage-5: oneof<nothing, bool> # enable 5-level triage values
]: nothing -> table<category: string, children: record, common_name: string, extras: record, id: string, image_source: string, image_url: string, name: string, parent_id: string, parent_relation: string, sex_filter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "enable_triage_5" $enable_triage_5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/symptoms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get symptoms by id
#
# GET /symptoms/{id}
# operationId: getSymptom
export def "symptoms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --age-value: int # age value (format: int32, e.g. 18)
  --age-unit: string@age-unit-completer # unit in which age value was provided (default: year, e.g. year)
  --enable-triage-5: oneof<nothing, bool> # enable 5-level triage values
]: nothing -> record<category: string, children: record, common_name: string, extras: record, id: string, image_source: string, image_url: string, name: string, parent_id: string, parent_relation: string, question: string, sex_filter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age.value" $age_value "scalar") (serialize-qp "age.unit" $age_unit "scalar") (serialize-qp "enable_triage_5" $enable_triage_5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/symptoms/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query diagnostic engine for triage level
#
# POST /triage
# operationId: computeTriage
# --evidence item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
export def "triage create-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  age: record # e.g. 18
  --evidence: list # item shape: {choice_id: "present"|"absent"|"unknown", id: string, observed_at?: string, source?: "initial"|"suggest"|"predefined"|"red_flags"}
  --extras: record
  sex: string@sex-completer
]: any -> record<root_cause: string, serious: table<common_name: string, id: string, is_emergency: bool, name: string>, teleconsultation_applicable: bool, triage_level: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/triage")
  let req_body = {"age": $age, "evidence": $evidence, "extras": $extras, "sex": $sex} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
