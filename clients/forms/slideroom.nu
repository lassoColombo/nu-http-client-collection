# Auto-generated client for SlideRoom API V2 vv2
# Source: https://api.apis.guru/v2/specs/slideroom.com/v2/swagger.json
# Auth: --token flag or $env.SLIDEROOM_API_V2_TOKEN

const BASE_URL = "https://api.slideroom.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SLIDEROOM_API_V2_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.slideroom.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def pool-completer [] { ["CommonAppSDS" "Standard"] }
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def format-completer [] { ["csv" "json" "pdf" "tab" "tsv" "txt" "xlsx" "zip"] }
def roundType-completer [] { ["All" "Assigned" "Current" "Named"] }
def pool-completer-1 [] { ["All" "Archived" "CommonAppSDS" "Current"] }
def status-completer [] { ["All" "InProgress" "Submitted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applicant-attributes DeleteAttributesV2" } } | get name | first)
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

# Deletes a custom attribute for an applicant.
#
# DELETE /api/v2/applicant/attributes
# operationId: Applicant_DeleteAttributesV2
export def "applicant-attributes DeleteAttributesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address of the applicant.
  --name: string # The name of the attribute to be deleted.
  --pool: string@pool-completer
  --commonAppYear: int # format: int32
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $commonAppYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the custom attributes for an applicant.
#
# GET /api/v2/applicant/attributes
# operationId: Applicant_GetAttributesV2
export def "applicant-attributes GetAttributesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address of the applicant.
  --pool: string@pool-completer
  --commonAppYear: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $commonAppYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the custom attributes for an applicant.
