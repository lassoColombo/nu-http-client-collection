# Auto-generated client for NamSor API v2 v2.0.24
# Source: https://api.apis.guru/v2/specs/namsor.com/2.0.24/openapi.json
# Auth: --token flag or $env.NAMSOR_API_V2_TOKEN

const BASE_URL = "https://v2.namsor.com/NamSorAPIv2"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NAMSOR_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-KEY: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://v2.namsor.com/NamSorAPIv2"] }
def auth-scheme-completer [] { ["x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api2-json-anonymize anonymize" } } | get name | first)
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

# Activate/deactivate anonymization for a source.
#
# GET /api2/json/anonymize/{source}/{anonymized}/{token}
# operationId: anonymize
export def "api2-json-anonymize anonymize" [
  source: string
  anonymized: bool
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({source: $source, anonymized: $anonymized, token_arg: $token_arg} | format pattern "/api2/json/anonymize/{source}/{anonymized}/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read API Key info.
#
# GET /api2/json/apiKeyInfo
# operationId: apiKeyInfo
export def "api2-json-api-key-info apiKeyInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/apiKeyInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of classification services and usage cost in Units per classification (default is 1=ONE Unit). Some API endpoints (ex. Corridor) combine multiple classifiers.
#
# GET /api2/json/apiServices
# operationId: availableServices
export def "api2-json-api-services availableServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiServices: table<costInUnits: int, serviceGroup: string, serviceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/apiServices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Prints the current status of the classifiers. A classifier name in apiStatus corresponds to a service name in apiServices.
#
# GET /api2/json/apiStatus
# operationId: apiStatus
export def "api2-json-api-status apiStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<classifiers: table<classifierName: string, learning: bool, probabilityCalibrated: bool, serving: bool, shuttingDown: bool>, softwareVersion: record<softwareNameAndVersion: string, softwareVersion: list<int>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/apiStatus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Print current API usage.
#
# GET /api2/json/apiUsage
# operationId: apiUsage
export def "api2-json-api-usage apiUsage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billingPeriod: record<apiKey: string, billingStatus: string, hardLimit: int, periodEnded: int, periodStarted: int, softLimit: int, stripeCurrentPeriodEnd: int, stripeCurrentPeriodStart: int, subscriptionStarted: int, usage: int>, overageCurrency: string, overageExclTax: float, overageInclTax: float, overageQuantity: int, subscription: record<apiKey: string, currency: string, currencyFactor: float, planBaseFeesKey: string, planEnded: int, planName: string, planQuota: int, planStarted: int, planStatus: string, price: float, priceOverage: float, priceOverageUSD: float, priceUSD: float, priorPlanStarted: int, stripeCustomerId: string, stripeStatus: string, stripeSubscription: string, taxRate: float, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/apiUsage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Print historical API usage.
#
# GET /api2/json/apiUsageHistory
# operationId: apiUsageHistory
export def "api2-json-api-usage-history apiUsageHistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<detailedUsage: table<apiKey: record, apiService: string, createdDateTime: int, hostAddress: string, lastFlushedDateTime: int, lastUsedDateTime: int, serviceFeaturesUsage: record, totalUsage: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/apiUsageHistory")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Print historical API usage (in an aggregated view, by service, by day/hour/min).
#
# GET /api2/json/apiUsageHistoryAggregate
# operationId: apiUsageHistoryAggregate
export def "api2-json-api-usage-history-aggregate apiUsageHistoryAggregate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<colHeaders: list<string>, data: list<list<int>>, historyTruncated: bool, periodEnd: int, periodStart: int, rowHeaders: list<string>, timeUnit: string, totalUsage: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/apiUsageHistoryAggregate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely Indian name castegroup of a personal full name.
#
# GET /api2/json/castegroupIndianFull/{subDivisionIso31662}/{personalNameFull}
# operationId: castegroupIndianFull
export def "api2-json-castegroup-indian-full castegroupIndianFull" [
  sub_division_iso31662: string
  personal_name_full: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<castegroup: string, castegroupAlt: string, castegroupTop: list<string>, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_division_iso31662: $sub_division_iso31662, personal_name_full: $personal_name_full} | format pattern "/api2/json/castegroupIndianFull/{sub_division_iso31662}/{personal_name_full}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely Indian name castegroup of up to 100 personal full names. 
#
# POST /api2/json/castegroupIndianFullBatch
# operationId: castegroupIndianFullBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string, subdivisionIso?: string}
export def "api2-json-castegroup-indian-full-batch castegroupIndianFullBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string, subdivisionIso?: string}
]: any -> record<personalNames: table<castegroup: string, castegroupAlt: string, castegroupTop: list, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/castegroupIndianFullBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Identify Chinese name candidates, based on the romanized name ex. Wang Xiaoming
#
# GET /api2/json/chineseNameCandidates/{chineseSurnameLatin}/{chineseGivenNameLatin}
# operationId: chineseNameCandidates
export def "api2-json-chinese-name-candidates chineseNameCandidates" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin} | format pattern "/api2/json/chineseNameCandidates/{chinese_surname_latin}/{chinese_given_name_latin}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Identify Chinese name candidates, based on the romanized name (firstName = chineseGivenName; lastName=chineseSurname), ex. Wang Xiaoming
#
# POST /api2/json/chineseNameCandidatesBatch
# operationId: chineseNameCandidatesBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-chinese-name-candidates-batch chineseNameCandidatesBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/chineseNameCandidatesBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Identify Chinese name candidates, based on the romanized name (firstName = chineseGivenName; lastName=chineseSurname) ex. Wang Xiaoming.
#
# POST /api2/json/chineseNameCandidatesGenderBatch
# operationId: chineseNameCandidatesGenderBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, gender?: string, id?: string, lastName?: string}
export def "api2-json-chinese-name-candidates-gender-batch chineseNameCandidatesGenderBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, gender?: string, id?: string, lastName?: string}
]: any -> record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/chineseNameCandidatesGenderBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Identify Chinese name candidates, based on the romanized name ex. Wang Xiaoming - having a known gender ('male' or 'female')
#
# GET /api2/json/chineseNameGenderCandidates/{chineseSurnameLatin}/{chineseGivenNameLatin}/{knownGender}
# operationId: chineseNameGenderCandidates
export def "api2-json-chinese-name-gender-candidates chineseNameGenderCandidates" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
  known_gender: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin, known_gender: $known_gender} | format pattern "/api2/json/chineseNameGenderCandidates/{chinese_surname_latin}/{chinese_given_name_latin}/{known_gender}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a score for matching Chinese name ex. 王晓明 with a romanized name ex. Wang Xiaoming
