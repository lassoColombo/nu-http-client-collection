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

def base-url-completer [] { ["https://api.slideroom.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def pool-completer [] { ["CommonAppSDS" "Standard"] }
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def format-completer [] { ["csv" "json" "pdf" "tab" "tsv" "txt" "xlsx" "zip"] }
def round-type-completer [] { ["All" "Assigned" "Current" "Named"] }
def pool-completer-1 [] { ["All" "Archived" "CommonAppSDS" "Current"] }
def status-completer [] { ["All" "InProgress" "Submitted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applicant-attributes delete" } } | get name | first)
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
export def "applicant-attributes delete" [
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
  --common-app-year: int # format: int32
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $common_app_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the custom attributes for an applicant.
#
# GET /api/v2/applicant/attributes
# operationId: Applicant_GetAttributesV2
export def "applicant-attributes get" [
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
  --common-app-year: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $common_app_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the custom attributes for an applicant.
#
# POST /api/v2/applicant/attributes
# operationId: Applicant_PostAttributesV2
export def "applicant-attributes create" [
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
  --common-app-year: int # format: int32
  --body: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $common_app_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the custom applicant attributes used by the organization.
#
# GET /api/v2/applicant/attributes/names
# operationId: Applicant_GetAttributeNamesV2
export def "applicant-attributes-names get" [
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
export def "application-attributes-names get" [
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
export def "application-request-export request" [
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
  --round-type: string@round-type-completer
  --round-name: string
  --tab-export: string
  --pdf-include-forms: oneof<nothing, bool>
  --pdf-include-references: oneof<nothing, bool>
  --pdf-include-media: oneof<nothing, bool>
  --pdf-include-applicant-attachments: oneof<nothing, bool>
  --pdf-include-organization-attachments: oneof<nothing, bool>
  --pdf-include-ratings: oneof<nothing, bool>
  --pdf-include-full-page-media: oneof<nothing, bool>
  --pdf-include-highlights: oneof<nothing, bool>
  --pdf-include-comments: oneof<nothing, bool>
  --pdf-include-common-app: oneof<nothing, bool>
  --zip-original-media: oneof<nothing, bool>
  --zip-include-forms: oneof<nothing, bool>
  --zip-include-references: oneof<nothing, bool>
  --zip-include-media: oneof<nothing, bool>
  --zip-include-applicant-attachments: oneof<nothing, bool>
  --zip-include-organization-attachments: oneof<nothing, bool>
  --zip-include-ratings: oneof<nothing, bool>
  --zip-include-comments: oneof<nothing, bool>
  --zip-include-common-app: oneof<nothing, bool>
  --delivery-account: string
  --delivery-folder: string
  --since: int # format: int32
  --pool: string@pool-completer-1
  --status: string@status-completer
  --search-name: string
  --email: string
]: nothing -> record<message: string, submissions: int, token: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "roundType" $round_type "scalar") (serialize-qp "roundName" $round_name "scalar") (serialize-qp "tab.export" $tab_export "scalar") (serialize-qp "pdf.includeForms" $pdf_include_forms "scalar") (serialize-qp "pdf.includeReferences" $pdf_include_references "scalar") (serialize-qp "pdf.includeMedia" $pdf_include_media "scalar") (serialize-qp "pdf.includeApplicantAttachments" $pdf_include_applicant_attachments "scalar") (serialize-qp "pdf.includeOrganizationAttachments" $pdf_include_organization_attachments "scalar") (serialize-qp "pdf.includeRatings" $pdf_include_ratings "scalar") (serialize-qp "pdf.includeFullPageMedia" $pdf_include_full_page_media "scalar") (serialize-qp "pdf.includeHighlights" $pdf_include_highlights "scalar") (serialize-qp "pdf.includeComments" $pdf_include_comments "scalar") (serialize-qp "pdf.includeCommonApp" $pdf_include_common_app "scalar") (serialize-qp "zip.originalMedia" $zip_original_media "scalar") (serialize-qp "zip.includeForms" $zip_include_forms "scalar") (serialize-qp "zip.includeReferences" $zip_include_references "scalar") (serialize-qp "zip.includeMedia" $zip_include_media "scalar") (serialize-qp "zip.includeApplicantAttachments" $zip_include_applicant_attachments "scalar") (serialize-qp "zip.includeOrganizationAttachments" $zip_include_organization_attachments "scalar") (serialize-qp "zip.includeRatings" $zip_include_ratings "scalar") (serialize-qp "zip.includeComments" $zip_include_comments "scalar") (serialize-qp "zip.includeCommonApp" $zip_include_common_app "scalar") (serialize-qp "delivery.account" $delivery_account "scalar") (serialize-qp "delivery.folder" $delivery_folder "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "searchName" $search_name "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/application/request-export" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a custom attribute for an application.
#
# DELETE /api/v2/application/{applicationId}/attributes
# operationId: Application_DeleteAttributesV2
export def "application-attributes delete" [
  application_id: string
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
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/attributes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the custom attributes for an application.
#
# GET /api/v2/application/{applicationId}/attributes
# operationId: Application_GetAttributesV2
export def "application-attributes get" [
  application_id: string
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
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/attributes"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the custom attributes for an application. API Import is available in the Advanced Plan.
#
# POST /api/v2/application/{applicationId}/attributes
# operationId: Application_PostAttributesV2
export def "application-attributes create" [
  application_id: string
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
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/attributes"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Requests the generation of a single application export file (tabular, pdf, zip).
#
# POST /api/v2/application/{applicationId}/request-export
# operationId: Application_RequestExportByApplicationIdV2
export def "application-request-export request-by-applicationId" [
  application_id: string
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
  --round-type: string@round-type-completer
  --round-name: string
  --tab-export: string
  --pdf-include-forms: oneof<nothing, bool>
  --pdf-include-references: oneof<nothing, bool>
  --pdf-include-media: oneof<nothing, bool>
  --pdf-include-applicant-attachments: oneof<nothing, bool>
  --pdf-include-organization-attachments: oneof<nothing, bool>
  --pdf-include-ratings: oneof<nothing, bool>
  --pdf-include-full-page-media: oneof<nothing, bool>
  --pdf-include-highlights: oneof<nothing, bool>
  --pdf-include-comments: oneof<nothing, bool>
  --pdf-include-common-app: oneof<nothing, bool>
  --zip-original-media: oneof<nothing, bool>
  --zip-include-forms: oneof<nothing, bool>
  --zip-include-references: oneof<nothing, bool>
  --zip-include-media: oneof<nothing, bool>
  --zip-include-applicant-attachments: oneof<nothing, bool>
  --zip-include-organization-attachments: oneof<nothing, bool>
  --zip-include-ratings: oneof<nothing, bool>
  --zip-include-comments: oneof<nothing, bool>
  --zip-include-common-app: oneof<nothing, bool>
  --delivery-account: string
  --delivery-folder: string
]: nothing -> record<message: string, submissions: int, token: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "roundType" $round_type "scalar") (serialize-qp "roundName" $round_name "scalar") (serialize-qp "tab.export" $tab_export "scalar") (serialize-qp "pdf.includeForms" $pdf_include_forms "scalar") (serialize-qp "pdf.includeReferences" $pdf_include_references "scalar") (serialize-qp "pdf.includeMedia" $pdf_include_media "scalar") (serialize-qp "pdf.includeApplicantAttachments" $pdf_include_applicant_attachments "scalar") (serialize-qp "pdf.includeOrganizationAttachments" $pdf_include_organization_attachments "scalar") (serialize-qp "pdf.includeRatings" $pdf_include_ratings "scalar") (serialize-qp "pdf.includeFullPageMedia" $pdf_include_full_page_media "scalar") (serialize-qp "pdf.includeHighlights" $pdf_include_highlights "scalar") (serialize-qp "pdf.includeComments" $pdf_include_comments "scalar") (serialize-qp "pdf.includeCommonApp" $pdf_include_common_app "scalar") (serialize-qp "zip.originalMedia" $zip_original_media "scalar") (serialize-qp "zip.includeForms" $zip_include_forms "scalar") (serialize-qp "zip.includeReferences" $zip_include_references "scalar") (serialize-qp "zip.includeMedia" $zip_include_media "scalar") (serialize-qp "zip.includeApplicantAttachments" $zip_include_applicant_attachments "scalar") (serialize-qp "zip.includeOrganizationAttachments" $zip_include_organization_attachments "scalar") (serialize-qp "zip.includeRatings" $zip_include_ratings "scalar") (serialize-qp "zip.includeComments" $zip_include_comments "scalar") (serialize-qp "zip.includeCommonApp" $zip_include_common_app "scalar") (serialize-qp "delivery.account" $delivery_account "scalar") (serialize-qp "delivery.folder" $delivery_folder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/request-export") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the status/result of a requested export.
#
# GET /api/v2/export/{token}
# operationId: Export_GetV2
export def "export get" [
  token_arg: int
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
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/api/v2/export/{token_arg}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