#
# POST /api/v2/applicant/attributes
# operationId: Applicant_PostAttributesV2
export def "applicant-attributes PostAttributesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address of the applicant.
  --pool: string@pool-completer
  --commonAppYear: int # format: int32
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $commonAppYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the custom applicant attributes used by the organization.
#
# GET /api/v2/applicant/attributes/names
# operationId: Applicant_GetAttributeNamesV2
export def "applicant-attributes-names GetAttributeNamesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/applicant/attributes/names")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the custom application attributes used by the organization.
#
# GET /api/v2/application/attributes/names
# operationId: Application_GetAttributeNamesV2
export def "application-attributes-names GetAttributeNamesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/application/attributes/names")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Requests the generation of application export files (tabular, pdf, zip).
#
# POST /api/v2/application/request-export
# operationId: Application_RequestExportV2
export def "application-request-export RequestExportV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer
  --roundType: string@roundType-completer
  --roundName: string
  --tabexport: string
  --pdfincludeForms: oneof<nothing, bool>
  --pdfincludeReferences: oneof<nothing, bool>
  --pdfincludeMedia: oneof<nothing, bool>
  --pdfincludeApplicantAttachments: oneof<nothing, bool>
  --pdfincludeOrganizationAttachments: oneof<nothing, bool>
  --pdfincludeRatings: oneof<nothing, bool>
  --pdfincludeFullPageMedia: oneof<nothing, bool>
  --pdfincludeHighlights: oneof<nothing, bool>
  --pdfincludeComments: oneof<nothing, bool>
  --pdfincludeCommonApp: oneof<nothing, bool>
  --ziporiginalMedia: oneof<nothing, bool>
  --zipincludeForms: oneof<nothing, bool>
  --zipincludeReferences: oneof<nothing, bool>
  --zipincludeMedia: oneof<nothing, bool>
  --zipincludeApplicantAttachments: oneof<nothing, bool>
  --zipincludeOrganizationAttachments: oneof<nothing, bool>
  --zipincludeRatings: oneof<nothing, bool>
  --zipincludeComments: oneof<nothing, bool>
  --zipincludeCommonApp: oneof<nothing, bool>
  --deliveryaccount: string
  --deliveryfolder: string
  --since: int # format: int32
  --pool: string@pool-completer-1
  --status: string@status-completer
  --searchName: string
  --email: string
]: nothing -> record<message: string, submissions: int, token: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "roundType" $roundType "scalar") (serialize-qp "roundName" $roundName "scalar") (serialize-qp "tab.export" $tabexport "scalar") (serialize-qp "pdf.includeForms" $pdfincludeForms "scalar") (serialize-qp "pdf.includeReferences" $pdfincludeReferences "scalar") (serialize-qp "pdf.includeMedia" $pdfincludeMedia "scalar") (serialize-qp "pdf.includeApplicantAttachments" $pdfincludeApplicantAttachments "scalar") (serialize-qp "pdf.includeOrganizationAttachments" $pdfincludeOrganizationAttachments "scalar") (serialize-qp "pdf.includeRatings" $pdfincludeRatings "scalar") (serialize-qp "pdf.includeFullPageMedia" $pdfincludeFullPageMedia "scalar") (serialize-qp "pdf.includeHighlights" $pdfincludeHighlights "scalar") (serialize-qp "pdf.includeComments" $pdfincludeComments "scalar") (serialize-qp "pdf.includeCommonApp" $pdfincludeCommonApp "scalar") (serialize-qp "zip.originalMedia" $ziporiginalMedia "scalar") (serialize-qp "zip.includeForms" $zipincludeForms "scalar") (serialize-qp "zip.includeReferences" $zipincludeReferences "scalar") (serialize-qp "zip.includeMedia" $zipincludeMedia "scalar") (serialize-qp "zip.includeApplicantAttachments" $zipincludeApplicantAttachments "scalar") (serialize-qp "zip.includeOrganizationAttachments" $zipincludeOrganizationAttachments "scalar") (serialize-qp "zip.includeRatings" $zipincludeRatings "scalar") (serialize-qp "zip.includeComments" $zipincludeComments "scalar") (serialize-qp "zip.includeCommonApp" $zipincludeCommonApp "scalar") (serialize-qp "delivery.account" $deliveryaccount "scalar") (serialize-qp "delivery.folder" $deliveryfolder "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "searchName" $searchName "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/application/request-export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a custom attribute for an application.
#
# DELETE /api/v2/application/{applicationId}/attributes
# operationId: Application_DeleteAttributesV2
export def "application-attributes DeleteAttributesV2" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The name of the attribute to be deleted.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/application/($applicationId)/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the custom attributes for an application.
#
# GET /api/v2/application/{applicationId}/attributes
# operationId: Application_GetAttributesV2
export def "application-attributes GetAttributesV2" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/application/($applicationId)/attributes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the custom attributes for an application. API Import is available in the Advanced Plan.
#
# POST /api/v2/application/{applicationId}/attributes
# operationId: Application_PostAttributesV2
export def "application-attributes PostAttributesV2" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/application/($applicationId)/attributes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Requests the generation of a single application export file (tabular, pdf, zip).
#
# POST /api/v2/application/{applicationId}/request-export
# operationId: Application_RequestExportByApplicationIdV2
export def "application-request-export RequestExportByApplicationIdV2" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer
  --roundType: string@roundType-completer
  --roundName: string
  --tabexport: string
  --pdfincludeForms: oneof<nothing, bool>
  --pdfincludeReferences: oneof<nothing, bool>
  --pdfincludeMedia: oneof<nothing, bool>
  --pdfincludeApplicantAttachments: oneof<nothing, bool>
  --pdfincludeOrganizationAttachments: oneof<nothing, bool>
  --pdfincludeRatings: oneof<nothing, bool>
  --pdfincludeFullPageMedia: oneof<nothing, bool>
  --pdfincludeHighlights: oneof<nothing, bool>
  --pdfincludeComments: oneof<nothing, bool>
  --pdfincludeCommonApp: oneof<nothing, bool>
  --ziporiginalMedia: oneof<nothing, bool>
  --zipincludeForms: oneof<nothing, bool>
  --zipincludeReferences: oneof<nothing, bool>
  --zipincludeMedia: oneof<nothing, bool>
  --zipincludeApplicantAttachments: oneof<nothing, bool>
  --zipincludeOrganizationAttachments: oneof<nothing, bool>
  --zipincludeRatings: oneof<nothing, bool>
  --zipincludeComments: oneof<nothing, bool>
  --zipincludeCommonApp: oneof<nothing, bool>
  --deliveryaccount: string
  --deliveryfolder: string
]: nothing -> record<message: string, submissions: int, token: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "roundType" $roundType "scalar") (serialize-qp "roundName" $roundName "scalar") (serialize-qp "tab.export" $tabexport "scalar") (serialize-qp "pdf.includeForms" $pdfincludeForms "scalar") (serialize-qp "pdf.includeReferences" $pdfincludeReferences "scalar") (serialize-qp "pdf.includeMedia" $pdfincludeMedia "scalar") (serialize-qp "pdf.includeApplicantAttachments" $pdfincludeApplicantAttachments "scalar") (serialize-qp "pdf.includeOrganizationAttachments" $pdfincludeOrganizationAttachments "scalar") (serialize-qp "pdf.includeRatings" $pdfincludeRatings "scalar") (serialize-qp "pdf.includeFullPageMedia" $pdfincludeFullPageMedia "scalar") (serialize-qp "pdf.includeHighlights" $pdfincludeHighlights "scalar") (serialize-qp "pdf.includeComments" $pdfincludeComments "scalar") (serialize-qp "pdf.includeCommonApp" $pdfincludeCommonApp "scalar") (serialize-qp "zip.originalMedia" $ziporiginalMedia "scalar") (serialize-qp "zip.includeForms" $zipincludeForms "scalar") (serialize-qp "zip.includeReferences" $zipincludeReferences "scalar") (serialize-qp "zip.includeMedia" $zipincludeMedia "scalar") (serialize-qp "zip.includeApplicantAttachments" $zipincludeApplicantAttachments "scalar") (serialize-qp "zip.includeOrganizationAttachments" $zipincludeOrganizationAttachments "scalar") (serialize-qp "zip.includeRatings" $zipincludeRatings "scalar") (serialize-qp "zip.includeComments" $zipincludeComments "scalar") (serialize-qp "zip.includeCommonApp" $zipincludeCommonApp "scalar") (serialize-qp "delivery.account" $deliveryaccount "scalar") (serialize-qp "delivery.folder" $deliveryfolder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/application/($applicationId)/request-export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the status/result of a requested export.
#
# GET /api/v2/export/{token}
# operationId: Export_GetV2
export def "export GetV2" [
  token: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_files: int, file_urls: list<string>, status: string, total_files: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/export/($token)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