#
# GET /api2/json/chineseNameMatch/{chineseSurnameLatin}/{chineseGivenNameLatin}/{chineseName}
# operationId: chineseNameMatch
export def "api2-json-chinese-name-match chineseNameMatch" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
  chinese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, matchStatus: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin, chinese_name: $chinese_name} | format pattern "/api2/json/chineseNameMatch/{chinese_surname_latin}/{chinese_given_name_latin}/{chinese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Identify Chinese name candidates, based on the romanized name (firstName = chineseGivenName; lastName=chineseSurname), ex. Wang Xiaoming
#
# POST /api2/json/chineseNameMatchBatch
# operationId: chineseNameMatchBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name1?: record, name2?: record}
export def "api2-json-chinese-name-match-batch chineseNameMatchBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name1?: record, name2?: record}
]: any -> record<matchedNames: table<id: string, matchStatus: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/chineseNameMatchBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 20 UNITS PER NAME COUPLE] Infer several classifications for a cross border interaction between names (ex. remit, travel, intl com)
#
# GET /api2/json/corridor/{countryIso2From}/{firstNameFrom}/{lastNameFrom}/{countryIso2To}/{firstNameTo}/{lastNameTo}
# operationId: corridor
export def "api2-json-corridor corridor" [
  country_iso2_from: string
  first_name_from: string
  last_name_from: string
  country_iso2_to: string
  first_name_to: string
  last_name_to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<FirstLastNameDiasporaedOut: record<countryIso2: string, ethnicitiesTop: list<string>, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>, FirstLastNameGenderedOut: record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>, FirstLastNameOriginedOut: record<countriesOriginTop: list<string>, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>, id: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_iso2_from: $country_iso2_from, first_name_from: $first_name_from, last_name_from: $last_name_from, country_iso2_to: $country_iso2_to, first_name_to: $first_name_to, last_name_to: $last_name_to} | format pattern "/api2/json/corridor/{country_iso2_from}/{first_name_from}/{last_name_from}/{country_iso2_to}/{first_name_to}/{last_name_to}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 20 UNITS PER NAME PAIR] Infer several classifications for up to 100 cross border interaction between names (ex. remit, travel, intl com)
#
# POST /api2/json/corridorBatch
# operationId: corridorBatch
# --corridorFromTo item shape: {firstLastNameGeoFrom?: record, firstLastNameGeoTo?: record, id?: string}
# --facts item shape: {id?: string, name?: string}
export def "api2-json-corridor-batch corridorBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --corridor-from-to: list # item shape: {firstLastNameGeoFrom?: record, firstLastNameGeoTo?: record, id?: string}
  --facts: list # item shape: {id?: string, name?: string}
]: any -> record<corridorFromTo: table<FirstLastNameDiasporaedOut: record, FirstLastNameGenderedOut: record, FirstLastNameOriginedOut: record, id: string, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/corridorBatch")
  let body = {"corridorFromTo": $corridor_from_to, "facts": $facts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 10 UNITS PER NAME] Infer the likely country of residence of a personal full name, or one surname. Assumes names as they are in the country of residence OR the country of origin.
