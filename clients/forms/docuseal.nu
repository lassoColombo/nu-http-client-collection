# Auto-generated client for DocuSeal API v1.0.0
# Source: https://console.docuseal.com/openapi.json
# Auth: --token flag or $env.DOCUSEAL_API_TOKEN

const BASE_URL = "https://api.docuseal.com"
const DEFAULT_AUTH = "x-auth-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DOCUSEAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-auth-token" => { {headers: {X-Auth-Token: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://api.docuseal.com" "https://api.docuseal.eu"] }
def auth-scheme-completer [] { ["x-auth-token"] }

# Completers for enum parameters
def status-completer [] { ["completed" "declined" "expired" "pending"] }
def order-completer [] { ["preserved" "random"] }
def size-completer [] { ["A0" "A1" "A2" "A3" "A4" "A5" "A6" "Ledger" "Legal" "Letter" "Tabloid"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "templates list" } } | get name | first)
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

# List all templates
#
# GET /templates
# operationId: getTemplates
export def "templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Filter templates based on the name partial match.
  --slug: string # Filter templates by unique slug. (e.g. opaKWh8WWTAcVG)
  --external-id: string # The unique application-specific identifier provided for the template via API or Embedded template form builder. It allows you to receive only templates with your specified external ID.
  --folder: string # Filter templates by folder name.
  --archived: string@bool-completer # Get only archived templates instead of active ones.
  --limit: int # The number of templates to return. Default value is 10. Maximum value is 100.
  --after: int # The unique identifier of the template to start the list from. It allows you to receive only templates with an ID greater than the specified value. Pass ID value from the `pagination.next` response to load the next batch of templates.
  --before: int # The unique identifier of the template to end the list with. It allows you to receive only templates with an ID less than the specified value.
]: nothing -> record<data: table<id: int, slug: string, name: string, preferences: record, schema: list, fields: list, submitters: list, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record, documents: list>, pagination: record<count: int, next: int, prev: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "folder" $folder "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a template
#
# GET /templates/{id}
# operationId: getTemplate
export def "templates get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a template
#
# DELETE /templates/{id}
# operationId: archiveTemplate
export def "templates archiveTemplate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, archived_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a template
#
# PUT /templates/{id}
# operationId: updateTemplate
export def "templates updateTemplate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the template. (e.g. New Document Name)
  --folder-name: string # The folder's name to which the template should be moved. (e.g. New Folder)
  --roles: list # An array of submitter role names to update the template with. (e.g. [Agent, Customer])
  --archived: string@bool-completer # Set `false` to unarchive template.
]: any -> record<id: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)")
  let body = {name: $name, folder_name: $folder_name, roles: $roles, archived: $archived} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all submissions
