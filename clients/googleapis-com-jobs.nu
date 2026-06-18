# Auto-generated client for Cloud Talent Solution API vv3p1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/jobs/v3p1beta1/openapi.json
# Auth: --token flag or $env.CLOUD_TALENT_SOLUTION_API_TOKEN

const BASE_URL = "https://jobs.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_TALENT_SOLUTION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://jobs.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def scope-completer [] { ["COMPLETION_SCOPE_UNSPECIFIED" "PUBLIC" "TENANT"] }
def type-completer [] { ["COMBINED" "COMPANY_NAME" "COMPLETION_TYPE_UNSPECIFIED" "JOB_TITLE"] }
def job-view-completer [] { ["JOB_VIEW_FULL" "JOB_VIEW_ID_ONLY" "JOB_VIEW_MINIMAL" "JOB_VIEW_SMALL" "JOB_VIEW_UNSPECIFIED"] }
def diversification-level-completer [] { ["DISABLED" "DIVERSIFICATION_LEVEL_UNSPECIFIED" "SIMPLE"] }
def search-mode-completer [] { ["FEATURED_JOB_SEARCH" "JOB_SEARCH" "SEARCH_MODE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v3p1beta1 delete" } } | get name | first)
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

# Deletes the specified job. Typically, the job becomes unsearchable within 10 seconds, but it may take up to 5 minutes.
#
# DELETE /v3p1beta1/{name}
# operationId: jobs.projects.jobs.delete
export def "v3p1beta1 delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v3p1beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v3p1beta1/{name}
# operationId: jobs.projects.operations.get
export def "v3p1beta1 get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v3p1beta1/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates specified job. Typically, updated contents become visible in search results within 10 seconds, but it may take up to 5 minutes.
#
# PATCH /v3p1beta1/{name}
# operationId: jobs.projects.jobs.patch
# --job shape: {addresses?: list<string>, applicationInfo?: record, companyDisplayName?: string, companyName?: string, compensationInfo?: record, customAttributes?: record, degreeTypes?: list<string>, department?: string, derivedInfo?: record, description?: string, employmentTypes?: list<string>, incentives?: string, jobBenefits?: list<string>, jobEndTime?: string, jobLevel?: "JOB_LEVEL_UNSPECIFIED"|"ENTRY_LEVEL"|"EXPERIENCED"|"MANAGER"|"DIRECTOR"|"EXECUTIVE", jobStartTime?: string, languageCode?: string, ... (13 more fields)}
export def "v3p1beta1 update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --job: record # A Job resource represents a job posting (also referred to as a "job listing" or "job requisition"). A job belongs to a Company, which is the hiring entity responsible for the job. — shape: {addresses?: list<string>, applicationInfo?: record, companyDisplayName?: string, companyName?: string, compensationInfo?: record, customAttributes?: record, degreeTypes?: list<string>, department?: string, derivedInfo?: record, description?: string, employmentTypes?: list<string>, incentives?: string, jobBenefits?: list<string>, jobEndTime?: string, jobLevel?: "JOB_LEVEL_UNSPECIFIED"|"ENTRY_LEVEL"|"EXPERIENCED"|"MANAGER"|"DIRECTOR"|"EXECUTIVE", jobStartTime?: string, languageCode?: string, ... (13 more fields)}
  --update-mask: string # Optional but strongly recommended to be provided for the best service experience. If update_mask is provided, only the specified fields in job are updated. Otherwise all the fields are updated. A field mask to restrict the fields that are updated. Only top level fields of Job are supported. (format: google-fieldmask)
]: any -> record<addresses: list<string>, applicationInfo: record<emails: list<string>, instruction: string, uris: list<string>>, companyDisplayName: string, companyName: string, compensationInfo: record<annualizedBaseCompensationRange: record<maxCompensation: record, minCompensation: record>, annualizedTotalCompensationRange: record<maxCompensation: record, minCompensation: record>, entries: list<record>>, customAttributes: record, degreeTypes: list<string>, department: string, derivedInfo: record<jobCategories: list<string>, locations: list<record>>, description: string, employmentTypes: list<string>, incentives: string, jobBenefits: list<string>, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record<disableStreetAddressResolution: bool, htmlSanitization: string>, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v3p1beta1/{name}") $qp)
  let req_body = {"job": $job, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Completes the specified prefix with keyword suggestions. Intended for use by a job search auto-complete search box.
#
# GET /v3p1beta1/{name}:complete
# operationId: jobs.projects.complete
export def "v3p1beta1 complete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --company-name: string # Optional. If provided, restricts completion to specified company. The format is "projects/{project_id}/companies/{company_id}", for example, "projects/api-test-project/companies/foo".
  --language-code: string # Deprecated. Use language_codes instead. Optional. The language of the query. This is the BCP-47 language code, such as "en-US" or "sr-Latn". For more information, see [Tags for Identifying Languages](https://tools.ietf.org/html/bcp47). For CompletionType.JOB_TITLE type, only open jobs with the same language_code are returned. For CompletionType.COMPANY_NAME type, only companies having open jobs with the same language_code are returned. For CompletionType.COMBINED type, only open jobs with the same language_code or companies having open jobs with the same language_code are returned. The maximum number of allowed characters is 255.
  --language-codes: list<string> # Optional. The list of languages of the query. This is the BCP-47 language code, such as "en-US" or "sr-Latn". For more information, see [Tags for Identifying Languages](https://tools.ietf.org/html/bcp47). For CompletionType.JOB_TITLE type, only open jobs with the same language_codes are returned. For CompletionType.COMPANY_NAME type, only companies having open jobs with the same language_codes are returned. For CompletionType.COMBINED type, only open jobs with the same language_codes or companies having open jobs with the same language_codes are returned. The maximum number of allowed characters is 255.
  --page-size: int # Required. Completion result count. The maximum allowed page size is 10.
  --query: string # Required. The query used to generate suggestions. The maximum number of allowed characters is 255.
  --scope: string@scope-completer # Optional. The scope of the completion. The defaults is CompletionScope.PUBLIC.
  --type: string@type-completer # Optional. The completion topic. The default is CompletionType.COMBINED.
]: nothing -> record<completionResults: table<imageUri: string, suggestion: string, type: string>, metadata: record<requestId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "companyName" $company_name "scalar") (serialize-qp "languageCode" $language_code "scalar") (serialize-qp "languageCodes" $language_codes "multi") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v3p1beta1/{name}:complete") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Report events issued when end user interacts with customer's application that uses Cloud Talent Solution. You may inspect the created events in [self service tools](https://console.cloud.google.com/talent-solution/overview). [Learn more](https://cloud.google.com/talent-solution/docs/management-tools) about self service tools.
#
# POST /v3p1beta1/{parent}/clientEvents
# operationId: jobs.projects.clientEvents.create
# --clientEvent shape: {createTime?: string, eventId?: string, extraInfo?: record, jobEvent?: record, parentEventId?: string, requestId?: string}
export def "v3p1beta1-client-events create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --client-event: record # An event issued when an end user interacts with the application that implements Cloud Talent Solution. Providing this information improves the quality of search and recommendation for the API clients, enabling the service to perform optimally. The number of events sent must be consistent with other calls, such as job searches, issued to the service by the client. — shape: {createTime?: string, eventId?: string, extraInfo?: record, jobEvent?: record, parentEventId?: string, requestId?: string}
]: any -> record<createTime: string, eventId: string, extraInfo: record, jobEvent: record<jobs: list<string>, type: string>, parentEventId: string, requestId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/clientEvents") $qp)
  let req_body = {"clientEvent": $client_event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all companies associated with the service account.
#
# GET /v3p1beta1/{parent}/companies
# operationId: jobs.projects.companies.list
export def "v3p1beta1-companies list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Optional. The maximum number of companies to be returned, at most 100. Default is 100 if a non-positive number is provided.
  --page-token: string # Optional. The starting indicator from which to return results.
  --require-open-jobs: oneof<nothing, bool> # Optional. Set to true if the companies requested must have open jobs. Defaults to false. If true, at most page_size of companies are fetched, among which only those with open jobs are returned.
]: nothing -> record<companies: table<careerSiteUri: string, derivedInfo: record, displayName: string, eeoText: string, externalId: string, headquartersAddress: string, hiringAgency: bool, imageUri: string, keywordSearchableJobCustomAttributes: list, name: string, size: string, suspended: bool, websiteUri: string>, metadata: record<requestId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "requireOpenJobs" $require_open_jobs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/companies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new company entity.
#
# POST /v3p1beta1/{parent}/companies
# operationId: jobs.projects.companies.create
# --company shape: {careerSiteUri?: string, derivedInfo?: record, displayName?: string, eeoText?: string, externalId?: string, headquartersAddress?: string, hiringAgency?: bool, imageUri?: string, keywordSearchableJobCustomAttributes?: list<string>, name?: string, size?: "COMPANY_SIZE_UNSPECIFIED"|"MINI"|"SMALL"|"SMEDIUM"|"MEDIUM"|"BIG"|"BIGGER"|"GIANT", suspended?: bool, websiteUri?: string}
export def "v3p1beta1-companies create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --company: record # A Company resource represents a company in the service. A company is the entity that owns job postings, that is, the hiring entity responsible for employing applicants for the job position. — shape: {careerSiteUri?: string, derivedInfo?: record, displayName?: string, eeoText?: string, externalId?: string, headquartersAddress?: string, hiringAgency?: bool, imageUri?: string, keywordSearchableJobCustomAttributes?: list<string>, name?: string, size?: "COMPANY_SIZE_UNSPECIFIED"|"MINI"|"SMALL"|"SMEDIUM"|"MEDIUM"|"BIG"|"BIGGER"|"GIANT", suspended?: bool, websiteUri?: string}
]: any -> record<careerSiteUri: string, derivedInfo: record<headquartersLocation: record<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>>, displayName: string, eeoText: string, externalId: string, headquartersAddress: string, hiringAgency: bool, imageUri: string, keywordSearchableJobCustomAttributes: list<string>, name: string, size: string, suspended: bool, websiteUri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/companies") $qp)
  let req_body = {"company": $company} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists jobs by filter.