#
# GET /api2/json/country/{personalNameFull}
# operationId: country
export def "api2-json-country country" [
  personal_name_full: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countriesTop: list<string>, country: string, countryAlt: string, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, region: string, score: float, script: string, subRegion: string, topRegion: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({personal_name_full: $personal_name_full} | format pattern "/api2/json/country/{personal_name_full}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely country of residence of up to 100 personal full names, or surnames. Assumes names as they are in the country of residence OR the country of origin.
#
# POST /api2/json/countryBatch
# operationId: countryBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-country-batch countryBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<countriesTop: list, country: string, countryAlt: string, id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, region: string, score: float, script: string, subRegion: string, topRegion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/countryBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 20 UNITS PER NAME] Infer the likely ethnicity/diaspora of a personal name, given a country of residence ISO2 code (ex. US, CA, AU, NZ etc.)
#
# GET /api2/json/diaspora/{countryIso2}/{firstName}/{lastName}
# operationId: diaspora
export def "api2-json-diaspora diaspora" [
  country_iso2: string
  first_name: string
  last_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryIso2: string, ethnicitiesTop: list<string>, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_iso2: $country_iso2, first_name: $first_name, last_name: $last_name} | format pattern "/api2/json/diaspora/{country_iso2}/{first_name}/{last_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 20 UNITS PER NAME] Infer the likely ethnicity/diaspora of up to 100 personal names, given a country of residence ISO2 code (ex. US, CA, AU, NZ etc.)
#
# POST /api2/json/diasporaBatch
# operationId: diasporaBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
export def "api2-json-diaspora-batch diasporaBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<countryIso2: string, ethnicitiesTop: list, ethnicity: string, ethnicityAlt: string, firstName: string, id: string, lastName: string, lifted: bool, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/diasporaBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a just a fiven name, assuming default 'US' local context. Please use preferably full names and local geographic context for better accuracy.
#
# GET /api2/json/gender/{firstName}
# operationId: gender
export def "api2-json-gender gender" [
  first_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name} | format pattern "/api2/json/gender/{first_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of a name.
#
# GET /api2/json/gender/{firstName}/{lastName}
# operationId: gender_1
export def "api2-json-gender gender-by-firstName-lastName" [
  first_name: string
  last_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name} | format pattern "/api2/json/gender/{first_name}/{last_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 names, detecting automatically the cultural context.
#
# POST /api2/json/genderBatch
# operationId: genderBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-gender-batch genderBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a Chinese full name ex. 王晓明
#
# GET /api2/json/genderChineseName/{chineseName}
# operationId: genderChineseName
export def "api2-json-gender-chinese-name genderChineseName" [
  chinese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_name: $chinese_name} | format pattern "/api2/json/genderChineseName/{chinese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 full names ex. 王晓明
#
# POST /api2/json/genderChineseNameBatch
# operationId: genderChineseNameBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-gender-chinese-name-batch genderChineseNameBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderChineseNameBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a Chinese name in LATIN (Pinyin).
#
# GET /api2/json/genderChineseNamePinyin/{chineseSurnameLatin}/{chineseGivenNameLatin}
# operationId: genderChineseNamePinyin
export def "api2-json-gender-chinese-name-pinyin genderChineseNamePinyin" [
  chinese_surname_latin: string
  chinese_given_name_latin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_surname_latin: $chinese_surname_latin, chinese_given_name_latin: $chinese_given_name_latin} | format pattern "/api2/json/genderChineseNamePinyin/{chinese_surname_latin}/{chinese_given_name_latin}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 Chinese names in LATIN (Pinyin).
#
# POST /api2/json/genderChineseNamePinyinBatch
# operationId: genderChineseNamePinyinBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-gender-chinese-name-pinyin-batch genderChineseNamePinyinBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderChineseNamePinyinBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a full name, ex. John H. Smith
#
# GET /api2/json/genderFull/{fullName}
# operationId: genderFull
export def "api2-json-gender-full genderFull" [
  full_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({full_name: $full_name} | format pattern "/api2/json/genderFull/{full_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 full names, detecting automatically the cultural context.
#
# POST /api2/json/genderFullBatch
# operationId: genderFullBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-gender-full-batch genderFullBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderFullBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a full name, given a local context (ISO2 country code).
#
# GET /api2/json/genderFullGeo/{fullName}/{countryIso2}
# operationId: genderFullGeo
export def "api2-json-gender-full-geo genderFullGeo" [
  full_name: string
  country_iso2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({full_name: $full_name, country_iso2: $country_iso2} | format pattern "/api2/json/genderFullGeo/{full_name}/{country_iso2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 full names, with a given cultural context (country ISO2 code).
#
# POST /api2/json/genderFullGeoBatch
# operationId: genderFullGeoBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, id?: string, name?: string}
export def "api2-json-gender-full-geo-batch genderFullGeoBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, id?: string, name?: string}
]: any -> record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderFullGeoBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a name, given a local context (ISO2 country code).
#
# GET /api2/json/genderGeo/{firstName}/{lastName}/{countryIso2}
# operationId: genderGeo
export def "api2-json-gender-geo genderGeo" [
  first_name: string
  last_name: string
  country_iso2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name, country_iso2: $country_iso2} | format pattern "/api2/json/genderGeo/{first_name}/{last_name}/{country_iso2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 names, each given a local context (ISO2 country code).
#
# POST /api2/json/genderGeoBatch
# operationId: genderGeoBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
export def "api2-json-gender-geo-batch genderGeoBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderGeoBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a Japanese name in LATIN (Pinyin).
#
# GET /api2/json/genderJapaneseName/{japaneseSurname}/{japaneseGivenName}
# operationId: genderJapaneseNamePinyin
export def "api2-json-gender-japanese-name genderJapaneseNamePinyin" [
  japanese_surname: string
  japanese_given_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_surname: $japanese_surname, japanese_given_name: $japanese_given_name} | format pattern "/api2/json/genderJapaneseName/{japanese_surname}/{japanese_given_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 Japanese names in LATIN (Pinyin).
#
# POST /api2/json/genderJapaneseNameBatch
# operationId: genderJapaneseNamePinyinBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-gender-japanese-name-batch genderJapaneseNamePinyinBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<firstName: string, genderScale: float, id: string, lastName: string, likelyGender: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderJapaneseNameBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely gender of a Japanese full name ex. 王晓明
#
# GET /api2/json/genderJapaneseNameFull/{japaneseName}
# operationId: genderJapaneseNameFull
export def "api2-json-gender-japanese-name-full genderJapaneseNameFull" [
  japanese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_name: $japanese_name} | format pattern "/api2/json/genderJapaneseNameFull/{japanese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely gender of up to 100 full names
#
# POST /api2/json/genderJapaneseNameFullBatch
# operationId: genderJapaneseNameFullBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-gender-japanese-name-full-batch genderJapaneseNameFullBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<genderScale: float, id: string, likelyGender: string, name: string, probabilityCalibrated: float, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/genderJapaneseNameFullBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Identify japanese name candidates in KANJI, based on the romanized name (firstName = japaneseGivenName; lastName=japaneseSurname) with KNOWN gender, ex. Yamamoto Sanae
#
# POST /api2/json/japaneseNameGenderKanjiCandidatesBatch
# operationId: japaneseNameGenderKanjiCandidatesBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, gender?: string, id?: string, lastName?: string}
export def "api2-json-japanese-name-gender-kanji-candidates-batch japaneseNameGenderKanjiCandidatesBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, gender?: string, id?: string, lastName?: string}
]: any -> record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/japaneseNameGenderKanjiCandidatesBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Identify japanese name candidates in KANJI, based on the romanized name ex. Yamamoto Sanae
#
# GET /api2/json/japaneseNameKanjiCandidates/{japaneseSurnameLatin}/{japaneseGivenNameLatin}
# operationId: japaneseNameKanjiCandidates
export def "api2-json-japanese-name-kanji-candidates japaneseNameKanjiCandidates" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin} | format pattern "/api2/json/japaneseNameKanjiCandidates/{japanese_surname_latin}/{japanese_given_name_latin}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Identify japanese name candidates in KANJI, based on the romanized name ex. Yamamoto Sanae - and a known gender.
#
# GET /api2/json/japaneseNameKanjiCandidates/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{knownGender}
# operationId: japaneseNameKanjiCandidates_1
export def "api2-json-japanese-name-kanji-candidates japaneseNameKanjiCandidates-by-japaneseSurnameLatin-japaneseGivenNameLatin-knownGender" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  known_gender: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin, known_gender: $known_gender} | format pattern "/api2/json/japaneseNameKanjiCandidates/{japanese_surname_latin}/{japanese_given_name_latin}/{known_gender}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Identify japanese name candidates in KANJI, based on the romanized name (firstName = japaneseGivenName; lastName=japaneseSurname), ex. Yamamoto Sanae
#
# POST /api2/json/japaneseNameKanjiCandidatesBatch
# operationId: japaneseNameKanjiCandidatesBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-japanese-name-kanji-candidates-batch japaneseNameKanjiCandidatesBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/japaneseNameKanjiCandidatesBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Romanize japanese name, based on the name in Kanji.
#
# GET /api2/json/japaneseNameLatinCandidates/{japaneseSurnameKanji}/{japaneseGivenNameKanji}
# operationId: japaneseNameLatinCandidates
export def "api2-json-japanese-name-latin-candidates japaneseNameLatinCandidates" [
  japanese_surname_kanji: string
  japanese_given_name_kanji: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, matchCandidates: table<candidateName: string, predScoreFamilyName: float, predScoreGivenName: float, probability: float>, orderOption: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_surname_kanji: $japanese_surname_kanji, japanese_given_name_kanji: $japanese_given_name_kanji} | format pattern "/api2/json/japaneseNameLatinCandidates/{japanese_surname_kanji}/{japanese_given_name_kanji}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Romanize japanese names, based on the name in KANJI
#
# POST /api2/json/japaneseNameLatinCandidatesBatch
# operationId: japaneseNameLatinCandidatesBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-japanese-name-latin-candidates-batch japaneseNameLatinCandidatesBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<namesAndMatchCandidates: table<firstName: string, id: string, lastName: string, matchCandidates: list, orderOption: string, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/japaneseNameLatinCandidatesBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return a score for matching Japanese name in KANJI ex. 山本 早苗 with a romanized name ex. Yamamoto Sanae
#
# GET /api2/json/japaneseNameMatch/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{japaneseName}
# operationId: japaneseNameMatch
export def "api2-json-japanese-name-match japaneseNameMatch" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  japanese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, matchStatus: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin, japanese_name: $japanese_name} | format pattern "/api2/json/japaneseNameMatch/{japanese_surname_latin}/{japanese_given_name_latin}/{japanese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a score for matching a list of Japanese names in KANJI ex. 山本 早苗 with romanized names ex. Yamamoto Sanae
#
# POST /api2/json/japaneseNameMatchBatch
# operationId: japaneseNameMatchBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name1?: record, name2?: record}
export def "api2-json-japanese-name-match-batch japaneseNameMatchBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name1?: record, name2?: record}
]: any -> record<matchedNames: table<id: string, matchStatus: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/japaneseNameMatchBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [CREDITS 1 UNIT] Feedback loop to better perform matching Japanese name in KANJI ex. 山本 早苗 with a romanized name ex. Yamamoto Sanae
#
# GET /api2/json/japaneseNameMatchFeedbackLoop/{japaneseSurnameLatin}/{japaneseGivenNameLatin}/{japaneseName}
# operationId: japaneseNameMatchFeedbackLoop
export def "api2-json-japanese-name-match-feedback-loop japaneseNameMatchFeedbackLoop" [
  japanese_surname_latin: string
  japanese_given_name_latin: string
  japanese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<feedbackCredits: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_surname_latin: $japanese_surname_latin, japanese_given_name_latin: $japanese_given_name_latin, japanese_name: $japanese_name} | format pattern "/api2/json/japaneseNameMatchFeedbackLoop/{japanese_surname_latin}/{japanese_given_name_latin}/{japanese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate/deactivate learning from a source.
