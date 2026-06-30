# Auto-generated client for SlideRoom API V2 vv2
# Source: https://api.apis.guru/v2/specs/slideroom.com/v2/swagger.json
# Auth: --token flag or $env.SLIDEROOM_API_V2_TOKEN

const BASE_URL = "https://api.slideroom.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SLIDEROOM_API_V2_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address of the applicant.
  --name: string # The name of the attribute to be deleted.
  --pool: string@pool-completer
  --common-app-year: int # format: int32
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $common_app_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"email": $email, "name": $name, "pool": $pool, "commonAppYear": $common_app_year} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address of the applicant.
  --pool: string@pool-completer
  --common-app-year: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $common_app_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"email": $email, "pool": $pool, "commonAppYear": $common_app_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The email address of the applicant.
  --pool: string@pool-completer
  --common-app-year: int # format: int32
  --body: record
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "pool" $pool "scalar") (serialize-qp "commonAppYear" $common_app_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/applicant/attributes" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"email": $email, "pool": $pool, "commonAppYear": $common_app_year} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/applicant/attributes/names" $auth.query)
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/application/attributes/names" $auth.query)
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/api/v2/application/request-export" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"format": $format, "roundType": $round_type, "roundName": $round_name, "tab.export": $tab_export, "pdf.includeForms": $pdf_include_forms, "pdf.includeReferences": $pdf_include_references, "pdf.includeMedia": $pdf_include_media, "pdf.includeApplicantAttachments": $pdf_include_applicant_attachments, "pdf.includeOrganizationAttachments": $pdf_include_organization_attachments, "pdf.includeRatings": $pdf_include_ratings, "pdf.includeFullPageMedia": $pdf_include_full_page_media, "pdf.includeHighlights": $pdf_include_highlights, "pdf.includeComments": $pdf_include_comments, "pdf.includeCommonApp": $pdf_include_common_app, "zip.originalMedia": $zip_original_media, "zip.includeForms": $zip_include_forms, "zip.includeReferences": $zip_include_references, "zip.includeMedia": $zip_include_media, "zip.includeApplicantAttachments": $zip_include_applicant_attachments, "zip.includeOrganizationAttachments": $zip_include_organization_attachments, "zip.includeRatings": $zip_include_ratings, "zip.includeComments": $zip_include_comments, "zip.includeCommonApp": $zip_include_common_app, "delivery.account": $delivery_account, "delivery.folder": $delivery_folder, "since": $since, "pool": $pool, "status": $status, "searchName": $search_name, "email": $email} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The name of the attribute to be deleted.
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/attributes") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/attributes") $auth.query)
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/attributes") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests the generation of a single application export file (tabular, pdf, zip).
#
# POST /api/v2/application/{applicationId}/request-export
# operationId: Application_RequestExportByApplicationIdV2
export def "application-request-export request-by-application-id" [
  application_id: string
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
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "roundType" $round_type "scalar") (serialize-qp "roundName" $round_name "scalar") (serialize-qp "tab.export" $tab_export "scalar") (serialize-qp "pdf.includeForms" $pdf_include_forms "scalar") (serialize-qp "pdf.includeReferences" $pdf_include_references "scalar") (serialize-qp "pdf.includeMedia" $pdf_include_media "scalar") (serialize-qp "pdf.includeApplicantAttachments" $pdf_include_applicant_attachments "scalar") (serialize-qp "pdf.includeOrganizationAttachments" $pdf_include_organization_attachments "scalar") (serialize-qp "pdf.includeRatings" $pdf_include_ratings "scalar") (serialize-qp "pdf.includeFullPageMedia" $pdf_include_full_page_media "scalar") (serialize-qp "pdf.includeHighlights" $pdf_include_highlights "scalar") (serialize-qp "pdf.includeComments" $pdf_include_comments "scalar") (serialize-qp "pdf.includeCommonApp" $pdf_include_common_app "scalar") (serialize-qp "zip.originalMedia" $zip_original_media "scalar") (serialize-qp "zip.includeForms" $zip_include_forms "scalar") (serialize-qp "zip.includeReferences" $zip_include_references "scalar") (serialize-qp "zip.includeMedia" $zip_include_media "scalar") (serialize-qp "zip.includeApplicantAttachments" $zip_include_applicant_attachments "scalar") (serialize-qp "zip.includeOrganizationAttachments" $zip_include_organization_attachments "scalar") (serialize-qp "zip.includeRatings" $zip_include_ratings "scalar") (serialize-qp "zip.includeComments" $zip_include_comments "scalar") (serialize-qp "zip.includeCommonApp" $zip_include_common_app "scalar") (serialize-qp "delivery.account" $delivery_account "scalar") (serialize-qp "delivery.folder" $delivery_folder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/api/v2/application/{application_id}/request-export") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"format": $format, "roundType": $round_type, "roundName": $round_name, "tab.export": $tab_export, "pdf.includeForms": $pdf_include_forms, "pdf.includeReferences": $pdf_include_references, "pdf.includeMedia": $pdf_include_media, "pdf.includeApplicantAttachments": $pdf_include_applicant_attachments, "pdf.includeOrganizationAttachments": $pdf_include_organization_attachments, "pdf.includeRatings": $pdf_include_ratings, "pdf.includeFullPageMedia": $pdf_include_full_page_media, "pdf.includeHighlights": $pdf_include_highlights, "pdf.includeComments": $pdf_include_comments, "pdf.includeCommonApp": $pdf_include_common_app, "zip.originalMedia": $zip_original_media, "zip.includeForms": $zip_include_forms, "zip.includeReferences": $zip_include_references, "zip.includeMedia": $zip_include_media, "zip.includeApplicantAttachments": $zip_include_applicant_attachments, "zip.includeOrganizationAttachments": $zip_include_organization_attachments, "zip.includeRatings": $zip_include_ratings, "zip.includeComments": $zip_include_comments, "zip.includeCommonApp": $zip_include_common_app, "delivery.account": $delivery_account, "delivery.folder": $delivery_folder} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<completed_files: int, file_urls: list<string>, status: string, total_files: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/api/v2/export/{token_arg}") $auth.query)
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
