# Auto-generated client for Agreements API v0.7.1-beta
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/navigator.rest.swagger.json
# Auth: --token flag or $env.AGREEMENTS_API_TOKEN

const BASE_URL = "https://api.docusign.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGREEMENTS_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.docusign.com" "https://api-d.docusign.com" "https://api-s.docusign.com" "https://api.dev.docusign.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-agreements GetAgreementsList" } } | get name | first)
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

# GET /v1/accounts/{accountId}/agreements
#
# operationId: GetAgreementsList
export def "accounts-agreements GetAgreementsList" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string
  --ctoken: string
  --filter: string # e.g. parties/name_in_agreement eq 'HEALTHEON CORPORATION'
  --qp-sort: string
  --direction: string@direction-completer
  --id: string
  --document-id: string
  --status: string
  --review-status: string
  --review-completed-at: string # format: DateTime
  --partiesname-in-agreement: string
  --metadatacreated-at: string # format: DateTime
  --title: string
  --related-agreement-documentsparent-agreement-document-id: string
  --languages: string
  --provisionseffective-date: string # format: DateTime
  --provisionsexpiration-date: string # format: DateTime
  --provisionsexecution-date: string # format: DateTime
  --provisionsterm-length: string
  --source-name: string
  --source-id: string
]: nothing -> record<data: table<id: string, title: string, file_name: string, document_id: string, type: string, category: string, summary: string, status: string, review_status: string, review_completed_at: string, parties: list, provisions: record, custom_provisions: record, additional_user_defined_data: record, additional_custom_clm_data: record, additional_custom_esign_data: record, related_agreement_documents: record, languages: list, source_name: record, source_id: string, source_account_id: string, linked_data: list, metadata: record, _links: record>, response_metadata: record<page_limit: int, request_id: string, response_timestamp: string, response_duration_ms: int>, _links: record<first: record<href: string>, self: record<href: string>, next: record<href: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ctoken" $ctoken "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "document_id" $document_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "review_status" $review_status "scalar") (serialize-qp "review_completed_at" $review_completed_at "scalar") (serialize-qp "parties.name_in_agreement" $partiesname_in_agreement "scalar") (serialize-qp "metadata.created_at" $metadatacreated_at "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "related_agreement_documents.parent_agreement_document_id" $related_agreement_documentsparent_agreement_document_id "scalar") (serialize-qp "languages" $languages "scalar") (serialize-qp "provisions.effective_date" $provisionseffective_date "scalar") (serialize-qp "provisions.expiration_date" $provisionsexpiration_date "scalar") (serialize-qp "provisions.execution_date" $provisionsexecution_date "scalar") (serialize-qp "provisions.term_length" $provisionsterm_length "scalar") (serialize-qp "source_name" $source_name "scalar") (serialize-qp "source_id" $source_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/accounts/{accountId}/agreements/{agreementId}
#
# operationId: GetAgreement
export def "accounts-agreements GetAgreement" [
  accountId: string
  agreementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, title: string, file_name: string, document_id: string, type: string, category: string, summary: string, status: string, review_status: string, review_completed_at: string, parties: table<id: string, name_in_agreement: string, preferred_name: string>, provisions: record<effective_date: string, expiration_date: string, execution_date: string, term_length: string>, custom_provisions: record, additional_user_defined_data: record, additional_custom_clm_data: record, additional_custom_esign_data: record, related_agreement_documents: record<parent_agreement_document_id: record>, languages: list<string>, source_name: record, source_id: string, source_account_id: string, linked_data: table<application_name: string, object_name: string, record_id: string>, metadata: record<created_at: string, created_by: string, modified_at: string, modified_by: string, request_id: string, response_timestamp: string, response_duration_ms: int>, _links: record<document: record<href: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements/($agreementId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /v1/accounts/{accountId}/agreements/{agreementId}
#
# operationId: DeleteAgreement
export def "accounts-agreements DeleteAgreement" [
  accountId: string
  agreementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements/($agreementId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/accounts/{accountId}/upload/jobs
#
# operationId: createBulkUploadJob
export def "accounts-upload-jobs createBulkUploadJob" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --job-name: string # Name for the new job to be created. If empty, server will auto-create name for the job.
  expected_number_of_docs: int # Number of docs this job will have. Will use provided document_requests size if there is a mismatch. (format: int32)
  --language: string # Language for the user, such as en-US, en-GB, if not provided will default to en-US.
  --agreement-set-ids: list # Optional list of agreement set IDs (21-character NanoID format).
]: any -> record<id: string, external_job_id: string, name: string, status: string, status_enum: list<string>, created_at: string, modified_at: string, expires_at: string, ttl_period: string, _embedded: record<document_status_enum: list<string>, documents: list<record>>, _action_templates: record<upload_document: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>, upload_metadata: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>>, _links: record<self: string>, constraints: record<max_size_mb: int, max_documents_per_job: int, allowed_formats: list<string>, timeout_seconds: int>, metadata: record<request_id: string, response_timestamp: string, response_duration: int>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/upload/jobs")
  let body = {job_name: $job_name, expected_number_of_docs: $expected_number_of_docs, language: $language, agreement_set_ids: $agreement_set_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /v1/accounts/{accountId}/upload/jobs/{jobId}
#
# operationId: getBulkJobStatus
export def "accounts-upload-jobs get" [
  accountId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, external_job_id: string, name: string, status: string, status_enum: list<string>, created_at: string, modified_at: string, expires_at: string, ttl_period: string, _embedded: record<document_status_enum: list<string>, documents: list<record>>, _action_templates: record<upload_document: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>, upload_metadata: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>>, _links: record<self: string>, constraints: record<max_size_mb: int, max_documents_per_job: int, allowed_formats: list<string>, timeout_seconds: int>, metadata: record<request_id: string, response_timestamp: string, response_duration: int>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/upload/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/accounts/{accountId}/upload/jobs/{jobId}/actions/complete
#
# operationId: uploadCompleteBulkJob
export def "accounts-upload-jobs-actions-complete uploadCompleteBulkJob" [
  accountId: string
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, external_job_id: string, name: string, status: string, status_enum: list<string>, created_at: string, modified_at: string, expires_at: string, ttl_period: string, _embedded: record<document_status_enum: list<string>, documents: list<record>>, _action_templates: record<upload_document: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>, upload_metadata: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>>, _links: record<self: string>, constraints: record<max_size_mb: int, max_documents_per_job: int, allowed_formats: list<string>, timeout_seconds: int>, metadata: record<request_id: string, response_timestamp: string, response_duration: int>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/upload/jobs/($jobId)/actions/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