#
# GET /v3p1beta1/{parent}/jobs
# operationId: jobs.projects.jobs.list
export def "v3p1beta1-jobs list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Required. The filter string specifies the jobs to be enumerated. Supported operator: =, AND The fields eligible for filtering are: * `companyName` * `requisitionId` * `status` Available values: OPEN, EXPIRED, ALL. Defaults to OPEN if no value is specified. At least one of `companyName` and `requisitionId` must present or an INVALID_ARGUMENT error is thrown. Sample Query: * companyName = "projects/api-test-project/companies/123" * companyName = "projects/api-test-project/companies/123" AND requisitionId = "req-1" * companyName = "projects/api-test-project/companies/123" AND status = "EXPIRED" * requisitionId = "req-1" * requisitionId = "req-1" AND status = "EXPIRED"
  --job-view: string@job-view-completer # Optional. The desired job attributes returned for jobs in the search response. Defaults to JobView.JOB_VIEW_FULL if no value is specified.
  --page-size: int # Optional. The maximum number of jobs to be returned per page of results. If job_view is set to JobView.JOB_VIEW_ID_ONLY, the maximum allowed page size is 1000. Otherwise, the maximum allowed page size is 100. Default is 100 if empty or a number < 1 is specified.
  --page-token: string # Optional. The starting point of a query result.
]: nothing -> record<jobs: table<addresses: list, applicationInfo: record, companyDisplayName: string, companyName: string, compensationInfo: record, customAttributes: record, degreeTypes: list, department: string, derivedInfo: record, description: string, employmentTypes: list, incentives: string, jobBenefits: list, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string>, metadata: record<requestId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "jobView" $job_view "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new job. Typically, the job becomes searchable within 10 seconds, but it may take up to 5 minutes.
#
# POST /v3p1beta1/{parent}/jobs
# operationId: jobs.projects.jobs.create
# --job shape: {addresses?: list<string>, applicationInfo?: record, companyDisplayName?: string, companyName?: string, compensationInfo?: record, customAttributes?: record, degreeTypes?: list<string>, department?: string, derivedInfo?: record, description?: string, employmentTypes?: list<string>, incentives?: string, jobBenefits?: list<string>, jobEndTime?: string, jobLevel?: "JOB_LEVEL_UNSPECIFIED"|"ENTRY_LEVEL"|"EXPERIENCED"|"MANAGER"|"DIRECTOR"|"EXECUTIVE", jobStartTime?: string, languageCode?: string, ... (13 more fields)}
export def "v3p1beta1-jobs create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --job: record # A Job resource represents a job posting (also referred to as a "job listing" or "job requisition"). A job belongs to a Company, which is the hiring entity responsible for the job. — shape: {addresses?: list<string>, applicationInfo?: record, companyDisplayName?: string, companyName?: string, compensationInfo?: record, customAttributes?: record, degreeTypes?: list<string>, department?: string, derivedInfo?: record, description?: string, employmentTypes?: list<string>, incentives?: string, jobBenefits?: list<string>, jobEndTime?: string, jobLevel?: "JOB_LEVEL_UNSPECIFIED"|"ENTRY_LEVEL"|"EXPERIENCED"|"MANAGER"|"DIRECTOR"|"EXECUTIVE", jobStartTime?: string, languageCode?: string, ... (13 more fields)}
]: any -> record<addresses: list<string>, applicationInfo: record<emails: list<string>, instruction: string, uris: list<string>>, companyDisplayName: string, companyName: string, compensationInfo: record<annualizedBaseCompensationRange: record<maxCompensation: record, minCompensation: record>, annualizedTotalCompensationRange: record<maxCompensation: record, minCompensation: record>, entries: list<record>>, customAttributes: record, degreeTypes: list<string>, department: string, derivedInfo: record<jobCategories: list<string>, locations: list<record>>, description: string, employmentTypes: list<string>, incentives: string, jobBenefits: list<string>, jobEndTime: string, jobLevel: string, jobStartTime: string, languageCode: string, name: string, postingCreateTime: string, postingExpireTime: string, postingPublishTime: string, postingRegion: string, postingUpdateTime: string, processingOptions: record<disableStreetAddressResolution: bool, htmlSanitization: string>, promotionValue: int, qualifications: string, requisitionId: string, responsibilities: string, title: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/jobs") $qp)
  let req_body = {"job": $job} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a list of Jobs by filter.