#
# GET /submissions
# operationId: getSubmissions
export def "submissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template-id: int # The template ID allows you to receive only the submissions created from that specific template.
  --status: string@status-completer # Filter submissions by status.
  --q: string # Filter submissions based on submitter's name, email or phone partial match.
  --slug: string # Filter submissions by unique slug. (e.g. NtLDQM7eJX2ZMd)
  --template-folder: string # Filter submissions by template folder name.
  --archived: string@bool-completer # Returns only archived submissions when `true` and only active submissions when `false`.
  --limit: int # The number of submissions to return. Default value is 10. Maximum value is 100.
  --after: int # The unique identifier of the submission to start the list from. It allows you to receive only submissions with an ID greater than the specified value. Pass ID value from the `pagination.next` response to load the next batch of submissions.
  --before: int # The unique identifier of the submission that marks the end of the list. It allows you to receive only submissions with an ID less than the specified value.
]: nothing -> record<data: table<id: int, name: string, source: string, slug: string, status: string, submitters_order: string, audit_log_url: string, combined_document_url: string, completed_at: string, created_at: string, updated_at: string, archived_at: string, submitters: list, template: record, created_by_user: record>, pagination: record<count: int, next: int, prev: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template_id" $template_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "template_folder" $template_folder "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a submission
#
# POST /submissions
# operationId: createSubmission
# --message shape: {subject?: string, body?: string}
# --submitters item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, message?: record, fields?: list, roles?: list}
export def "submissions createSubmission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_id: int # The unique identifier of the template. Document template forms can be created via the Web UI, <a href="https://www.docuseal.com/guides/use-embedded-text-field-tags-in-the-pdf-to-create-a-fillable-form" class="link">PDF and DOCX API</a>, or <a href="https://www.docuseal.com/guides/create-pdf-document-fillable-form-with-html-api" class="link">HTML API</a>. (e.g. 1000001)
  --send-email: string@bool-completer # Set `false` to disable signature request emails sending. (default: true)
  --send-sms: string@bool-completer # Set `true` to send signature request via phone number and SMS. (default: false)
  --order: string@order-completer # Pass 'random' to send signature request emails to all parties right away. The order is 'preserved' by default so the second party will receive a signature request email only after the document is signed by the first party. (default: preserved)
  --completed-redirect-url: string # Specify URL to redirect to after the submission completion.
  --bcc-completed: string # Specify BCC address to send signed documents to after the completion.
  --reply-to: string # Specify Reply-To address to use in the notification emails.
  --expire-at: string # Specify the expiration date and time after which the submission becomes unavailable for signature. (e.g. 2024-09-01 12:00:00 UTC)
  --body-variables: record # Dynamic content variables object. Variable values can be strings, numbers, arrays, objects, or HTML content used to generate styled text, paragraphs, and tables in dynamic template documents. (e.g. {variable_name: value})
  --message: record # Custom signature request email message. — shape: {subject?: string, body?: string}
  submitters: list # The list of submitters for the submission. — item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, message?: record, fields?: list, roles?: list}
]: any -> table<id: int, submission_id: int, uuid: string, email: string, slug: string, status: string, values: list<record>, metadata: record, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, external_id: string, preferences: record<send_email: bool, send_sms: bool>, role: string, embed_src: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions")
  let body = {template_id: $template_id, send_email: $send_email, send_sms: $send_sms, order: $order, completed_redirect_url: $completed_redirect_url, bcc_completed: $bcc_completed, reply_to: $reply_to, expire_at: $expire_at, variables: $body_variables, message: $message, submitters: $submitters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a submission
#
# GET /submissions/{id}
# operationId: getSubmission
export def "submissions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, slug: string, source: string, submitters_order: string, audit_log_url: string, combined_document_url: string, created_at: string, updated_at: string, archived_at: string, submitters: table<id: int, submission_id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, external_id: string, status: string, values: list, documents: list, role: string>, template: record<id: int, name: string, external_id: string, folder_name: string, created_at: string, updated_at: string>, created_by_user: record<id: int, first_name: string, last_name: string, email: string>, submission_events: table<id: int, submitter_id: int, event_type: string, event_timestamp: string, data: record>, documents: table<name: string, url: string>, status: string, metadata: record, completed_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/submissions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a submission
#
# DELETE /submissions/{id}
# operationId: archiveSubmission
export def "submissions archiveSubmission" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, archived_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/submissions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get submission documents
#
# GET /submissions/{id}/documents
# operationId: getSubmissionDocuments
export def "submissions-documents get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merge: string@bool-completer # When `true`, merges all documents into a single PDF. (default: false, e.g. false)
]: nothing -> record<id: int, documents: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge" $merge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/submissions/($id)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create submissions from emails
#
# POST /submissions/emails
# operationId: createSubmissionsFromEmails
# --message shape: {subject?: string, body?: string}
export def "submissions-emails createSubmissionsFromEmails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_id: int # The unique identifier of the template. (e.g. 1000001)
  emails: string # A comma-separated list of email addresses to send the submission to. (e.g. {{emails}})
  --send-email: string@bool-completer # Set `false` to disable signature request emails sending. (default: true)
  --message: record # Custom signature request email message. — shape: {subject?: string, body?: string}
]: any -> table<id: int, submission_id: int, uuid: string, email: string, slug: string, status: string, values: list<record>, metadata: record, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, external_id: string, preferences: record<send_email: bool, send_sms: bool>, role: string, embed_src: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/emails")
  let body = {template_id: $template_id, emails: $emails, send_email: $send_email, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a submission from PDF
#
# POST /submissions/pdf
# operationId: createSubmissionFromPdf
# --documents item shape: {name: string, file: string, fields?: list, position?: int}
# --submitters item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, invite_by?: string, fields?: list, roles?: list}
# --message shape: {subject?: string, body?: string}
export def "submissions-pdf createSubmissionFromPdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the document submission. (e.g. Test Submission Document)
  --send-email: string@bool-completer # Set `false` to disable signature request emails sending. (default: true)
  --send-sms: string@bool-completer # Set `true` to send signature request via phone number and SMS. (default: false)
  --order: string@order-completer # Pass 'random' to send signature request emails to all parties right away. The order is 'preserved' by default so the second party will receive a signature request email only after the document is signed by the first party. (default: preserved)
  --completed-redirect-url: string # Specify URL to redirect to after the submission completion.
  --bcc-completed: string # Specify BCC address to send signed documents to after the completion.
  --reply-to: string # Specify Reply-To address to use in the notification emails.
  --expire-at: string # Specify the expiration date and time after which the submission becomes unavailable for signature. (e.g. 2024-09-01 12:00:00 UTC)
  --template-ids: list # An optional array of template IDs to use in the submission along with the provided documents. This can be used to create multi-document submissions when some of the required documents exist within templates.
  documents: list # An array of PDF documents to create a submission. — item shape: {name: string, file: string, fields?: list, position?: int}
  submitters: list # The list of submitters for the submission. — item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, invite_by?: string, fields?: list, roles?: list}
  --message: record # Custom signature request email message. — shape: {subject?: string, body?: string}
  --flatten: string@bool-completer # Remove PDF form fields from the documents. (default: false)
  --merge-documents: string@bool-completer # Set `true` to merge the documents into a single PDF file. (default: false)
  --remove-tags: string@bool-completer # Pass `false` to disable the removal of {{text}} tags from the PDF. This can be used along with transparent text tags for faster and more robust PDF processing. (default: true)
]: any -> record<id: int, name: string, submitters: table<id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, external_id: string, status: string, values: list, role: string, metadata: record, preferences: record, embed_src: string>, source: string, submitters_order: string, status: string, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, expire_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/pdf")
  let body = {name: $name, send_email: $send_email, send_sms: $send_sms, order: $order, completed_redirect_url: $completed_redirect_url, bcc_completed: $bcc_completed, reply_to: $reply_to, expire_at: $expire_at, template_ids: $template_ids, documents: $documents, submitters: $submitters, message: $message, flatten: $flatten, merge_documents: $merge_documents, remove_tags: $remove_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a submission from DOCX
#
# POST /submissions/docx
# operationId: createSubmissionFromDocx
# --documents item shape: {name: string, file: string, position?: int}
# --submitters item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, invite_by?: string, fields?: list, roles?: list}
# --message shape: {subject?: string, body?: string}
export def "submissions-docx createSubmissionFromDocx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the document submission. (e.g. Test Submission Document)
  --send-email: string@bool-completer # Set `false` to disable signature request emails sending. (default: true)
  --send-sms: string@bool-completer # Set `true` to send signature request via phone number and SMS. (default: false)
  --body-variables: record # Dynamic content variables object. Variable values can be strings, numbers, arrays, objects, or HTML content used to generate styled text, paragraphs, and tables in DOCX. (e.g. {variable_name: value})
  --order: string@order-completer # Pass 'random' to send signature request emails to all parties right away. The order is 'preserved' by default so the second party will receive a signature request email only after the document is signed by the first party. (default: preserved)
  --completed-redirect-url: string # Specify URL to redirect to after the submission completion.
  --bcc-completed: string # Specify BCC address to send signed documents to after the completion.
  --reply-to: string # Specify Reply-To address to use in the notification emails.
  --expire-at: string # Specify the expiration date and time after which the submission becomes unavailable for signature. (e.g. 2024-09-01 12:00:00 UTC)
  --template-ids: list # An optional array of template IDs to use in the submission along with the provided documents. This can be used to create multi-document submissions when some of the required documents exist within templates.
  documents: list # An array of DOCX documents to create a submission. — item shape: {name: string, file: string, position?: int}
  submitters: list # The list of submitters for the submission. — item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, invite_by?: string, fields?: list, roles?: list}
  --message: record # Custom signature request email message. — shape: {subject?: string, body?: string}
  --merge-documents: string@bool-completer # Set `true` to merge the documents into a single PDF file. (default: false)
  --remove-tags: string@bool-completer # Pass `false` to disable the removal of {{text}} tags from the document. This can be used along with transparent text tags for faster and more robust document processing. (default: true)
]: any -> record<id: int, name: string, submitters: table<id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, external_id: string, status: string, values: list, role: string, metadata: record, preferences: record, embed_src: string>, source: string, submitters_order: string, status: string, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, expire_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/docx")
  let body = {name: $name, send_email: $send_email, send_sms: $send_sms, variables: $body_variables, order: $order, completed_redirect_url: $completed_redirect_url, bcc_completed: $bcc_completed, reply_to: $reply_to, expire_at: $expire_at, template_ids: $template_ids, documents: $documents, submitters: $submitters, message: $message, merge_documents: $merge_documents, remove_tags: $remove_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a submission from HTML
#
# POST /submissions/html
# operationId: createSubmissionFromHtml
# --documents item shape: {name?: string, html: string, html_header?: string, html_footer?: string, size?: "Letter"|"Legal"|"Tabloid"|"Ledger"|"A0"|"A1"|"A2"|"A3"|"A4"|"A5"|"A6", position?: int}
# --submitters item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, invite_by?: string, fields?: list, roles?: list}
# --message shape: {subject?: string, body?: string}
export def "submissions-html createSubmissionFromHtml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the document submission. (e.g. Test Submission Document)
  --send-email: string@bool-completer # Set `false` to disable signature request emails sending. (default: true)
  --send-sms: string@bool-completer # Set `true` to send signature request via phone number and SMS. (default: false)
  --order: string@order-completer # Pass 'random' to send signature request emails to all parties right away. The order is 'preserved' by default so the second party will receive a signature request email only after the document is signed by the first party. (default: preserved)
  --completed-redirect-url: string # Specify URL to redirect to after the submission completion.
  --bcc-completed: string # Specify BCC address to send signed documents to after the completion.
  --reply-to: string # Specify Reply-To address to use in the notification emails.
  --expire-at: string # Specify the expiration date and time after which the submission becomes unavailable for signature. (e.g. 2024-09-01 12:00:00 UTC)
  --template-ids: list # An optional array of template IDs to use in the submission along with the provided documents. This can be used to create multi-document submissions when some of the required documents exist within templates.
  documents: list # The list of documents built from HTML. Can be used to create a submission with multiple documents. — item shape: {name?: string, html: string, html_header?: string, html_footer?: string, size?: "Letter"|"Legal"|"Tabloid"|"Ledger"|"A0"|"A1"|"A2"|"A3"|"A4"|"A5"|"A6", position?: int}
  submitters: list # The list of submitters for the submission. — item shape: {name?: string, role?: string, email?: string, phone?: string, values?: record, external_id?: string, completed?: bool, metadata?: record, send_email?: bool, send_sms?: bool, reply_to?: string, completed_redirect_url?: string, order?: int, require_phone_2fa?: bool, require_email_2fa?: bool, invite_by?: string, fields?: list, roles?: list}
  --message: record # Custom signature request email message. — shape: {subject?: string, body?: string}
  --merge-documents: string@bool-completer # Set `true` to merge the documents into a single PDF file. (default: false)
]: any -> record<id: int, name: string, submitters: table<id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, external_id: string, status: string, values: list, role: string, metadata: record, preferences: record, embed_src: string>, source: string, submitters_order: string, status: string, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, expire_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/submissions/html")
  let body = {name: $name, send_email: $send_email, send_sms: $send_sms, order: $order, completed_redirect_url: $completed_redirect_url, bcc_completed: $bcc_completed, reply_to: $reply_to, expire_at: $expire_at, template_ids: $template_ids, documents: $documents, submitters: $submitters, message: $message, merge_documents: $merge_documents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a submitter
#
# GET /submitters/{id}
# operationId: getSubmitter
export def "submitters get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, submission_id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, status: string, external_id: string, metadata: record, preferences: record, template: record<id: int, name: string, created_at: string, updated_at: string>, submission_events: table<id: int, submitter_id: int, event_type: string, event_timestamp: string, data: record>, values: table<field: string, value: any>, documents: table<name: string, url: string>, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/submitters/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a submitter
#
# PUT /submitters/{id}
# operationId: updateSubmitter
# --message shape: {subject?: string, body?: string}
# --fields item shape: {name: string, default_value?: any, readonly?: bool, required?: bool, validation?: record, preferences?: record}
export def "submitters updateSubmitter" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the submitter.
  --email: string # The email address of the submitter. (format: email, e.g. john.doe@example.com)
  --phone: string # The phone number of the submitter, formatted according to the E.164 standard. (e.g. +1234567890)
  --values: record # An object with pre-filled values for the submission. Use field names for keys of the object. For more configurations see `fields` param.
  --external-id: string # Your application-specific unique string key to identify this submitter within your app.
  --send-email: string@bool-completer # Set `true` to re-send signature request emails.
  --send-sms: string@bool-completer # Set `true` to re-send signature request via phone number SMS. (default: false)
  --reply-to: string # Specify Reply-To address to use in the notification emails.
  --completed: string@bool-completer # Pass `true` to mark submitter as completed and auto-signed via API.
  --metadata: record # Metadata object with additional submitter information. (e.g. { "customField": "value" })
  --completed-redirect-url: string # Submitter specific URL to redirect to after the submission completion.
  --require-phone-2fa: string@bool-completer # Set to `true` to require phone 2FA verification via a one-time code sent to the phone number in order to access the documents. (default: false)
  --require-email-2fa: string@bool-completer # Set to `true` to require email 2FA verification via a one-time code sent to the email address in order to access the documents. (default: false)
  --message: record # Custom signature request email message. — shape: {subject?: string, body?: string}
  --body-fields: list # A list of configurations for template document form fields. — item shape: {name: string, default_value?: any, readonly?: bool, required?: bool, validation?: record, preferences?: record}
]: any -> record<id: int, submission_id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, status: string, external_id: string, metadata: record, preferences: record, values: table<field: string, value: any>, documents: table<name: string, url: string>, role: string, embed_src: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/submitters/($id)")
  let body = {name: $name, email: $email, phone: $phone, values: $values, external_id: $external_id, send_email: $send_email, send_sms: $send_sms, reply_to: $reply_to, completed: $completed, metadata: $metadata, completed_redirect_url: $completed_redirect_url, require_phone_2fa: $require_phone_2fa, require_email_2fa: $require_email_2fa, message: $message, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all submitters
#
# GET /submitters
# operationId: getSubmitters
export def "submitters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --submission-id: int # The submission ID allows you to receive only the submitters related to that specific submission.
  --q: string # Filter submitters on name, email or phone partial match.
  --slug: string # Filter submitters by unique slug. (e.g. zAyL9fH36Havvm)
  --completed-after: string # The date and time string value to filter submitters that completed the submission after the specified date and time. (format: date-time, e.g. 2024-03-05 9:32:20)
  --completed-before: string # The date and time string value to filter submitters that completed the submission before the specified date and time. (format: date-time, e.g. 2024-03-06 19:32:20)
  --external-id: string # The unique application-specific identifier provided for a submitter when initializing a signature request. It allows you to receive only submitters with a specified external ID.
  --limit: int # The number of submitters to return. Default value is 10. Maximum value is 100.
  --after: int # The unique identifier of the submitter to start the list from. It allows you to receive only submitters with an ID greater than the specified value. Pass ID value from the `pagination.next` response to load the next batch of submitters.
  --before: int # The unique identifier of the submitter to end the list with. It allows you to receive only submitters with an ID less than the specified value.
]: nothing -> record<data: table<id: int, submission_id: int, uuid: string, email: string, slug: string, sent_at: string, opened_at: string, completed_at: string, declined_at: string, created_at: string, updated_at: string, name: string, phone: string, status: string, external_id: string, preferences: record, metadata: record, submission_events: list, values: list, documents: list, role: string>, pagination: record<count: int, next: int, prev: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "submission_id" $submission_id "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "slug" $slug "scalar") (serialize-qp "completed_after" $completed_after "scalar") (serialize-qp "completed_before" $completed_before "scalar") (serialize-qp "external_id" $external_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/submitters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template documents
#
# PUT /templates/{id}/documents
# operationId: addDocumentToTemplate
# --documents item shape: {name?: string, file?: string, html?: string, position?: int, replace?: bool, remove?: bool}
export def "templates-documents addDocumentToTemplate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --documents: list # The list of documents to add or replace in the template. — item shape: {name?: string, file?: string, html?: string, position?: int, replace?: bool, remove?: bool}
  --merge: string@bool-completer # Set to `true` to merge all existing and new documents into a single PDF document in the template. (default: false)
]: any -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)/documents")
  let body = {documents: $documents, merge: $merge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Clone a template
#
# POST /templates/{id}/clone
# operationId: cloneTemplate
export def "templates-clone cloneTemplate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Template name. Existing name with (Clone) suffix will be used if not specified. (e.g. Cloned Template)
  --folder-name: string # The folder's name to which the template should be cloned.
  --external-id: string # Your application-specific unique string key to identify this template within your app.
]: any -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/templates/($id)/clone")
  let body = {name: $name, folder_name: $folder_name, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a template from HTML
#
# POST /templates/html
# operationId: createTemplateFromHtml
# --documents item shape: {html: string, name?: string}
export def "templates-html createTemplateFromHtml" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  html: string # HTML template with field tags. (e.g. <p>Lorem Ipsum is simply dummy text of the <text-field   name="Industry"   role="First Party"   required="false"   style="width: 80px; height: 16px; display: inline-block; margin-bottom: -4px"> </text-field> and typesetting industry</p> )
  --html-header: string # HTML template of the header to be displayed on every page.
  --html-footer: string # HTML template of the footer to be displayed on every page.
  --name: string # Template name. Random uuid will be assigned when not specified. (e.g. Test Template)
  --size: string@size-completer # Page size. Letter 8.5 x 11 will be assigned when not specified. (default: Letter, e.g. A4)
  --external-id: string # Your application-specific unique string key to identify this template within your app. Existing template with specified `external_id` will be updated with a new HTML. (e.g. 714d974e-83d8-11ee-b962-0242ac120002)
  --folder-name: string # The folder's name in which the template should be created.
  --shared-link: string@bool-completer # Set to `true` to make the template available via a shared link. This will allow anyone with the link to create a submission from this template. (default: true)
  --documents: list # The list of documents built from HTML. Can be used to create a template with multiple documents. Leave `documents` param empty when using a top-level `html` param for a template with a single document. — item shape: {html: string, name?: string}
]: any -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/html")
  let body = {html: $html, html_header: $html_header, html_footer: $html_footer, name: $name, size: $size, external_id: $external_id, folder_name: $folder_name, shared_link: $shared_link, documents: $documents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a template from Word DOCX
#
# POST /templates/docx
# operationId: createTemplateFromDocx
# --documents item shape: {name: string, file: string, dynamic?: bool, fields?: list}
export def "templates-docx createTemplateFromDocx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the template. (e.g. Test DOCX)
  --external-id: string # Your application-specific unique string key to identify this template within your app. Existing template with specified `external_id` will be updated with a new document. (e.g. unique-key)
  --folder-name: string # The folder's name in which the template should be created.
  --shared-link: string@bool-completer # Set to `true` to make the template available via a shared link. This will allow anyone with the link to create a submission from this template. (default: true)
  documents: list # An array of DOCX documents to create a template. — item shape: {name: string, file: string, dynamic?: bool, fields?: list}
]: any -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/docx")
  let body = {name: $name, external_id: $external_id, folder_name: $folder_name, shared_link: $shared_link, documents: $documents} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a template from PDF
