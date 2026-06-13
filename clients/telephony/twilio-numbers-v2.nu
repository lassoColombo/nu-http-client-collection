# Auto-generated client for Twilio - Numbers v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_numbers_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_NUMBERS_TOKEN

const BASE_URL = "https://numbers.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_NUMBERS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://numbers.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Status-completer [] { ["draft" "in-review" "pending-review" "provisionally-approved" "twilio-approved" "twilio-rejected"] }
def SortBy-completer [] { ["date-updated" "valid-until"] }
def SortDirection-completer [] { ["ASC" "DESC"] }
def EndUserType-completer [] { ["business" "individual"] }
def Type-completer [] { ["business" "individual"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "regulatory-compliance-bundles ListBundle" } } | get name | first)
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

# Retrieve a list of all Bundles for an account.
#
# GET /v2/RegulatoryCompliance/Bundles
# operationId: ListBundle
export def "regulatory-compliance-bundles ListBundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string@Status-completer # The verification status of the Bundle resource. Please refer to [Bundle Statuses](https://www.twilio.com/docs/phone-numbers/regulatory/api/bundles#bundle-statuses) for more details.
  --FriendlyName: string # The string that you assigned to describe the resource. The column can contain 255 variable characters.
  --RegulationSid: string # The unique string of a [Regulation resource](https://www.twilio.com/docs/phone-numbers/regulatory/api/regulations) that is associated to the Bundle resource.
  --IsoCountry: string # The 2-digit [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the Bundle's phone number country ownership request.
  --NumberType: string # The type of phone number of the Bundle's ownership request. Can be `local`, `mobile`, `national`, or `tollfree`.
  --HasValidUntilDate: oneof<nothing, bool> # Indicates that the Bundle is a valid Bundle until a specified expiration date.
  --SortBy: string@SortBy-completer # Can be `valid-until` or `date-updated`. Defaults to `date-created`.
  --SortDirection: string@SortDirection-completer # Default is `DESC`. Can be `ASC` or `DESC`.
  --ValidUntilDate: string # Date to filter Bundles having their `valid_until_date` before or after the specified date. Can be `ValidUntilDate>=` or `ValidUntilDate<=`. Both can be used in conjunction as well. [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) is the acceptable date format. (format: date-time)
  --ValidUntilDate<: string # Date to filter Bundles having their `valid_until_date` before or after the specified date. Can be `ValidUntilDate>=` or `ValidUntilDate<=`. Both can be used in conjunction as well. [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) is the acceptable date format. (format: date-time)
  --ValidUntilDate>: string # Date to filter Bundles having their `valid_until_date` before or after the specified date. Can be `ValidUntilDate>=` or `ValidUntilDate<=`. Both can be used in conjunction as well. [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) is the acceptable date format. (format: date-time)
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "FriendlyName" $FriendlyName "scalar") (serialize-qp "RegulationSid" $RegulationSid "scalar") (serialize-qp "IsoCountry" $IsoCountry "scalar") (serialize-qp "NumberType" $NumberType "scalar") (serialize-qp "HasValidUntilDate" $HasValidUntilDate "scalar") (serialize-qp "SortBy" $SortBy "scalar") (serialize-qp "SortDirection" $SortDirection "scalar") (serialize-qp "ValidUntilDate" $ValidUntilDate "scalar") (serialize-qp "ValidUntilDate<" $ValidUntilDate< "scalar") (serialize-qp "ValidUntilDate>" $ValidUntilDate> "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RegulatoryCompliance/Bundles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Bundle.
#
# POST /v2/RegulatoryCompliance/Bundles
# operationId: CreateBundle
export def "regulatory-compliance-bundles CreateBundle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Email: string # The email address that will receive updates when the Bundle resource changes status.
  --EndUserType: string@EndUserType-completer
  FriendlyName: string # The string that you assigned to describe the resource.
  --IsoCountry: string # The [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) of the Bundle's phone number country ownership request.
  --NumberType: string # The type of phone number of the Bundle's ownership request. Can be `local`, `mobile`, `national`, or `toll free`.
  --RegulationSid: string # The unique string of a regulation that is associated to the Bundle resource.
  --StatusCallback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base "/v2/RegulatoryCompliance/Bundles")
  let body = {Email: $Email, EndUserType: $EndUserType, FriendlyName: $FriendlyName, IsoCountry: $IsoCountry, NumberType: $NumberType, RegulationSid: $RegulationSid, StatusCallback: $StatusCallback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Bundles Copies for a Bundle.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/Copies
# operationId: ListBundleCopy
export def "regulatory-compliance-bundles-copies ListBundleCopy" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/Copies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new copy of a Bundle. It will internally create copies of all the bundle items (identities and documents) of the original bundle
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/Copies
# operationId: CreateBundleCopy
export def "regulatory-compliance-bundles-copies CreateBundleCopy" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The string that you assigned to describe the copied bundle.
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/Copies")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Evaluations associated to the Bundle resource.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations
# operationId: ListEvaluation
export def "regulatory-compliance-bundles-evaluations ListEvaluation" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list, sid: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/Evaluations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an evaluation for a bundle
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations
# operationId: CreateEvaluation
export def "regulatory-compliance-bundles-evaluations CreateEvaluation" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list<any>, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/Evaluations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch specific Evaluation Instance.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/Evaluations/{Sid}
# operationId: FetchEvaluation
export def "regulatory-compliance-bundles-evaluations FetchEvaluation" [
  BundleSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, bundle_sid: string, date_created: string, regulation_sid: string, results: list<any>, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/Evaluations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Assigned Items for an account.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments
# operationId: ListItemAssignment
export def "regulatory-compliance-bundles-item-assignments ListItemAssignment" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/ItemAssignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Assigned Item.
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments
# operationId: CreateItemAssignment
export def "regulatory-compliance-bundles-item-assignments CreateItemAssignment" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ObjectSid: string # The SID of an object bag that holds information of the different items.
]: any -> record<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/ItemAssignments")
  let body = {ObjectSid: $ObjectSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an Assignment Item Instance.
#
# DELETE /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments/{Sid}
# operationId: DeleteItemAssignment
export def "regulatory-compliance-bundles-item-assignments DeleteItemAssignment" [
  BundleSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/ItemAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch specific Assigned Item Instance.
#
# GET /v2/RegulatoryCompliance/Bundles/{BundleSid}/ItemAssignments/{Sid}
# operationId: FetchItemAssignment
export def "regulatory-compliance-bundles-item-assignments FetchItemAssignment" [
  BundleSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, bundle_sid: string, date_created: string, object_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/ItemAssignments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces all bundle items in the target bundle (specified in the path) with all the bundle items of the source bundle (specified by the from_bundle_sid body param)
#
# POST /v2/RegulatoryCompliance/Bundles/{BundleSid}/ReplaceItems
# operationId: CreateReplaceItems
export def "regulatory-compliance-bundles-replace-items CreateReplaceItems" [
  BundleSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  FromBundleSid: string # The source bundle sid to copy the item assignments from.
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, regulation_sid: string, sid: string, status: string, status_callback: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($BundleSid)/ReplaceItems")
  let body = {FromBundleSid: $FromBundleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Bundle.
#
# DELETE /v2/RegulatoryCompliance/Bundles/{Sid}
# operationId: DeleteBundle
export def "regulatory-compliance-bundles DeleteBundle" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Bundle instance.
#
# GET /v2/RegulatoryCompliance/Bundles/{Sid}
# operationId: FetchBundle
export def "regulatory-compliance-bundles FetchBundle" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Bundle in an account.
#
# POST /v2/RegulatoryCompliance/Bundles/{Sid}
# operationId: UpdateBundle
export def "regulatory-compliance-bundles UpdateBundle" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Email: string # The email address that will receive updates when the Bundle resource changes status.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Status: string@Status-completer
  --StatusCallback: string # The URL we call to inform your application of status changes. (format: uri)
]: any -> record<account_sid: string, date_created: string, date_updated: string, email: string, friendly_name: string, links: record, regulation_sid: string, sid: string, status: string, status_callback: string, url: string, valid_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Bundles/($Sid)")
  let body = {Email: $Email, FriendlyName: $FriendlyName, Status: $Status, StatusCallback: $StatusCallback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all End-User Types.
#
# GET /v2/RegulatoryCompliance/EndUserTypes
# operationId: ListEndUserType
export def "regulatory-compliance-end-user-types ListEndUserType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<end_user_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RegulatoryCompliance/EndUserTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific End-User Type Instance.
#
# GET /v2/RegulatoryCompliance/EndUserTypes/{Sid}
# operationId: FetchEndUserType
export def "regulatory-compliance-end-user-types FetchEndUserType" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/EndUserTypes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all End User for an account.
#
# GET /v2/RegulatoryCompliance/EndUsers
# operationId: ListEndUser
export def "regulatory-compliance-end-users ListEndUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RegulatoryCompliance/EndUsers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new End User.
#
# POST /v2/RegulatoryCompliance/EndUsers
# operationId: CreateEndUser
export def "regulatory-compliance-end-users CreateEndUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  FriendlyName: string # The string that you assigned to describe the resource.
  Type: string@Type-completer
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base "/v2/RegulatoryCompliance/EndUsers")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific End User.
#
# DELETE /v2/RegulatoryCompliance/EndUsers/{Sid}
# operationId: DeleteEndUser
export def "regulatory-compliance-end-users DeleteEndUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/EndUsers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch specific End User Instance.
#
# GET /v2/RegulatoryCompliance/EndUsers/{Sid}
# operationId: FetchEndUser
export def "regulatory-compliance-end-users FetchEndUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/EndUsers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing End User.
#
# POST /v2/RegulatoryCompliance/EndUsers/{Sid}
# operationId: UpdateEndUser
export def "regulatory-compliance-end-users UpdateEndUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: any # The set of parameters that are the attributes of the End User resource which are derived End User Types.
  --FriendlyName: string # The string that you assigned to describe the resource.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/EndUsers/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Regulations.
#
# GET /v2/RegulatoryCompliance/Regulations
# operationId: ListRegulation
export def "regulatory-compliance-regulations ListRegulation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EndUserType: string@EndUserType-completer # The type of End User the regulation requires - can be `individual` or `business`.
  --IsoCountry: string # The ISO country code of the phone number's country.
  --NumberType: string # The type of phone number that the regulatory requiremnt is restricting.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<end_user_type: string, friendly_name: string, iso_country: string, number_type: string, requirements: any, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "EndUserType" $EndUserType "scalar") (serialize-qp "IsoCountry" $IsoCountry "scalar") (serialize-qp "NumberType" $NumberType "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RegulatoryCompliance/Regulations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch specific Regulation Instance.
#
# GET /v2/RegulatoryCompliance/Regulations/{Sid}
# operationId: FetchRegulation
export def "regulatory-compliance-regulations FetchRegulation" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<end_user_type: string, friendly_name: string, iso_country: string, number_type: string, requirements: any, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/Regulations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Supporting Document Types.
#
# GET /v2/RegulatoryCompliance/SupportingDocumentTypes
# operationId: ListSupportingDocumentType
export def "regulatory-compliance-supporting-document-types ListSupportingDocumentType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, supporting_document_types: table<fields: list, friendly_name: string, machine_name: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RegulatoryCompliance/SupportingDocumentTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Supporting Document Type Instance.
#
# GET /v2/RegulatoryCompliance/SupportingDocumentTypes/{Sid}
# operationId: FetchSupportingDocumentType
export def "regulatory-compliance-supporting-document-types FetchSupportingDocumentType" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fields: list<any>, friendly_name: string, machine_name: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/SupportingDocumentTypes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Supporting Document for an account.
#
# GET /v2/RegulatoryCompliance/SupportingDocuments
# operationId: ListSupportingDocument
export def "regulatory-compliance-supporting-documents ListSupportingDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, results: table<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RegulatoryCompliance/SupportingDocuments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Supporting Document.
#
# POST /v2/RegulatoryCompliance/SupportingDocuments
# operationId: CreateSupportingDocument
export def "regulatory-compliance-supporting-documents CreateSupportingDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: any # The set of parameters that are the attributes of the Supporting Documents resource which are derived Supporting Document Types.
  FriendlyName: string # The string that you assigned to describe the resource.
  Type: string # The type of the Supporting Document.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base "/v2/RegulatoryCompliance/SupportingDocuments")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Supporting Document.
#
# DELETE /v2/RegulatoryCompliance/SupportingDocuments/{Sid}
# operationId: DeleteSupportingDocument
export def "regulatory-compliance-supporting-documents DeleteSupportingDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/SupportingDocuments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch specific Supporting Document Instance.
#
# GET /v2/RegulatoryCompliance/SupportingDocuments/{Sid}
# operationId: FetchSupportingDocument
export def "regulatory-compliance-supporting-documents FetchSupportingDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/SupportingDocuments/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing Supporting Document.
#
# POST /v2/RegulatoryCompliance/SupportingDocuments/{Sid}
# operationId: UpdateSupportingDocument
export def "regulatory-compliance-supporting-documents UpdateSupportingDocument" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Attributes: any # The set of parameters that are the attributes of the Supporting Document resource which are derived Supporting Document Types.
  --FriendlyName: string # The string that you assigned to describe the resource.
]: any -> record<account_sid: string, attributes: any, date_created: string, date_updated: string, failure_reason: string, friendly_name: string, mime_type: string, sid: string, status: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://numbers.twilio.com")
  let full_url = (build-url $base $"/v2/RegulatoryCompliance/SupportingDocuments/($Sid)")
  let body = {Attributes: $Attributes, FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