#
# POST /v3p1beta1/{parent}/jobs:batchDelete
# operationId: jobs.projects.jobs.batchDelete
export def "v3p1beta1-jobs-batch-delete delete" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Required. The filter string specifies the jobs to be deleted. Supported operator: =, AND The fields eligible for filtering are: * `companyName` (Required) * `requisitionId` (Required) Sample Query: companyName = "projects/api-test-project/companies/123" AND requisitionId = "req-1"
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/jobs:batchDelete") $qp)
  let req_body = {"filter": $filter} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Searches for jobs using the provided SearchJobsRequest. This call constrains the visibility of jobs present in the database, and only returns jobs that the caller has permission to search against.
#
# POST /v3p1beta1/{parent}/jobs:search
# operationId: jobs.projects.jobs.search
# --customRankingInfo shape: {importanceLevel?: "IMPORTANCE_LEVEL_UNSPECIFIED"|"NONE"|"LOW"|"MILD"|"MEDIUM"|"HIGH"|"EXTREME", rankingExpression?: string}
# --histogramFacets shape: {compensationHistogramFacets?: list, customAttributeHistogramFacets?: list, simpleHistogramFacets?: list<string>}
# --histogramQueries item shape: {histogramQuery?: string}
# --jobQuery shape: {commuteFilter?: record, companyDisplayNames?: list<string>, companyNames?: list<string>, compensationFilter?: record, customAttributeFilter?: string, disableSpellCheck?: bool, employmentTypes?: list<string>, excludedJobs?: list<string>, jobCategories?: list<string>, languageCodes?: list<string>, locationFilters?: list, publishTimeRange?: record, query?: string, queryLanguageCode?: string}
# --requestMetadata shape: {deviceInfo?: record, domain?: string, sessionId?: string, userId?: string}
export def "v3p1beta1-jobs-search list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --custom-ranking-info: record # Input only. Custom ranking information for SearchJobsRequest. — shape: {importanceLevel?: "IMPORTANCE_LEVEL_UNSPECIFIED"|"NONE"|"LOW"|"MILD"|"MEDIUM"|"HIGH"|"EXTREME", rankingExpression?: string}
  --disable-keyword-match: oneof<nothing, bool> # Optional. Controls whether to disable exact keyword match on Job.job_title, Job.description, Job.company_display_name, Job.locations, Job.qualifications. When disable keyword match is turned off, a keyword match returns jobs that do not match given category filters when there are matching keywords. For example, the query "program manager," a result is returned even if the job posting has the title "software developer," which does not fall into "program manager" ontology, but does have "program manager" appearing in its description. For queries like "cloud" that does not contain title or location specific ontology, jobs with "cloud" keyword matches are returned regardless of this flag's value. Please use Company.keyword_searchable_custom_fields or Company.keyword_searchable_custom_attributes if company specific globally matched custom field/attribute string values is needed. Enabling keyword match improves recall of subsequent search requests. Defaults to false.
  --diversification-level: string@diversification-level-completer # Optional. Controls whether highly similar jobs are returned next to each other in the search results. Jobs are identified as highly similar based on their titles, job categories, and locations. Highly similar results are clustered so that only one representative job of the cluster is displayed to the job seeker higher up in the results, with the other jobs being displayed lower down in the results. Defaults to DiversificationLevel.SIMPLE if no value is specified.
  --enable-broadening: oneof<nothing, bool> # Optional. Controls whether to broaden the search when it produces sparse results. Broadened queries append results to the end of the matching results list. Defaults to false.
  --histogram-facets: record # Input only. Histogram facets to be specified in SearchJobsRequest. — shape: {compensationHistogramFacets?: list, customAttributeHistogramFacets?: list, simpleHistogramFacets?: list<string>}
  --histogram-queries: list # Optional. Expression based histogram requests for jobs matching JobQuery. — item shape: {histogramQuery?: string}
  --job-query: record # Input only. The query required to perform a search query. — shape: {commuteFilter?: record, companyDisplayNames?: list<string>, companyNames?: list<string>, compensationFilter?: record, customAttributeFilter?: string, disableSpellCheck?: bool, employmentTypes?: list<string>, excludedJobs?: list<string>, jobCategories?: list<string>, languageCodes?: list<string>, locationFilters?: list, publishTimeRange?: record, query?: string, queryLanguageCode?: string}
  --job-view: string@job-view-completer # Optional. The desired job attributes returned for jobs in the search response. Defaults to JobView.SMALL if no value is specified.
  --offset: int # Optional. An integer that specifies the current offset (that is, starting result location, amongst the jobs deemed by the API as relevant) in search results. This field is only considered if page_token is unset. The maximum allowed value is 5000. Otherwise an error is thrown. For example, 0 means to return results starting from the first matching job, and 10 means to return from the 11th job. This can be used for pagination, (for example, pageSize = 10 and offset = 10 means to return from the second page). (format: int32)
  --order-by: string # Optional. The criteria determining how search results are sorted. Default is "relevance desc". Supported options are: * `"relevance desc"`: By relevance descending, as determined by the API algorithms. Relevance thresholding of query results is only available with this ordering. * `"posting_publish_time desc"`: By Job.posting_publish_time descending. * `"posting_update_time desc"`: By Job.posting_update_time descending. * `"title"`: By Job.title ascending. * `"title desc"`: By Job.title descending. * `"annualized_base_compensation"`: By job's CompensationInfo.annualized_base_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_base_compensation desc"`: By job's CompensationInfo.annualized_base_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation"`: By job's CompensationInfo.annualized_total_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation desc"`: By job's CompensationInfo.annualized_total_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"custom_ranking desc"`: By the relevance score adjusted to the SearchJobsRequest.custom_ranking_info.ranking_expression with weight factor assigned by SearchJobsRequest.custom_ranking_info.importance_level in descending order. * Location sorting: Use the special syntax to order jobs by distance: "`distance_from('Hawaii')`": Order by distance from Hawaii. "`distance_from(19.89, 155.5)`": Order by distance from a coordinate. "`distance_from('Hawaii'), distance_from('Puerto Rico')`": Order by multiple locations. See details below. "`distance_from('Hawaii'), distance_from(19.89, 155.5)`": Order by multiple locations. See details below. The string can have a maximum of 256 characters. When multiple distance centers are provided, a job that is close to any of the distance centers would have a high rank. When a job has multiple locations, the job location closest to one of the distance centers will be used. Jobs that don't have locations will be ranked at the bottom. Distance is calculated with a precision of 11.3 meters (37.4 feet). Diversification strategy is still applied unless explicitly disabled in diversification_level.
  --page-size: int # Optional. A limit on the number of jobs returned in the search results. Increasing this value above the default value of 10 can increase search response time. The value can be between 1 and 100. (format: int32)
  --page-token: string # Optional. The token specifying the current offset within search results. See SearchJobsResponse.next_page_token for an explanation of how to obtain the next set of query results.
  --request-metadata: record # Input only. Meta information related to the job searcher or entity conducting the job search. This information is used to improve the performance of the service. — shape: {deviceInfo?: record, domain?: string, sessionId?: string, userId?: string}
  --require-precise-result-size: oneof<nothing, bool> # This field is deprecated.
  --search-mode: string@search-mode-completer # Optional. Mode of a search. Defaults to SearchMode.JOB_SEARCH.
]: any -> record<broadenedQueryJobsCount: int, estimatedTotalSize: int, histogramQueryResults: table<histogram: record, histogramQuery: string>, histogramResults: record<compensationHistogramResults: list<record>, customAttributeHistogramResults: list<record>, simpleHistogramResults: list<record>>, locationFilters: table<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>, matchingJobs: table<commuteInfo: record, job: record, jobSummary: string, jobTitleSnippet: string, searchTextSnippet: string>, metadata: record<requestId: string>, nextPageToken: string, spellCorrection: record<corrected: bool, correctedText: string>, totalSize: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/jobs:search") $qp)
  let req_body = {"customRankingInfo": $custom_ranking_info, "disableKeywordMatch": $disable_keyword_match, "diversificationLevel": $diversification_level, "enableBroadening": $enable_broadening, "histogramFacets": $histogram_facets, "histogramQueries": $histogram_queries, "jobQuery": $job_query, "jobView": $job_view, "offset": $offset, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token, "requestMetadata": $request_metadata, "requirePreciseResultSize": $require_precise_result_size, "searchMode": $search_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Searches for jobs using the provided SearchJobsRequest. This API call is intended for the use case of targeting passive job seekers (for example, job seekers who have signed up to receive email alerts about potential job opportunities), and has different algorithmic adjustments that are targeted to passive job seekers. This call constrains the visibility of jobs present in the database, and only returns jobs the caller has permission to search against.
#
# POST /v3p1beta1/{parent}/jobs:searchForAlert
# operationId: jobs.projects.jobs.searchForAlert
# --customRankingInfo shape: {importanceLevel?: "IMPORTANCE_LEVEL_UNSPECIFIED"|"NONE"|"LOW"|"MILD"|"MEDIUM"|"HIGH"|"EXTREME", rankingExpression?: string}
# --histogramFacets shape: {compensationHistogramFacets?: list, customAttributeHistogramFacets?: list, simpleHistogramFacets?: list<string>}
# --histogramQueries item shape: {histogramQuery?: string}
# --jobQuery shape: {commuteFilter?: record, companyDisplayNames?: list<string>, companyNames?: list<string>, compensationFilter?: record, customAttributeFilter?: string, disableSpellCheck?: bool, employmentTypes?: list<string>, excludedJobs?: list<string>, jobCategories?: list<string>, languageCodes?: list<string>, locationFilters?: list, publishTimeRange?: record, query?: string, queryLanguageCode?: string}
# --requestMetadata shape: {deviceInfo?: record, domain?: string, sessionId?: string, userId?: string}
export def "v3p1beta1-jobs-search-for-alert list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --custom-ranking-info: record # Input only. Custom ranking information for SearchJobsRequest. — shape: {importanceLevel?: "IMPORTANCE_LEVEL_UNSPECIFIED"|"NONE"|"LOW"|"MILD"|"MEDIUM"|"HIGH"|"EXTREME", rankingExpression?: string}
  --disable-keyword-match: oneof<nothing, bool> # Optional. Controls whether to disable exact keyword match on Job.job_title, Job.description, Job.company_display_name, Job.locations, Job.qualifications. When disable keyword match is turned off, a keyword match returns jobs that do not match given category filters when there are matching keywords. For example, the query "program manager," a result is returned even if the job posting has the title "software developer," which does not fall into "program manager" ontology, but does have "program manager" appearing in its description. For queries like "cloud" that does not contain title or location specific ontology, jobs with "cloud" keyword matches are returned regardless of this flag's value. Please use Company.keyword_searchable_custom_fields or Company.keyword_searchable_custom_attributes if company specific globally matched custom field/attribute string values is needed. Enabling keyword match improves recall of subsequent search requests. Defaults to false.
  --diversification-level: string@diversification-level-completer # Optional. Controls whether highly similar jobs are returned next to each other in the search results. Jobs are identified as highly similar based on their titles, job categories, and locations. Highly similar results are clustered so that only one representative job of the cluster is displayed to the job seeker higher up in the results, with the other jobs being displayed lower down in the results. Defaults to DiversificationLevel.SIMPLE if no value is specified.
  --enable-broadening: oneof<nothing, bool> # Optional. Controls whether to broaden the search when it produces sparse results. Broadened queries append results to the end of the matching results list. Defaults to false.
  --histogram-facets: record # Input only. Histogram facets to be specified in SearchJobsRequest. — shape: {compensationHistogramFacets?: list, customAttributeHistogramFacets?: list, simpleHistogramFacets?: list<string>}
  --histogram-queries: list # Optional. Expression based histogram requests for jobs matching JobQuery. — item shape: {histogramQuery?: string}
  --job-query: record # Input only. The query required to perform a search query. — shape: {commuteFilter?: record, companyDisplayNames?: list<string>, companyNames?: list<string>, compensationFilter?: record, customAttributeFilter?: string, disableSpellCheck?: bool, employmentTypes?: list<string>, excludedJobs?: list<string>, jobCategories?: list<string>, languageCodes?: list<string>, locationFilters?: list, publishTimeRange?: record, query?: string, queryLanguageCode?: string}
  --job-view: string@job-view-completer # Optional. The desired job attributes returned for jobs in the search response. Defaults to JobView.SMALL if no value is specified.
  --offset: int # Optional. An integer that specifies the current offset (that is, starting result location, amongst the jobs deemed by the API as relevant) in search results. This field is only considered if page_token is unset. The maximum allowed value is 5000. Otherwise an error is thrown. For example, 0 means to return results starting from the first matching job, and 10 means to return from the 11th job. This can be used for pagination, (for example, pageSize = 10 and offset = 10 means to return from the second page). (format: int32)
  --order-by: string # Optional. The criteria determining how search results are sorted. Default is "relevance desc". Supported options are: * `"relevance desc"`: By relevance descending, as determined by the API algorithms. Relevance thresholding of query results is only available with this ordering. * `"posting_publish_time desc"`: By Job.posting_publish_time descending. * `"posting_update_time desc"`: By Job.posting_update_time descending. * `"title"`: By Job.title ascending. * `"title desc"`: By Job.title descending. * `"annualized_base_compensation"`: By job's CompensationInfo.annualized_base_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_base_compensation desc"`: By job's CompensationInfo.annualized_base_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation"`: By job's CompensationInfo.annualized_total_compensation_range ascending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"annualized_total_compensation desc"`: By job's CompensationInfo.annualized_total_compensation_range descending. Jobs whose annualized base compensation is unspecified are put at the end of search results. * `"custom_ranking desc"`: By the relevance score adjusted to the SearchJobsRequest.custom_ranking_info.ranking_expression with weight factor assigned by SearchJobsRequest.custom_ranking_info.importance_level in descending order. * Location sorting: Use the special syntax to order jobs by distance: "`distance_from('Hawaii')`": Order by distance from Hawaii. "`distance_from(19.89, 155.5)`": Order by distance from a coordinate. "`distance_from('Hawaii'), distance_from('Puerto Rico')`": Order by multiple locations. See details below. "`distance_from('Hawaii'), distance_from(19.89, 155.5)`": Order by multiple locations. See details below. The string can have a maximum of 256 characters. When multiple distance centers are provided, a job that is close to any of the distance centers would have a high rank. When a job has multiple locations, the job location closest to one of the distance centers will be used. Jobs that don't have locations will be ranked at the bottom. Distance is calculated with a precision of 11.3 meters (37.4 feet). Diversification strategy is still applied unless explicitly disabled in diversification_level.
  --page-size: int # Optional. A limit on the number of jobs returned in the search results. Increasing this value above the default value of 10 can increase search response time. The value can be between 1 and 100. (format: int32)
  --page-token: string # Optional. The token specifying the current offset within search results. See SearchJobsResponse.next_page_token for an explanation of how to obtain the next set of query results.
  --request-metadata: record # Input only. Meta information related to the job searcher or entity conducting the job search. This information is used to improve the performance of the service. — shape: {deviceInfo?: record, domain?: string, sessionId?: string, userId?: string}
  --require-precise-result-size: oneof<nothing, bool> # This field is deprecated.
  --search-mode: string@search-mode-completer # Optional. Mode of a search. Defaults to SearchMode.JOB_SEARCH.
]: any -> record<broadenedQueryJobsCount: int, estimatedTotalSize: int, histogramQueryResults: table<histogram: record, histogramQuery: string>, histogramResults: record<compensationHistogramResults: list<record>, customAttributeHistogramResults: list<record>, simpleHistogramResults: list<record>>, locationFilters: table<latLng: record, locationType: string, postalAddress: record, radiusInMiles: float>, matchingJobs: table<commuteInfo: record, job: record, jobSummary: string, jobTitleSnippet: string, searchTextSnippet: string>, metadata: record<requestId: string>, nextPageToken: string, spellCorrection: record<corrected: bool, correctedText: string>, totalSize: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v3p1beta1/{parent}/jobs:searchForAlert") $qp)
  let req_body = {"customRankingInfo": $custom_ranking_info, "disableKeywordMatch": $disable_keyword_match, "diversificationLevel": $diversification_level, "enableBroadening": $enable_broadening, "histogramFacets": $histogram_facets, "histogramQueries": $histogram_queries, "jobQuery": $job_query, "jobView": $job_view, "offset": $offset, "orderBy": $order_by, "pageSize": $page_size, "pageToken": $page_token, "requestMetadata": $request_metadata, "requirePreciseResultSize": $require_precise_result_size, "searchMode": $search_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