#
# GET /api2/json/learnable/{source}/{learnable}/{token}
# operationId: learnable
export def "api2-json-learnable learnable" [
  source: string
  learnable: bool
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: bool, anonymized: bool, apiKey: string, corporate: bool, disabled: bool, learnable: bool, partner: bool, striped: bool, userId: string, vetted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({source: $source, learnable: $learnable, token_arg: $token_arg} | format pattern "/api2/json/learnable/{source}/{learnable}/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely type of a proper noun (personal name, brand name, place name etc.)
#
# GET /api2/json/nameType/{properNoun}
# operationId: nameType
export def "api2-json-name-type nameType" [
  proper_noun: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({proper_noun: $proper_noun} | format pattern "/api2/json/nameType/{proper_noun}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely common type of up to 100 proper nouns (personal name, brand name, place name etc.)
#
# POST /api2/json/nameTypeBatch
# operationId: nameTypeBatch
# --facts item shape: {id?: string, name?: string}
# --properNouns item shape: {id?: string, name?: string}
export def "api2-json-name-type-batch nameTypeBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --proper-nouns: list # item shape: {id?: string, name?: string}
]: any -> record<properNouns: table<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/nameTypeBatch")
  let body = {"facts": $facts, "properNouns": $proper_nouns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely type of a proper noun (personal name, brand name, place name etc.)
#
# GET /api2/json/nameTypeGeo/{properNoun}/{countryIso2}
# operationId: nameTypeGeo
export def "api2-json-name-type-geo nameTypeGeo" [
  proper_noun: string
  country_iso2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({proper_noun: $proper_noun, country_iso2: $country_iso2} | format pattern "/api2/json/nameTypeGeo/{proper_noun}/{country_iso2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely common type of up to 100 proper nouns (personal name, brand name, place name etc.)
#
# POST /api2/json/nameTypeGeoBatch
# operationId: nameTypeGeoBatch
# --facts item shape: {id?: string, name?: string}
# --properNouns item shape: {countryIso2?: string, id?: string, name?: string}
export def "api2-json-name-type-geo-batch nameTypeGeoBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --proper-nouns: list # item shape: {countryIso2?: string, id?: string, name?: string}
]: any -> record<properNouns: table<commonType: string, commonTypeAlt: string, id: string, name: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/nameTypeGeoBatch")
  let body = {"facts": $facts, "properNouns": $proper_nouns} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 10 UNITS PER NAME] Infer the likely country of origin of a personal name. Assumes names as they are in the country of origin. For US, CA, AU, NZ and other melting-pots : use 'diaspora' instead.
#
# GET /api2/json/origin/{firstName}/{lastName}
# operationId: origin
export def "api2-json-origin origin" [
  first_name: string
  last_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countriesOriginTop: list<string>, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name} | format pattern "/api2/json/origin/{first_name}/{last_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely country of origin of up to 100 names, detecting automatically the cultural context.
#
# POST /api2/json/originBatch
# operationId: originBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {firstName?: string, id?: string, lastName?: string}
export def "api2-json-origin-batch originBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<countriesOriginTop: list, countryOrigin: string, countryOriginAlt: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, regionOrigin: string, score: float, script: string, subRegionOrigin: string, topRegionOrigin: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/originBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely first/last name structure of a name, ex. 王晓明 -> 王(surname) 晓明(given name)
#
# GET /api2/json/parseChineseName/{chineseName}
# operationId: parseChineseName
export def "api2-json-parse-chinese-name parseChineseName" [
  chinese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_name: $chinese_name} | format pattern "/api2/json/parseChineseName/{chinese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely first/last name structure of a name, ex. 王晓明 -> 王(surname) 晓明(given name).
#
# POST /api2/json/parseChineseNameBatch
# operationId: parseChineseNameBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-parse-chinese-name-batch parseChineseNameBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/parseChineseNameBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely first/last name structure of a name, ex. 山本 早苗 or Yamamoto Sanae
#
# GET /api2/json/parseJapaneseName/{japaneseName}
# operationId: parseJapaneseName
export def "api2-json-parse-japanese-name parseJapaneseName" [
  japanese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({japanese_name: $japanese_name} | format pattern "/api2/json/parseJapaneseName/{japanese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely first/last name structure of a name, ex. 山本 早苗 or Yamamoto Sanae 
#
# POST /api2/json/parseJapaneseNameBatch
# operationId: parseJapaneseNameBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-parse-japanese-name-batch parseJapaneseNameBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/parseJapaneseNameBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John. 
#
# GET /api2/json/parseName/{nameFull}
# operationId: parseName
export def "api2-json-parse-name parseName" [
  name_full: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name_full: $name_full} | format pattern "/api2/json/parseName/{name_full}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John. For better accuracy, provide a geographic context.
#
# GET /api2/json/parseName/{nameFull}/{countryIso2}
# operationId: parseNameGeo
export def "api2-json-parse-name parseNameGeo" [
  name_full: string
  country_iso2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name_full: $name_full, country_iso2: $country_iso2} | format pattern "/api2/json/parseName/{name_full}/{country_iso2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John.
#
# POST /api2/json/parseNameBatch
# operationId: parseNameBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-parse-name-batch parseNameBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/parseNameBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Infer the likely first/last name structure of a name, ex. John Smith or SMITH, John or SMITH; John. Giving a local context improves precision. 
#
# POST /api2/json/parseNameGeoBatch
# operationId: parseNameGeoBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, id?: string, name?: string}
export def "api2-json-parse-name-geo-batch parseNameGeoBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, id?: string, name?: string}
]: any -> record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/parseNameGeoBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 11 UNITS PER NAME] Infer the likely country and phone prefix, given a personal name and formatted / unformatted phone number.
#
# GET /api2/json/phoneCode/{firstName}/{lastName}/{phoneNumber}
# operationId: phoneCode
export def "api2-json-phone-code phoneCode" [
  first_name: string
  last_name: string
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name, phone_number: $phone_number} | format pattern "/api2/json/phoneCode/{first_name}/{last_name}/{phone_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 11 UNITS PER NAME] Infer the likely country and phone prefix, of up to 100 personal names, detecting automatically the local context given a name and formatted / unformatted phone number.
#
# POST /api2/json/phoneCodeBatch
# operationId: phoneCodeBatch
# --facts item shape: {id?: string, name?: string}
# --personalNamesWithPhoneNumbers item shape: {firstName?: string, id?: string, lastName?: string, phoneNumber?: string}
export def "api2-json-phone-code-batch phoneCodeBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names-with-phone-numbers: list # item shape: {firstName?: string, id?: string, lastName?: string, phoneNumber?: string}
]: any -> record<personalNamesWithPhoneNumbers: table<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/phoneCodeBatch")
  let body = {"facts": $facts, "personalNamesWithPhoneNumbers": $personal_names_with_phone_numbers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 11 UNITS PER NAME] Infer the likely phone prefix, given a personal name and formatted / unformatted phone number, with a local context (ISO2 country of residence).
#
# GET /api2/json/phoneCodeGeo/{firstName}/{lastName}/{phoneNumber}/{countryIso2}
# operationId: phoneCodeGeo
export def "api2-json-phone-code-geo phoneCodeGeo" [
  first_name: string
  last_name: string
  phone_number: string
  country_iso2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name, phone_number: $phone_number, country_iso2: $country_iso2} | format pattern "/api2/json/phoneCodeGeo/{first_name}/{last_name}/{phone_number}/{country_iso2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 11 UNITS PER NAME] Infer the likely country and phone prefix, of up to 100 personal names, with a local context (ISO2 country of residence).
#
# POST /api2/json/phoneCodeGeoBatch
# operationId: phoneCodeGeoBatch
# --facts item shape: {id?: string, name?: string}
# --personalNamesWithPhoneNumbers item shape: {countryIso2?: string, countryIso2Alt?: string, firstName?: string, id?: string, lastName?: string, phoneNumber?: string}
export def "api2-json-phone-code-geo-batch phoneCodeGeoBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names-with-phone-numbers: list # item shape: {countryIso2?: string, countryIso2Alt?: string, firstName?: string, id?: string, lastName?: string, phoneNumber?: string}
]: any -> record<personalNamesWithPhoneNumbers: table<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/phoneCodeGeoBatch")
  let body = {"facts": $facts, "personalNamesWithPhoneNumbers": $personal_names_with_phone_numbers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [CREDITS 1 UNIT] Feedback loop to better infer the likely phone prefix, given a personal name and formatted / unformatted phone number, with a local context (ISO2 country of residence).
#
# GET /api2/json/phoneCodeGeoFeedbackLoop/{firstName}/{lastName}/{phoneNumber}/{phoneNumberE164}/{countryIso2}
# operationId: phoneCodeGeoFeedbackLoop
export def "api2-json-phone-code-geo-feedback-loop phoneCodeGeoFeedbackLoop" [
  first_name: string
  last_name: string
  phone_number: string
  phone_number_e164: string
  country_iso2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryIso2: string, firstName: string, id: string, internationalPhoneNumberVerified: string, lastName: string, originCountryIso2: string, originCountryIso2Alt: string, phoneCountryCode: int, phoneCountryCodeAlt: int, phoneCountryIso2: string, phoneCountryIso2Alt: string, phoneCountryIso2Verified: string, phoneNumber: string, score: float, script: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name, phone_number: $phone_number, phone_number_e164: $phone_number_e164, country_iso2: $country_iso2} | format pattern "/api2/json/phoneCodeGeoFeedbackLoop/{first_name}/{last_name}/{phone_number}/{phone_number_e164}/{country_iso2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Romanize the Chinese name to Pinyin, ex. 王晓明 -> Wang (surname) Xiaoming (given name)
#
# GET /api2/json/pinyinChineseName/{chineseName}
# operationId: pinyinChineseName
export def "api2-json-pinyin-chinese-name pinyinChineseName" [
  chinese_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstLastName: record<firstName: string, id: string, lastName: string, script: string>, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({chinese_name: $chinese_name} | format pattern "/api2/json/pinyinChineseName/{chinese_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Romanize a list of Chinese name to Pinyin, ex. 王晓明 -> Wang (surname) Xiaoming (given name).
#
# POST /api2/json/pinyinChineseNameBatch
# operationId: pinyinChineseNameBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string}
export def "api2-json-pinyin-chinese-name-batch pinyinChineseNameBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string}
]: any -> record<personalNames: table<firstLastName: record, id: string, name: string, nameParserType: string, nameParserTypeAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/pinyinChineseNameBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Print basic source statistics.
#
# GET /api2/json/regions
# operationId: regions
export def "api2-json-regions regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countriesAndRegions: table<countryFIPS: string, countryISO2: string, countryISO3: string, countryName: string, countryNumCode: string, region: string, subregion: string, topregion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely religion of a personal full name. NB: only for INDIA (as of current version).
#
# GET /api2/json/religionFull/{countryIso2}/{subDivisionIso31662}/{personalNameFull}
# operationId: religionFull
export def "api2-json-religion-full religionFull" [
  country_iso2: string
  sub_division_iso31662: string
  personal_name_full: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list<string>, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_iso2: $country_iso2, sub_division_iso31662: $sub_division_iso31662, personal_name_full: $personal_name_full} | format pattern "/api2/json/religionFull/{country_iso2}/{sub_division_iso31662}/{personal_name_full}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely religion of up to 100 personal full names. NB: only for India as of currently.
#
# POST /api2/json/religionFullBatch
# operationId: religionFullBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, id?: string, name?: string, subdivisionIso?: string}
export def "api2-json-religion-full-batch religionFullBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, id?: string, name?: string, subdivisionIso?: string}
]: any -> record<personalNames: table<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/religionFullBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 10 UNITS PER NAME] Infer the likely religion of a personal Indian full name, provided the Indian state or Union territory (NB/ this can be inferred using the subclassification endpoint).
#
# GET /api2/json/religionIndianFull/{subDivisionIso31662}/{personalNameFull}
# operationId: religion
export def "api2-json-religion-indian-full religion" [
  sub_division_iso31662: string
  personal_name_full: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list<string>, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_division_iso31662: $sub_division_iso31662, personal_name_full: $personal_name_full} | format pattern "/api2/json/religionIndianFull/{sub_division_iso31662}/{personal_name_full}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely religion of up to 100 personal full Indian names, provided the subclassification at State or Union territory level (NB/ can be inferred using the subclassification endpoint).
#
# POST /api2/json/religionIndianFullBatch
# operationId: religionIndianFullBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {id?: string, name?: string, subdivisionIso?: string}
export def "api2-json-religion-indian-full-batch religionIndianFullBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {id?: string, name?: string, subdivisionIso?: string}
]: any -> record<personalNames: table<id: string, name: string, probabilityAltCalibrated: float, probabilityCalibrated: float, religion: string, religionAlt: string, religionsTop: list, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/religionIndianFullBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the current software version
#
# GET /api2/json/softwareVersion
# operationId: softwareVersion
export def "api2-json-software-version softwareVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<softwareNameAndVersion: string, softwareVersion: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/softwareVersion")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely origin of a name at a country subclassification level (state or regeion). Initially, this is only supported for India (ISO2 code 'IN').
#
# GET /api2/json/subclassification/{countryIso2}/{firstName}/{lastName}
# operationId: subclassification
export def "api2-json-subclassification subclassification" [
  country_iso2: string
  first_name: string
  last_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_iso2: $country_iso2, first_name: $first_name, last_name: $last_name} | format pattern "/api2/json/subclassification/{country_iso2}/{first_name}/{last_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely origin of a list of up to 100 names at a country subclassification level (state or regeion). Initially, this is only supported for India (ISO2 code 'IN').
