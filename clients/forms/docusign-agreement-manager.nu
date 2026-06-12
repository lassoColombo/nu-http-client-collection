# Auto-generated client for Agreement Manager API v1.0.0
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/agreementmanager.rest.swagger-1.0.0.json
# Auth: --token flag or $env.AGREEMENT_MANAGER_API_TOKEN

const BASE_URL = "https://api.docusign.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGREEMENT_MANAGER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.docusign.com" "https://api-d.docusign.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["asc" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  accountId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of items that can be returned in a single page. (nullable, format: int32, default: 25, e.g. 10)
  --ctoken: string # An opaque token that helps retrieve the a page of data. (nullable, e.g. abc123)
  --search: string # OData full-text search expression. Performs a case-insensitive search across agreement text fields including title, type, parties, and provisions.  The search term is matched as a substring against searchable fields. Enclose multi-word terms in double quotes for exact phrase matching.  Examples: - `$search=Acme` — matches agreements mentioning "Acme" in any searchable field - `$search="Non-Disclosure Agreement"` — exact phrase match - `$search=renewal` — matches agreements with "renewal" in title, type, or provisions  **Note**: `$search` can be combined with `$filter` for more targeted results (e.g., `$search=Acme&$filter=status eq 'COMPLETE'`).  (e.g. /agreements?$search=Acme)
  --filter: string # OData filter expression for complex queries. Supports: - Comparison operators: `eq`, `ne`, `gt`, `ge`, `lt`, `le` - Logical operators: `and`, `or` - In operator: `in` (e.g., `type in ('Msa','Sow')`)  **Note**: Use forward slash `/` to navigate nested properties (e.g., `provisions/effective_date`), not dot notation.  Examples: - `status eq 'COMPLETE' and provisions/effective_date ge 2025-01-01` - `parties/name_in_agreement eq 'Acme Corp' or parties/name_in_agreement eq 'Beta Ltd'` - `provisions/renewal_type in ('EVERGREEN','AUTO_RENEW')`  (e.g. parties/name_in_agreement eq 'HEALTHEON CORPORATION')
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
  --include-linked-data: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "ctoken" $ctoken "scalar") (serialize-qp "$search" $search "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "document_id" $document_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "review_status" $review_status "scalar") (serialize-qp "review_completed_at" $review_completed_at "scalar") (serialize-qp "parties.name_in_agreement" $partiesname_in_agreement "scalar") (serialize-qp "metadata.created_at" $metadatacreated_at "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "related_agreement_documents.parent_agreement_document_id" $related_agreement_documentsparent_agreement_document_id "scalar") (serialize-qp "languages" $languages "scalar") (serialize-qp "provisions.effective_date" $provisionseffective_date "scalar") (serialize-qp "provisions.expiration_date" $provisionsexpiration_date "scalar") (serialize-qp "provisions.execution_date" $provisionsexecution_date "scalar") (serialize-qp "provisions.term_length" $provisionsterm_length "scalar") (serialize-qp "source_name" $source_name "scalar") (serialize-qp "source_id" $source_id "scalar") (serialize-qp "include_linked_data" $include_linked_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/accounts/{accountId}/agreements
#
# operationId: PatchAgreementByDocumentId
# --parties item shape: {id: string, name_in_agreement?: string, preferred_name?: string}
# --related_agreement_documents shape: {parent_agreement_document_id?: any}
# --linked_data item shape: {application_name?: string, object_name?: string, record_id?: string}
# --metadata shape: {created_at?: string, created_by?: string, modified_at?: string, modified_by?: string, request_id?: string, response_timestamp?: string, response_duration_ms?: int}
# --_links shape: {document?: record, agreement_types?: any}
# --_actions shape: {change_type?: record}
export def "accounts-agreements PatchAgreementByDocumentId" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-id: string
  id: string # default: 00000000-0000-0000-0000-000000000000
  --title: string # Title of the agreement document, summarizing its purpose. (nullable)
  --file-name: string # The file name of the agreement. (nullable)
  --document-id: string # The id the original agreement document. (nullable)
  --type: string # The type of agreement. (nullable, e.g. Master Service Agreement)
  --category: string # Server-defined category based on the agreement type. (nullable, e.g. BusinessServices)
  --summary: string # A detailed summary of the agreement's key provisions and scope. (nullable, e.g. This Master Service Agreement between Alpha Corp and Beta Ltd. defines the terms for services provided by Alpha Corp, including project scope, payment terms, and dispute resolution.)
  --status: string # Current status of the agreement (e.g., PENDING, COMPLETE, INACTIVE) (nullable)
  --review-status: string # The review status of the agreement, indicating whether it has been complete or pending. (nullable)
  --review-completed-at: string # The date when the agreement extraction review was completed. (nullable, format: date-time)
  --parties: list # A list of parties involved in the agreement. (nullable) — item shape: {id: string, name_in_agreement?: string, preferred_name?: string}
  --provisions: any # "The conditions or rules written in a legal agreement. The set of possible provisions is determined by the agreement type."
  --custom-provisions: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --additional-user-defined-data: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --additional-custom-clm-data: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --additional-custom-esign-data: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --related-agreement-documents: record # shape: {parent_agreement_document_id?: any}
  --languages: list # List of languages applicable to the agreement, identified using BCP-47 language codes. (nullable)
  --source-name: any # The name of the source system which created this agreement, e.g. eSign, CLM, or Salesforce.
  --source-id: string # The ID of the entity in the source system that this entity is associated with. For example, it could be an ID of the envelope in eSign. (nullable, e.g. 8ade6915-d04b-40d6-bb6f-9c6ba6aa1bb5)
  --source-account-id: string # The Account ID of the source system who creates this entity, e.g. eSign Account ID (nullable, e.g. faee2c10-cae6-4d90-ba66-6d6d117d92c5)
  --linked-data: list # item shape: {application_name?: string, object_name?: string, record_id?: string}
  --metadata: record # shape: {created_at?: string, created_by?: string, modified_at?: string, modified_by?: string, request_id?: string, response_timestamp?: string, response_duration_ms?: int}
  --links: record # Hypermedia controls (HATEOAS) for agreement specific links to resources.  (nullable) — shape: {document?: record, agreement_types?: any}
  --actions: record # Available actions on the agreement. Actions are conditionally present based on the current state of the resource.  (nullable) — shape: {change_type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "document_id" $document_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements" $qp)
  let body = {id: $id, title: $title, file_name: $file_name, document_id: $document_id, type: $type, category: $category, summary: $summary, status: $status, review_status: $review_status, review_completed_at: $review_completed_at, parties: $parties, provisions: $provisions, custom_provisions: $custom_provisions, additional_user_defined_data: $additional_user_defined_data, additional_custom_clm_data: $additional_custom_clm_data, additional_custom_esign_data: $additional_custom_esign_data, related_agreement_documents: $related_agreement_documents, languages: $languages, source_name: $source_name, source_id: $source_id, source_account_id: $source_account_id, linked_data: $linked_data, metadata: $metadata, _links: $links, _actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/accounts/{accountId}/agreement-types
#
# operationId: GetAgreementTypes
export def "accounts-agreement-types GetAgreementTypes" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreement-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-linked-data: oneof<nothing, bool> # default: false
]: nothing -> record<id: string, title: string, file_name: string, document_id: string, type: string, category: string, summary: string, status: string, review_status: string, review_completed_at: string, parties: table<id: string, name_in_agreement: string, preferred_name: string>, provisions: record<effective_date: string, expiration_date: string, execution_date: string, term_length: string>, custom_provisions: record, additional_user_defined_data: record, additional_custom_clm_data: record, additional_custom_esign_data: record, related_agreement_documents: record<parent_agreement_document_id: record>, languages: list<string>, source_name: record, source_id: string, source_account_id: string, linked_data: table<application_name: string, object_name: string, record_id: string>, metadata: record<created_at: string, created_by: string, modified_at: string, modified_by: string, request_id: string, response_timestamp: string, response_duration_ms: int>, _links: record<document: record<href: string>, agreement_types: record<href: string>>, _actions: record<change_type: record<href: string, method: string, description: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_linked_data" $include_linked_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements/($agreementId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements/($agreementId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/accounts/{accountId}/agreements/{agreementId}
#
# operationId: PatchAgreement
# --parties item shape: {id: string, name_in_agreement?: string, preferred_name?: string}
# --related_agreement_documents shape: {parent_agreement_document_id?: any}
# --linked_data item shape: {application_name?: string, object_name?: string, record_id?: string}
# --metadata shape: {created_at?: string, created_by?: string, modified_at?: string, modified_by?: string, request_id?: string, response_timestamp?: string, response_duration_ms?: int}
# --_links shape: {document?: record, agreement_types?: any}
# --_actions shape: {change_type?: record}
export def "accounts-agreements PatchAgreement" [
  accountId: string
  agreementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # default: 00000000-0000-0000-0000-000000000000
  --title: string # Title of the agreement document, summarizing its purpose. (nullable)
  --file-name: string # The file name of the agreement. (nullable)
  --document-id: string # The id the original agreement document. (nullable)
  --type: string # The type of agreement. (nullable, e.g. Master Service Agreement)
  --category: string # Server-defined category based on the agreement type. (nullable, e.g. BusinessServices)
  --summary: string # A detailed summary of the agreement's key provisions and scope. (nullable, e.g. This Master Service Agreement between Alpha Corp and Beta Ltd. defines the terms for services provided by Alpha Corp, including project scope, payment terms, and dispute resolution.)
  --status: string # Current status of the agreement (e.g., PENDING, COMPLETE, INACTIVE) (nullable)
  --review-status: string # The review status of the agreement, indicating whether it has been complete or pending. (nullable)
  --review-completed-at: string # The date when the agreement extraction review was completed. (nullable, format: date-time)
  --parties: list # A list of parties involved in the agreement. (nullable) — item shape: {id: string, name_in_agreement?: string, preferred_name?: string}
  --provisions: any # "The conditions or rules written in a legal agreement. The set of possible provisions is determined by the agreement type."
  --custom-provisions: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --additional-user-defined-data: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --additional-custom-clm-data: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --additional-custom-esign-data: record # A generic map/dict. The key is a string, and the value can be of any type, including strings, booleans, numbers, arrays, or objects (nullable)
  --related-agreement-documents: record # shape: {parent_agreement_document_id?: any}
  --languages: list # List of languages applicable to the agreement, identified using BCP-47 language codes. (nullable)
  --source-name: any # The name of the source system which created this agreement, e.g. eSign, CLM, or Salesforce.
  --source-id: string # The ID of the entity in the source system that this entity is associated with. For example, it could be an ID of the envelope in eSign. (nullable, e.g. 8ade6915-d04b-40d6-bb6f-9c6ba6aa1bb5)
  --source-account-id: string # The Account ID of the source system who creates this entity, e.g. eSign Account ID (nullable, e.g. faee2c10-cae6-4d90-ba66-6d6d117d92c5)
  --linked-data: list # item shape: {application_name?: string, object_name?: string, record_id?: string}
  --metadata: record # shape: {created_at?: string, created_by?: string, modified_at?: string, modified_by?: string, request_id?: string, response_timestamp?: string, response_duration_ms?: int}
  --links: record # Hypermedia controls (HATEOAS) for agreement specific links to resources.  (nullable) — shape: {document?: record, agreement_types?: any}
  --actions: record # Available actions on the agreement. Actions are conditionally present based on the current state of the resource.  (nullable) — shape: {change_type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements/($agreementId)")
  let body = {id: $id, title: $title, file_name: $file_name, document_id: $document_id, type: $type, category: $category, summary: $summary, status: $status, review_status: $review_status, review_completed_at: $review_completed_at, parties: $parties, provisions: $provisions, custom_provisions: $custom_provisions, additional_user_defined_data: $additional_user_defined_data, additional_custom_clm_data: $additional_custom_clm_data, additional_custom_esign_data: $additional_custom_esign_data, related_agreement_documents: $related_agreement_documents, languages: $languages, source_name: $source_name, source_id: $source_id, source_account_id: $source_account_id, linked_data: $linked_data, metadata: $metadata, _links: $links, _actions: $actions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /v1/accounts/{accountId}/agreements/{agreementId}/actions/change-type
#
# operationId: ChangeAgreementType
export def "accounts-agreements-actions-change-type ChangeAgreementType" [
  accountId: string
  agreementId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: string # The name of the target agreement type from the agreement-types collection. (e.g. MSA_DOCUMENT_DATA)
]: any -> record<id: string, title: string, type: string, category: string, status: string, metadata: record<created_at: string, created_by: string, modified_at: string, modified_by: string, request_id: string, response_timestamp: string, response_duration_ms: int>, _links: record<self: record<href: string>, collection: record<href: string>, agreement_types: record<href: string>>, _actions: record<change_type: record<href: string, method: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/agreements/($agreementId)/actions/change-type")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-name: string # Name for the new job to be created. If empty, server will auto-create name for the job. (e.g. Q4 2025 Contracts)
  expected_number_of_docs: int # Number of docs this job will have. Will use provided document_requests size if there is a mismatch. (format: int32, e.g. 2)
  --language: string # Language for the user, such as en-US, en-GB, if not provided will default to en-US. (e.g. en-US)
]: any -> record<id: string, external_job_id: string, name: string, status: string, status_enum: list<string>, created_at: string, modified_at: string, expires_at: string, ttl_period: string, _embedded: record<document_status_enum: list<string>, documents: list<record>>, _action_templates: record<upload_document: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>, upload_metadata: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>>, _links: record<self: string>, constraints: record<max_size_mb: int, max_documents_per_job: int, allowed_formats: list<string>, timeout_seconds: int>, metadata: record<request_id: string, response_timestamp: string, response_duration: int>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/upload/jobs")
  let body = {job_name: $job_name, expected_number_of_docs: $expected_number_of_docs, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, external_job_id: string, name: string, status: string, status_enum: list<string>, created_at: string, modified_at: string, expires_at: string, ttl_period: string, _embedded: record<document_status_enum: list<string>, documents: list<record>>, _action_templates: record<upload_document: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>, upload_metadata: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>>, _links: record<self: string>, constraints: record<max_size_mb: int, max_documents_per_job: int, allowed_formats: list<string>, timeout_seconds: int>, metadata: record<request_id: string, response_timestamp: string, response_duration: int>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/upload/jobs/($jobId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, external_job_id: string, name: string, status: string, status_enum: list<string>, created_at: string, modified_at: string, expires_at: string, ttl_period: string, _embedded: record<document_status_enum: list<string>, documents: list<record>>, _action_templates: record<upload_document: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>, upload_metadata: record<method: string, required: bool, description: string, template_variables: record, headers: record, constraints: record, success_status_code: int, error_status_codes: record>>, _links: record<self: string>, constraints: record<max_size_mb: int, max_documents_per_job: int, allowed_formats: list<string>, timeout_seconds: int>, metadata: record<request_id: string, response_timestamp: string, response_duration: int>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/upload/jobs/($jobId)/actions/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