#
# POST /templates/pdf
# operationId: createTemplateFromPdf
# --documents item shape: {name: string, file: string, fields?: list}
export def "templates-pdf createTemplateFromPdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the template. (e.g. Test PDF)
  --folder-name: string # The folder's name in which the template should be created.
  --external-id: string # Your application-specific unique string key to identify this template within your app. Existing template with specified `external_id` will be updated with a new PDF. (e.g. unique-key)
  --shared-link: string@bool-completer # Set to `true` to make the template available via a shared link. This will allow anyone with the link to create a submission from this template. (default: true)
  documents: list # An array of PDF documents to create a template. — item shape: {name: string, file: string, fields?: list}
  --flatten: string@bool-completer # Remove PDF form fields from the documents. (default: false)
  --remove-tags: string@bool-completer # Pass `false` to disable the removal of {{text}} tags from the PDF. This can be used along with transparent text tags for faster and more robust PDF processing. (default: true)
]: any -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/pdf")
  let body = {name: $name, folder_name: $folder_name, external_id: $external_id, shared_link: $shared_link, documents: $documents, flatten: $flatten, remove_tags: $remove_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge templates
#
# POST /templates/merge
# operationId: mergeTemplate
export def "templates-merge mergeTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # An array of template ids to merge into a new template. (e.g. [321, 432])
  --name: string # Template name. Existing name with (Merged) suffix will be used if not specified. (e.g. Merged Template)
  --folder-name: string # The name of the folder in which the merged template should be placed.
  --external-id: string # Your application-specific unique string key to identify this template within your app.
  --shared-link: string@bool-completer # Set to `true` to make the template available via a shared link. This will allow anyone with the link to create a submission from this template. (default: true)
  --roles: list # An array of submitter role names to be used in the merged template. (e.g. [Agent, Customer])
]: any -> record<id: int, slug: string, name: string, preferences: record, schema: table<attachment_uuid: string, name: string>, fields: table<uuid: string, submitter_uuid: string, name: string, type: string, required: bool, preferences: record, areas: list>, submitters: table<name: string, uuid: string>, author_id: int, archived_at: string, created_at: string, updated_at: string, source: string, external_id: string, folder_id: int, folder_name: string, shared_link: bool, author: record<id: int, first_name: string, last_name: string, email: string>, documents: table<id: int, uuid: string, url: string, preview_image_url: string, filename: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/templates/merge")
  let body = {template_ids: $template_ids, name: $name, folder_name: $folder_name, external_id: $external_id, shared_link: $shared_link, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