#
# POST /api2/json/subclassificationBatch
# operationId: subclassificationBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
export def "api2-json-subclassification-batch subclassificationBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/subclassificationBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 10 UNITS PER NAME] Infer the likely Indian state of Union territory according to ISO 3166-2:IN based on the name.
#
# GET /api2/json/subclassificationIndian/{firstName}/{lastName}
# operationId: subclassificationIndian
export def "api2-json-subclassification-indian subclassificationIndian" [
  first_name: string
  last_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name} | format pattern "/api2/json/subclassificationIndian/{first_name}/{last_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer the likely Indian state of Union territory according to ISO 3166-2:IN based on a list of up to 100 names.
#
# POST /api2/json/subclassificationIndianBatch
# operationId: subclassificationIndianBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
export def "api2-json-subclassification-indian-batch subclassificationIndianBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<countryIso2: string, firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, score: float, script: string, subClassification: string, subClassificationAlt: string, subclassificationTop: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/subclassificationIndianBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Print the taxonomy classes valid for the given classifier.
#
# GET /api2/json/taxonomyClasses/{classifierName}
# operationId: taxonomyClasses
export def "api2-json-taxonomy-classes taxonomyClasses" [
  classifier_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<classifierName: string, classifyingScripts: list<string>, taxonomyClasses: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({classifier_name: $classifier_name} | format pattern "/api2/json/taxonomyClasses/{classifier_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer a US resident's likely race/ethnicity according to US Census taxonomy W_NL (white, non latino), HL (hispano latino),  A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# GET /api2/json/usRaceEthnicity/{firstName}/{lastName}
# operationId: usRaceEthnicity
export def "api2-json-us-race-ethnicity usRaceEthnicity" [
  first_name: string
  last_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list<string>, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name} | format pattern "/api2/json/usRaceEthnicity/{first_name}/{last_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer up-to 100 US resident's likely race/ethnicity according to US Census taxonomy. Output is W_NL (white, non latino), HL (hispano latino),  A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# POST /api2/json/usRaceEthnicityBatch
# operationId: usRaceEthnicityBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
export def "api2-json-us-race-ethnicity-batch usRaceEthnicityBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string}
]: any -> record<personalNames: table<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/usRaceEthnicityBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [USES 10 UNITS PER NAME] Infer a US resident's likely race/ethnicity according to US Census taxonomy, using (optional) ZIP5 code info. Output is W_NL (white, non latino), HL (hispano latino),  A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# GET /api2/json/usRaceEthnicityZIP5/{firstName}/{lastName}/{zip5Code}
# operationId: usRaceEthnicityZIP5
export def "api2-json-us-race-ethnicity-zip5 usRaceEthnicityZIP5" [
  first_name: string
  last_name: string
  zip5_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list<string>, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({first_name: $first_name, last_name: $last_name, zip5_code: $zip5_code} | format pattern "/api2/json/usRaceEthnicityZIP5/{first_name}/{last_name}/{zip5_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [USES 10 UNITS PER NAME] Infer up-to 100 US resident's likely race/ethnicity according to US Census taxonomy, with (optional) ZIP code. Output is W_NL (white, non latino), HL (hispano latino),  A (asian, non latino), B_NL (black, non latino). Optionally add header X-OPTION-USRACEETHNICITY-TAXONOMY: USRACEETHNICITY-6CLASSES for two additional classes, AI_AN (American Indian or Alaskan Native) and PI (Pacific Islander).
#
# POST /api2/json/usZipRaceEthnicityBatch
# operationId: usZipRaceEthnicityBatch
# --facts item shape: {id?: string, name?: string}
# --personalNames item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string, zipCode?: string}
export def "api2-json-us-zip-race-ethnicity-batch usZipRaceEthnicityBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facts: list # item shape: {id?: string, name?: string}
  --personal-names: list # item shape: {countryIso2?: string, firstName?: string, id?: string, lastName?: string, zipCode?: string}
]: any -> record<personalNames: table<firstName: string, id: string, lastName: string, probabilityAltCalibrated: float, probabilityCalibrated: float, raceEthnicitiesTop: list, raceEthnicity: string, raceEthnicityAlt: string, score: float, script: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api2/json/usZipRaceEthnicityBatch")
  let body = {"facts": $facts, "personalNames": $personal_names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
