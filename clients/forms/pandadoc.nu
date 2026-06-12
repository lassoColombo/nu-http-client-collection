# Auto-generated client for PandaDoc Public API v7.30.3
# Source: https://raw.githubusercontent.com/PandaDoc/pandadoc-openapi-specification/main/openapi.yaml
# Auth: --token flag or $env.PANDADOC_PUBLIC_API_TOKEN

const BASE_URL = "https://api.pandadoc.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PANDADOC_PUBLIC_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.pandadoc.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-by-completer [] { ["-date_completed" "-date_created" "-date_declined" "-date_expiration" "-date_modified" "-date_of_last_action" "-date_sent" "-date_status_changed" "-name" "-status" "date_completed" "date_created" "date_declined" "date_expiration" "date_modified" "date_of_last_action" "date_sent" "date_status_changed" "name" "status"] }
def status-completer [] { ["0" "1" "10" "11" "12" "13" "2" "3" "4" "5" "6" "7" "8" "9"] }
def status-ne-completer [] { ["0" "1" "10" "11" "12" "13" "2" "3" "4" "5" "6" "7" "8" "9"] }
def delivery-method-completer [] { ["email" "sms"] }
def status-completer-1 [] { ["10" "11" "12" "2"] }
def language-completer [] { ["bg-BG" "cs-CZ" "da-DK" "de-DE" "el-GR" "en-US" "es-ES" "fr-FR" "hu-HU" "it-IT" "nb-NO" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "sv-SE"] }
def kind-completer [] { ["contact" "contact_group"] }
def merge-field-scope-completer [] { ["document" "upload"] }
def order-by-completer-1 [] { ["created_date" "modified_date" "name" "responses" "status"] }
def environment-type-completer [] { ["PRODUCTION" "SANDBOX"] }
def order-by-completer-2 [] { ["-email" "-name" "-status" "email" "name" "status"] }
def order-by-completer-3 [] { ["-date_completed" "-date_created" "-status" "date_completed" "date_created" "status"] }
def order-by-completer-4 [] { ["-date_modified" "-price" "-sku" "-title" "date_modified" "price" "sku" "title"] }
def type-completer [] { ["bundle" "regular"] }
def license-completer [] { ["Creator" "Full" "Guest" "Read-only" "eSign"] }
def role-completer [] { ["Admin" "Collaborator" "Manager" "Member"] }
def type-completer-1 [] { ["production" "sandbox"] }
def type-completer-2 [] { ["detailed" "headline" "short" "xshort"] }
def format-completer [] { ["markdown" "plaintext"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "oauth2-access-token accessToken" } } | get name | first)
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

# Create/Refresh Access Token
#
# POST /oauth2/access_token
# operationId: accessToken
export def "oauth2-access-token accessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --grant-type: string # This value must be set to `authorization_code`. (default: authorization_code)
  --client-id: string # Client ID that is automatically generated after application creation in the Developer Dashboard. (e.g. 479a3c7ba4a8d3cf28702)
  --client-secret: string # Client secret that is automatically generated after application creation in the Developer Dashboard. (e.g. a66515d3caf9183b8cad3eee546bcba892b45b01)
  --code: string # `auth_code` from the server on the previous step (Authorize a PandaDoc User).  (e.g. a9a60d4dabb61ade665c712d2b41766e7bb9a2f9)
  --scope: string # Requested permissions. Use `read+write` to create, send, delete, and download documents, and `read` to view templates and document details. (e.g. read+write)
  --refresh-token: string # `refresh_token` you received and stored from the server when initially creating an `access_token`.  (e.g. f61cc0cffd437c9a596f0acc8eb6f502a7a429d7)
]: any -> record<access_token: string, token_type: string, expires_in: float, scope: string, refresh_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/access_token")
  let body = {grant_type: $grant_type, client_id: $client_id, client_secret: $client_secret, code: $code, scope: $scope, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List Documents
#
# GET /public/v1/documents
# operationId: listDocuments
export def "public-documents listDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --template-id: string # Filters by parent template. This Parameter can't be used with form_id. (e.g. BhVzRcxH9Z2LgfPPGXFUBa)
  --form-id: string # Filters by parent form. This parameter can't be used with template_id. (e.g. BhVzRcxH9Z2LgfPPGXFUBa)
  --folder-uuid: string # Filters by the folder where the documents are stored. (e.g. BhVzRcxH9Z2LgfPPGXFUBa)
  --contact-id: string # Filters by recipient or approver with this 'contact_id'. (e.g. 9FeAY2NB3C9qDdtQRb4tTL)
  --count: int # Limits the size of the response. Default is 50 documents, maximum is 100 documents. (e.g. 50)
  --page: int # Paginates the search result. Increase value to get the next page of results. (e.g. 1)
  --order-by: string@order-by-completer # Defines the sorting of the result. Use `date_created` for ASC and `-date_created` for DESC sorting. (default: date_status_changed)
  --created-from: string # Limits results to the documents with the `date_created` greater than or equal to this value. (format: datetime, e.g. 2024-10-27T15:22:23.132757Z)
  --created-to: string # Limits results to the documents with the `date_created` less than this value. (format: datetime, e.g. 2024-10-27T15:22:23.132757Z)
  --deleted: oneof<nothing, bool> # Returns only the deleted documents. (e.g. false)
  --id: string # e.g. BhVzRcxH9Z2LgfPPGXFUBa
  --completed-from: string # Limits results to the documents with the `date_completed` greater than or equal to this value. (format: datetime, e.g. 2024-10-27T15:22:23.132757Z)
  --completed-to: string # Limits results to the documents with the `date_completed` less than this value. (format: datetime, e.g. 2024-10-27T15:22:23.132757Z)
  --membership-id: string # Filter documents by the owner's 'membership_id'. (e.g. BhVzRcxH9Z2LgfPPGXFUBa)
  --metadata: list # Filters documents by metadata. Pass metadata in the format of `metadata_{metadata-key}={metadata-value}` such as `metadata_opportunity_id=2181432`. The `metadata_` prefix is always required. (e.g. [metadata_opportunity_id=2181432, metadata_custom_key=custom_value])
  --modified-from: string # Limits results to the documents with the `date_modified` greater than or equal to this value. (format: datetime, e.g. 2024-10-27T15:22:23.132757Z)
  --modified-to: string # Limits results to the documents with the `date_modified` less than this value. (format: datetime, e.g. 2024-10-27T15:22:23.132757Z)
  --q: string # Filters documents by name or reference number (stored on the template level). (e.g. Sample Document)
  --status: int@status-completer # Filters documents by the status.   * 0: document.draft   * 1: document.sent   * 2: document.completed   * 3: document.uploaded   * 4: document.error   * 5: document.viewed   * 6: document.waiting_approval   * 7: document.approved   * 8: document.rejected   * 9: document.waiting_pay   * 10: document.paid   * 11: document.voided   * 12: document.declined   * 13: document.external_review  (e.g. 12)
  --status-ne: int@status-ne-completer # Exludes documents with this status.   * 0: document.draft   * 1: document.sent   * 2: document.completed   * 3: document.uploaded   * 4: document.error   * 5: document.viewed   * 6: document.waiting_approval   * 7: document.approved   * 8: document.rejected   * 9: document.waiting_pay   * 10: document.paid   * 11: document.voided   * 12: document.declined   * 13: document.external_review  (e.g. 12)
  --tag: string # Filters documents by tag. (e.g. tag_1)
]: nothing -> record<results: table<id: string, name: string, status: string, date_created: string, date_modified: string, date_completed: string, expiration_date: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "template_id" $template_id "scalar") (serialize-qp "form_id" $form_id "scalar") (serialize-qp "folder_uuid" $folder_uuid "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "created_from" $created_from "scalar") (serialize-qp "created_to" $created_to "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "completed_from" $completed_from "scalar") (serialize-qp "completed_to" $completed_to "scalar") (serialize-qp "membership_id" $membership_id "scalar") (serialize-qp "metadata" $metadata "multi") (serialize-qp "modified_from" $modified_from "scalar") (serialize-qp "modified_to" $modified_to "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "status__ne" $status_ne "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Document
#
# POST /public/v1/documents
# operationId: createDocument
# --images item shape: {urls: list, name: string}
# --pricing_tables item shape: {name: string, data_merge?: bool, options?: record, sections?: list}
# --tables item shape: {name: string, data: record}
# --texts item shape: {name: string, data: string}
# --content_placeholders item shape: {content_library_items?: list, block_id: string}
# --owner shape: {email?: string, membership_id?: string}
# --tokens item shape: {name: string, value: string}
@deprecated --flag editor-ver
export def "public-documents createDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --editor-ver: string # Set this parameter as `ev1` if you want to create a document from PDF with Classic Editor when both editors are enabled for the workspace. (DEPRECATED, e.g. ev2)
  --use-form-field-properties: string # Set this parameter as `yes` or `1` or `true` (only when upload pdf with form fields) if you want to  respect form fields properties, like `required`. (e.g. true)
  --template-uuid: string # The ID of a template you want to use. You can copy it from an in app template url such as `https://app.pandadoc.com/a/#/templates/{ID}/content`. A template ID is also obtained by listing templates. (e.g. hryJY9mqYZHjQCYQuSjRQg)
  --body-fields: record # Set specific values to the fields. This object maps merge field names to their corresponding values.  Each key represents a merge field name, and each value is an object containing the data to populate that field with. The structure allows you to pre-populate various field types including text inputs, checkboxes, dropdowns, and date fields.  **Key Points:** - Keys must match the exact merge field names from your template or file. - Values must be wrapped in an object with a `value` property. - Supported value types: string, number, boolean. - Date fields should use RFC 3339 format (e.g., '2019-12-31T00:00:00.000Z'). - Signature fields cannot be pre-filled.  **Example Usage:** - Text field: `"CustomerName": {"value": "John Doe"}` - Checkbox: `"AgreeToTerms": {"value": true}` - Date field: `"DeliveryDate": {"value": "2019-12-31T00:00:00.000Z"}`  (e.g. {Like: {value: true}, Delivery: {value: Same Day Delivery}, Date: {value: 2019-12-31T00:00:00.000Z}})
  --images: list # You can pass a list of images to image blocks (one image in one block) for replacement. — item shape: {urls: list, name: string}
  --pricing-tables: list # Information to construct or populate a pricing table can be passed when creating a document. All product information must be passed when creating a new document. Products stored in PandaDoc cannot be used to populate table rows at this time. Keep in mind that this is an array, so multiple table objects can be passed to a document. Make sure that "Automatically add products to this table" is enabled in the PandaDoc template pricing tables you wish to populate via API. — item shape: {name: string, data_merge?: bool, options?: record, sections?: list}
  --tables: list # Information to construct or populate a table can be passed when creating a document. Keep in mind that this is an array, so multiple table objects can be passed to a document. — item shape: {name: string, data: record}
  --texts: list # You can pass a list of rich text values to pre-fill text blocks in a template. This is useful for inserting dynamic content like introductions or terms and conditions. Markdown is supported. — item shape: {name: string, data: string}
  --detect-title-variables: oneof<nothing, bool> # Set this parameter as true if you want to detect title variables in the document. (e.g. true)
  --content-placeholders: list # You may replace Content Library Item Placeholders with a few content library items each and pre-fill fields/variables values, pricing table items, and assign recipients to roles from there. — item shape: {content_library_items?: list, block_id: string}
  --name: string # Name the document you are creating. (e.g. API Sample Document from PandaDoc Template)
  --folder-uuid: string # ID of the folder where the created document should be stored. (e.g. QMDSzwabfFzTgjW4kUijqQ)
  --owner: record # The owner of the document. Pass either `email` or `membership_id` of the user in the workspace. (e.g. {membership_id: QMDSzwabfFzTgjW6KijHyu}) — shape: {email?: string, membership_id?: string}
  --recipients: list # The list of recipients to whom the document will be sent. Either `email` or `phone` is required. Specifying the `role` assigns all matching fields to the recipient or group. If `first_name` and `last_name` are not specified, the system looks them up in the workspace contacts list using the `email` or `phone number`. If `first_name` and `last_name` are provided, they override the existing contact's data.
  --tokens: list # Also known as variables. Pass values for the variables in the template to render them into the created document or make them available for insertion later. — item shape: {name: string, value: string}
  --metadata: record # You can pass any data in a key-value format to associate it with a document. Searching by metadata is available in the List Documents endpoint and is also included in the Document Details response. (nullable, e.g. {lead_id: 1234567, lead_source: PandaDoc})
  --tags: list # Mark your document with one or more tags. Tags are displayed in the UI, and you can filter by tags in the List Documents endpoint. (e.g. [created_via_api, test_document, created_from_source])
]: any -> record<id: string, name: string, status: string, date_created: string, date_modified: string, expiration_date: string, version: string, uuid: string, links: table<rel: string, href: string, type: string>, info_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editor_ver" $editor_ver "scalar") (serialize-qp "use_form_field_properties" $use_form_field_properties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/documents" $qp)
  let body = {template_uuid: $template_uuid, fields: $body_fields, images: $images, pricing_tables: $pricing_tables, tables: $tables, texts: $texts, detect_title_variables: $detect_title_variables, content_placeholders: $content_placeholders, name: $name, folder_uuid: $folder_uuid, owner: $owner, recipients: $recipients, tokens: $tokens, metadata: $metadata, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete documents (bulk)
#
# DELETE /public/v1/documents
# operationId: bulkDeleteDocuments
export def "public-documents bulkDeleteDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/documents")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Document from File Upload
#
# POST /public/v1/documents?upload
# operationId: createDocumentFromUpload
# --data shape: {parse_form_fields?: bool, fields?: record, name: string, folder_uuid?: string, owner?: record, recipients?: list, tokens?: list, metadata?: record, tags?: list}
@deprecated --flag editor-ver
export def "public-documents-upload createDocumentFromUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --editor-ver: string # Set this parameter as `ev1` if you want to create a document from PDF with Classic Editor when both editors are enabled for the workspace. (DEPRECATED, e.g. ev2)
  --use-form-field-properties: string # Set this parameter as `yes` or `1` or `true` (only when upload pdf with form fields) if you want to  respect form fields properties, like `required`. (e.g. true)
  --file: string # Binary PDF File (format: binary)
  --data: record # shape: {parse_form_fields?: bool, fields?: record, name: string, folder_uuid?: string, owner?: record, recipients?: list, tokens?: list, metadata?: record, tags?: list}
]: any -> record<id: string, name: string, status: string, date_created: string, date_modified: string, expiration_date: string, version: string, uuid: string, links: table<rel: string, href: string, type: string>, info_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "editor_ver" $editor_ver "scalar") (serialize-qp "use_form_field_properties" $use_form_field_properties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/documents?upload" $qp)
  let body = {file: $file, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create Document from Markdown File Upload
#
# POST /public/v1/documents?upload-markdown
# operationId: createDocumentFromMarkdownUpload
# --data shape: {name: string, folder_uuid?: string, owner?: record, recipients?: list, tokens?: list, metadata?: record, tags?: list, fields_mapping?: record}
export def "public-documents-upload-markdown createDocumentFromMarkdownUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # The Markdown file to upload.  Accepted content types: `text/markdown`, `text/x-markdown`.  (format: binary)
  --data: record # Request body for creating a document from an uploaded Markdown file.  > **Alpha:** Markdown file upload is currently in alpha. This functionality may change or be removed without notice. — shape: {name: string, folder_uuid?: string, owner?: record, recipients?: list, tokens?: list, metadata?: record, tags?: list, fields_mapping?: record}
]: any -> record<id: string, name: string, status: string, date_created: string, date_modified: string, expiration_date: string, version: string, uuid: string, links: table<rel: string, href: string, type: string>, info_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/documents?upload-markdown")
  let body = {file: $file, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Document Status
#
# GET /public/v1/documents/{id}
# operationId: statusDocument
export def "public-documents statusDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, status: string, date_created: string, date_modified: string, date_completed: string, expiration_date: string, version: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Document
#
# DELETE /public/v1/documents/{id}
# operationId: deleteDocument
export def "public-documents delete" [
  id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Document
#
# PATCH /public/v1/documents/{id}
# operationId: updateDocument
# --tokens item shape: {name: string, value: string}
# --pricing_tables item shape: {name: string, data_merge?: bool, options?: record, sections?: list}
# --tables item shape: {name: string, data: record}
# --images item shape: {urls: list, name: string}
# --texts item shape: {name: string, data: string}
export def "public-documents updateDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the document. (e.g. Contract)
  --recipients: list # The list of recipients you're sending the document to. The ID or email are required. If the ID is passed, an existing recipient will be updated. If the email is passed, a new recipient will be added to CC.
  --body-fields: record # Set specific values to the fields. This object maps merge field names to their corresponding values.  Each key represents a merge field name, and each value is an object containing the data to populate that field with. The structure allows you to pre-populate various field types including text inputs, checkboxes, dropdowns, and date fields.  **Key Points:** - Keys must match the exact merge field names from your template or file. - Values must be wrapped in an object with a `value` property. - Supported value types: string, number, boolean. - Date fields should use RFC 3339 format (e.g., '2019-12-31T00:00:00.000Z'). - Signature fields cannot be pre-filled.  **Example Usage:** - Text field: `"CustomerName": {"value": "John Doe"}` - Checkbox: `"AgreeToTerms": {"value": true}` - Date field: `"DeliveryDate": {"value": "2019-12-31T00:00:00.000Z"}`  (e.g. {Like: {value: true}, Delivery: {value: Same Day Delivery}, Date: {value: 2019-12-31T00:00:00.000Z}})
  --tokens: list # Create or initialize multiple variables with their values using tokens/values list. — item shape: {name: string, value: string}
  --tags: list # Mark your document with one or several tags. (e.g. [updated_via_api, test_document])
  --metadata: record # You can pass arbitrary data in the key-value format to associate custom information with a document. This information is returned in any API requests for the document details by id. If metadata exists in a document then the value will be updated. Otherwise, metadata will be added to the document. (e.g. {my_favorite_pet: Cat})
  --pricing-tables: list # item shape: {name: string, data_merge?: bool, options?: record, sections?: list}
  --tables: list # item shape: {name: string, data: record}
  --images: list # You can pass a list of images to image blocks (one image in one block) for replacement. — item shape: {urls: list, name: string}
  --texts: list # You can pass a list of texts to text blocks for replacement. — item shape: {name: string, data: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)")
  let body = {name: $name, recipients: $recipients, fields: $body_fields, tokens: $tokens, tags: $tags, metadata: $metadata, pricing_tables: $pricing_tables, tables: $tables, images: $images, texts: $texts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Document Auto Reminder Settings
#
# PATCH /public/v1/documents/{document_id}/auto-reminders
# operationId: updateDocumentAutoReminderSettings
export def "public-documents-auto-reminders updateDocumentAutoReminderSettings" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: oneof<nothing, bool> # Toggles auto-reminders for the document.  If `true`, reminders are scheduled based on the configuration.
  --delivery-method: string@delivery-method-completer # The method used to deliver reminders (e.g., email, SMS).
  --initial-delay-days: int # Number of days to wait after sending the document before the first reminder is sent.
  --is-recurring: oneof<nothing, bool> # If `true`, reminders will be sent repeatedly at specified intervals after the initial reminder.
  --recurrence-frequency-days: int # Number of days between recurring reminders, applicable if `is_recurring` is `true`.
]: any -> record<enabled: bool, delivery_method: string, initial_delay_days: int, is_recurring: bool, recurrence_frequency_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/auto-reminders")
  let body = {enabled: $enabled, delivery_method: $delivery_method, initial_delay_days: $initial_delay_days, is_recurring: $is_recurring, recurrence_frequency_days: $recurrence_frequency_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Document Auto Reminder Settings
#
# GET /public/v1/documents/{document_id}/auto-reminders
# operationId: getDocumentAutoReminderSettings
export def "public-documents-auto-reminders get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, delivery_method: string, initial_delay_days: int, is_recurring: bool, recurrence_frequency_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/auto-reminders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Document Auto Reminder Status
#
# GET /public/v1/documents/{document_id}/auto-reminders/status
# operationId: statusDocumentAutoReminder
export def "public-documents-auto-reminders-status statusDocumentAutoReminder" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: table<recipient_id: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/auto-reminders/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Document eSign disclosure
#
# GET /public/v1/documents/{document_id}/esign-disclosure
# operationId: documentESignDisclosure
export def "public-documents-esign-disclosure documentESignDisclosure" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<result: record<is_enabled: bool, company_name: string, esign_disclosure_text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/esign-disclosure")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Document Status Change
#
# PATCH /public/v1/documents/{id}/status
# operationId: changeDocumentStatus
export def "public-documents-status changeDocumentStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: int@status-completer-1 # Number code for the target document status. See notes for the codes corresponding to each status. (e.g. 12)
  --note: string # Provide “private notes” regarding the manual status change. (e.g. A private note)
  --notify-recipients: oneof<nothing, bool> # Send a notification email about the status change to all recipients.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/status")
  let body = {status: $status, note: $note, notify_recipients: $notify_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Document Status Change with Upload
#
# PATCH /public/v1/documents/{id}/status?upload
# operationId: changeDocumentStatusWithUpload
export def "public-documents-status-upload changeDocumentStatusWithUpload" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # Binary attachment file (format: binary)
  --data: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/status?upload")
  let body = {file: $file, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Move Document to Draft
#
# POST /public/v1/documents/{id}/draft
# operationId: documentRevertToDraft
export def "public-documents-draft documentRevertToDraft" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, status: string, date_created: string, date_modified: string, expiration_date: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/draft")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Document Details
#
# GET /public/v1/documents/{id}/details
# operationId: detailsDocument
export def "public-documents-details detailsDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, autonumbering_sequence_name_prefix: any, folder_uuid: string, date_created: string, date_modified: string, date_completed: string, content_date_modified: string, date_sent: string, ref_number: string, created_by: record<id: string, membership_id: string, email: string, first_name: string, last_name: string, avatar: string>, template: record<id: string, name: string>, expiration_date: string, metadata: record, tokens: list<record>, fields: list<any>, pricing: record<tables: list<record>, quotes: list<record>, total: string>, tables: table<name: string>, images: table<name: string>, texts: table<name: string>, tags: list<string>, sent_by: any, recipients: list<record>, grand_total: record<amount: string, currency: string>, linked_objects: table<provider: string, entity_type: string, entity_id: string, id: string, children: list>, status: string, approval_execution: record<document_uuid: string, revision_number: int>, version: string, lock: record<locked_by_user_id: string, lock_type: string, expires_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Document
#
# POST /public/v1/documents/{id}/send
# operationId: sendDocument
# --sender shape: {membership_id?: string, email?: string}
# --forwarding_settings shape: {forwarding_allowed?: bool, forwarding_with_reassigning_allowed?: bool}
# --selected_approvers shape: {steps?: list}
export def "public-documents-send sendDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message: string # A message that will be sent by email with a link to a document to sign. (e.g. Hello! This document was sent from the PandaDoc API)
  --subject: string # Value that will be used as the email subject. (e.g. Please check this test API document from PandaDoc)
  --silent: oneof<nothing, bool> # If set to `true`, disables email notifications for document recipients and the document sender. Also disables scheduled reminders (manual reminders still possible). Doesn't affect "Approve document" email notification sent to the Approver.
  --sender: record # You can set a sender of a document as an `email` or `membership_id` — shape: {membership_id?: string, email?: string}
  --forwarding-settings: record # Set settings for Document and Signature forwarding. — shape: {forwarding_allowed?: bool, forwarding_with_reassigning_allowed?: bool}
  --reply-to: string # Email address that will be used as a reply-to address for the document. To use this parameter, please contact the support team to have it enabled for your account.  (format: email, e.g. john.doe@example.com)
  --selected-approvers: record # Configuration for selected approvers. — shape: {steps?: list}
]: any -> record<id: string, name: string, status: string, date_created: string, date_modified: string, date_completed: string, expiration_date: string, version: string, uuid: string, recipients: table<id: string, first_name: string, last_name: string, recipient_type: string, email: string, phone: string, delivery_methods: record, signing_order: int, shared_link: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/send")
  let body = {message: $message, subject: $subject, silent: $silent, sender: $sender, forwarding_settings: $forwarding_settings, reply_to: $reply_to, selected_approvers: $selected_approvers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Document Editing Session
#
# POST /public/v1/documents/{id}/editing-sessions
# operationId: createDocumentEditingSession
export def "public-documents-editing-sessions createDocumentEditingSession" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email of the user to create the editing session for (format: email, e.g. john.doe@pandadoc.com)
  --lifetime: int # Lifetime of the E-Token in seconds. (format: int32, default: 3600, e.g. 3600)
]: any -> record<id: string, email: string, expires_at: string, key: string, token: string, document_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/editing-sessions")
  let body = {email: $email, lifetime: $lifetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Document Session for Embedded Sign
#
# POST /public/v1/documents/{id}/session
# operationId: createDocumentLink
export def "public-documents-session createDocumentLink" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  recipient: string # Email address of the person who will receive access to the document. (e.g. josh@example.com)
  --lifetime: float # The duration in seconds for which the document link will remain valid. The link will expire and become inaccessible after this time period. For security, we recommend setting the lifetime to less than one year (e.g., `"lifetime": 31535999`). If not specified, the default value is 1 hour (3600 seconds).  (default: 3600, e.g. 900)
]: any -> record<id: string, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/session")
  let body = {recipient: $recipient, lifetime: $lifetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Document Download
#
# GET /public/v1/documents/{id}/download
# operationId: downloadDocument
export def "public-documents-download downloadDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --watermark-color: string # HEX code (for example `#FF5733`). (e.g. #FF5733)
  --watermark-font-size: int # Font size of the watermark. (e.g. 12)
  --watermark-opacity: float # In range 0.0-1.0 (format: float, e.g. 0.5)
  --watermark-text: string # Specify watermark text. (e.g. John Doe inc.)
  --separate-files: oneof<nothing, bool> # Download document bundle as a zip-archive of separate PDFs (1 file per section). (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "watermark_color" $watermark_color "scalar") (serialize-qp "watermark_font_size" $watermark_font_size "scalar") (serialize-qp "watermark_opacity" $watermark_opacity "scalar") (serialize-qp "watermark_text" $watermark_text "scalar") (serialize-qp "separate_files" $separate_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/documents/($id)/download" $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Completed Document
#
# GET /public/v1/documents/{id}/download-protected
# operationId: downloadProtectedDocument
export def "public-documents-download-protected downloadProtectedDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --separate-files: oneof<nothing, bool> # Download document bundle as a zip-archive of separate PDFs (1 file per section). (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "separate_files" $separate_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/documents/($id)/download-protected" $qp)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Documents by Linked Object
#
# GET /public/v1/documents/linked-objects
# operationId: listDocumentsByLinkedObject
export def "public-documents-linked-objects listDocumentsByLinkedObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-id: string # You can get entity id from your integration, for example, from a url of a HubSpot deal. (e.g. 12345)
  --entity-type: string # See the available entity types: https://developers.pandadoc.com/reference/link-service#examples-of-the-most-popular-crms  (e.g. deal)
  --provider: string # See the available providers: https://developers.pandadoc.com/reference/link-service#examples-of-the-most-popular-crms  (e.g. hubspot)
  --order-by: string # default: -date_created, e.g. -date_created
  --owner-ids: list # default: [[]], e.g. [owner1, owner2]
]: nothing -> table<id: string, status: string, date_created: string, template_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_id" $entity_id "scalar") (serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "owner_ids" $owner_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/documents/linked-objects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Linked Objects
#
# GET /public/v1/documents/{id}/linked-objects
# operationId: listLinkedObjects
export def "public-documents-linked-objects listLinkedObjects" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<linked_objects: table<id: string, provider: string, entity_type: string, entity_id: string, children: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/linked-objects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Linked Object
#
# POST /public/v1/documents/{id}/linked-objects
# operationId: createLinkedObject
export def "public-documents-linked-objects createLinkedObject" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider: string # CRM name (lowercase).  See the list of available providers: https://developers.pandadoc.com/reference/link-service#examples-of-the-most-popular-crms  (e.g. pipedrive)
  entity_type: string # Entity type.  See the available entity types: https://developers.pandadoc.com/reference/link-service#examples-of-the-most-popular-crms  (e.g. deal)
  entity_id: string # Entity unique identifier. The system validates if the entity exists. (e.g. 9372)
]: any -> record<id: string, provider: string, entity_type: string, entity_id: string, children: table<id: string, entity_type: string, entity_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/linked-objects")
  let body = {provider: $provider, entity_type: $entity_type, entity_id: $entity_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Linked Object
#
# DELETE /public/v1/documents/{id}/linked-objects/{linked_object_id}
# operationId: deleteLinkedObject
export def "public-documents-linked-objects delete" [
  id: string
  linked_object_id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($id)/linked-objects/($linked_object_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Document Attachments
#
# GET /public/v1/documents/{id}/attachments
# operationId: listDocumentAttachments
export def "public-documents-attachments listDocumentAttachments" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<uuid: string, date_created: string, created_by: record<id: string, email: string, first_name: string, last_name: string, avatar: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Document Attachment
#
# POST /public/v1/documents/{id}/attachments
# operationId: createDocumentAttachment
export def "public-documents-attachments createDocumentAttachment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: string # URL link to the file to be attached to a document (e.g. https://is3-ssl.mzstatic.com/1e7fbd74-d10c-8e3a-63c3-0beb3ea231a5/512x512bb.jpg)
  --name: string # Optional name to set for uploaded file (e.g. Additional agreement)
]: any -> record<uuid: string, date_created: string, created_by: record<id: string, email: string, first_name: string, last_name: string, avatar: string>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/attachments")
  let body = {source: $body_source, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Document Attachment From Upload
#
# POST /public/v1/documents/{id}/attachments?upload
# operationId: createDocumentAttachmentFromFileUpload
export def "public-documents-attachments-upload createDocumentAttachmentFromFileUpload" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # Binary file to be attached to a document (format: binary)
  --name: string # Optional name to set for uploaded file (e.g. Additional agreement)
]: any -> record<uuid: string, date_created: string, created_by: record<id: string, email: string, first_name: string, last_name: string, avatar: string>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/attachments?upload")
  let body = {file: $file, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Document Attachment Details
#
# GET /public/v1/documents/{id}/attachments/{attachment_id}
# operationId: detailsDocumentAttachment
export def "public-documents-attachments detailsDocumentAttachment" [
  id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, date_created: string, created_by: record<id: string, email: string, first_name: string, last_name: string, avatar: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Document Attachment
#
# DELETE /public/v1/documents/{id}/attachments/{attachment_id}
# operationId: deleteDocumentAttachment
export def "public-documents-attachments delete" [
  id: string
  attachment_id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($id)/attachments/($attachment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Document Attachment
#
# GET /public/v1/documents/{id}/attachments/{attachment_id}/download
# operationId: downloadDocumentAttachment
export def "public-documents-attachments-download downloadDocumentAttachment" [
  id: string
  attachment_id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($id)/attachments/($attachment_id)/download")
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Document Fields
#
# GET /public/v1/documents/{id}/fields
# operationId: listDocumentFields
export def "public-documents-fields listDocumentFields" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<uuid: string, name: string, title: string, value: any, field_id: string, type: string, placeholder: string, assigned_to: record, layout: record, section_uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/fields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Document Fields Assignment
#
# PATCH /public/v1/documents/{id}/fields
# operationId: updateDocumentFieldsAssignment
# --fields item shape: {field_id: string, assigned_to: string}
export def "public-documents-fields updateDocumentFieldsAssignment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-fields: list # An array of field assignment operations. Each item specifies a field and the recipient it should be assigned to. — item shape: {field_id: string, assigned_to: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/fields")
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Document Fields
#
# POST /public/v1/documents/{id}/fields
# operationId: createDocumentFields
# --fields item shape: {field_id?: string, merge_field?: string, type: "checkbox"|"collect_file"|"date"|"dropdown"|"initials"|"payment_details"|"radio_buttons"|"signature"|"stamp"|"text", placeholder?: string, assigned_to?: string, layout: record}
export def "public-documents-fields createDocumentFields" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-fields: list # An array of fields to place on a document. — item shape: {field_id?: string, merge_field?: string, type: "checkbox"|"collect_file"|"date"|"dropdown"|"initials"|"payment_details"|"radio_buttons"|"signature"|"stamp"|"text", placeholder?: string, assigned_to?: string, layout: record}
]: any -> record<fields: table<uuid: string, name: string, title: string, value: any, field_id: string, type: string, placeholder: string, assigned_to: record, layout: record, section_uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/fields")
  let body = {fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Document Audit Trail
#
# GET /public/v2/documents/{document_id}/audit-trail
# operationId: listDocumentAuditTrail
export def "public-documents-audit-trail listDocumentAuditTrail" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of items to return. (default: 20, e.g. 20)
  --offset: int # Number of items to skip before starting to collect the result set. (default: 0, e.g. 0)
]: nothing -> record<count: int, results: table<id: string, user: record, action: int, reason: string, date_created: string, ip_address: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v2/documents/($document_id)/audit-trail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get document settings
#
# GET /public/v2/documents/{document_id}/settings
# operationId: documentSettingsGet
export def "public-documents-settings documentSettingsGet" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<language: string, qualified_electronic_signature: bool, expires_in: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/documents/($document_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update document settings
#
# PATCH /public/v2/documents/{document_id}/settings
# operationId: documentSettingsUpdate
export def "public-documents-settings documentSettingsUpdate" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string@language-completer # Document language code (e.g., 'en-US', 'fr-FR').
  --qualified-electronic-signature: oneof<nothing, bool> # Indicates whether the document requires a Qualified Electronic Signature (QES) during the signing process. If `true`, signers must complete the document using a third-party qualified electronic signature provider according to supported verification rules.
  --expires-in: int # Document expiration in days. Minimum is 1 day.  (format: int32)
]: any -> record<language: string, qualified_electronic_signature: bool, expires_in: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/documents/($document_id)/settings")
  let body = {language: $language, qualified_electronic_signature: $qualified_electronic_signature, expires_in: $expires_in} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update document ownership
#
# PATCH /public/v1/documents/{id}/ownership
# operationId: transferDocumentOwnership
export def "public-documents-ownership transferDocumentOwnership" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --membership-id: string # A unique identifier of a workspace member. (e.g. radQBiBkU7MBk59NSgaGfd)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/ownership")
  let body = {membership_id: $membership_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfer all documents ownership
#
# PATCH /public/v1/documents/ownership
# operationId: transferAllDocumentsOwnership
export def "public-documents-ownership transferAllDocumentsOwnership" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --from-membership-id: string # A unique identifier of a workspace member from whom you want to transfer ownership. (e.g. Dqsxp4jNnFcS63tJEgLJGN)
  --to-membership-id: string # A unique identifier of a workspace member to whom you want to transfer ownership. (e.g. radQBiBkU7MBk59NSgaGfd)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/documents/ownership")
  let body = {from_membership_id: $from_membership_id, to_membership_id: $to_membership_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Document move to folder
#
# POST /public/v1/documents/{id}/move-to-folder/{folder_id}
# operationId: documentMoveToFolder
export def "public-documents-move-to-folder documentMoveToFolder" [
  id: string
  folder_id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($id)/move-to-folder/($folder_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Append Content Library Item to a document
#
# POST /public/v1/documents/{id}/append-content-library-item
# operationId: appendContentLibraryItemToDocument
# --cli shape: {id: string, pages?: list}
export def "public-documents-append-content-library-item appendContentLibraryItemToDocument" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cli: record # Settings to append a CLI to a document, with ability to change some parameters — shape: {id: string, pages?: list}
]: any -> record<cli: record<id: string, pages: list<record>>, block_mapping: record<tables: list<record>, pricing_tables: list<record>, images: list<record>, texts: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/append-content-library-item")
  let body = {cli: $cli} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Document Recipient
#
# POST /public/v1/documents/{id}/recipients
# operationId: addDocumentRecipient
export def "public-documents-recipients addDocumentRecipient" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string # Contact uuid. (e.g. 2eWSKSvVqmuVCnuUK3iWwD)
  kind: string@kind-completer # default: contact, e.g. contact
]: any -> record<recipient_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/recipients")
  let body = {id: $body_id, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Document Recipient
#
# DELETE /public/v1/documents/{id}/recipients/{recipient_id}
# operationId: deleteDocumentRecipient
export def "public-documents-recipients delete" [
  id: string
  recipient_id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($id)/recipients/($recipient_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Document Recipient
#
# PATCH /public/v1/documents/{id}/recipients/recipient/{recipient_id}
# operationId: editDocumentRecipient
# --delivery_methods shape: {email?: bool, sms?: bool}
# --verification_settings shape: {verification_place?: "before_open"|"before_sign", passcode_verification?: record, phone_verification?: record, kba_verification?: record, id_verification?: record}
# --redirect shape: {is_enabled: bool, url: string}
export def "public-documents-recipients-recipient editDocumentRecipient" [
  id: string
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # You cannot use the email of another contact when updating a recipient contact. (nullable, e.g. user01@pandadoc.com)
  --phone: string # nullable, e.g. +14842634627
  --delivery-methods: record # nullable — shape: {email?: bool, sms?: bool}
  --first-name: string # nullable, e.g. John
  --last-name: string # nullable, e.g. Doe
  --company: string # nullable, e.g. John Doe Inc.
  --job-title: string # nullable, e.g. CTO
  --state: string # nullable, e.g. Texas
  --street-address: string # nullable, e.g. 1313 Mockingbird Lane
  --city: string # nullable, e.g. Austin
  --postal-code: string # nullable, e.g. 75001
  --verification-settings: record # To set up recipient verification, fill in verification_place and specify the type: passcode_verification, phone_verification, kba_verification or id_verification. - For passcode_verification, provide the passcode. - For phone_verification, provide the phone_number. - For kba_verification and id_verification, set the enabled parameter to true.  (nullable) — shape: {verification_place?: "before_open"|"before_sign", passcode_verification?: record, phone_verification?: record, kba_verification?: record, id_verification?: record}
  --redirect: record # shape: {is_enabled: bool, url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/recipients/recipient/($recipient_id)")
  let body = {email: $email, phone: $phone, delivery_methods: $delivery_methods, first_name: $first_name, last_name: $last_name, company: $company, job_title: $job_title, state: $state, street_address: $street_address, city: $city, postal_code: $postal_code, verification_settings: $verification_settings, redirect: $redirect} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Change Signer (Reassign Document Recipient)
#
# POST /public/v1/documents/{id}/recipients/{recipient_id}/reassign
# operationId: reassignDocumentRecipient
export def "public-documents-recipients-reassign reassignDocumentRecipient" [
  id: string
  recipient_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string # Contact uuid. (e.g. 2eWSKSvVqmuVCnuUK3iWwD)
  kind: string@kind-completer # default: contact, e.g. contact
]: any -> record<recipient_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($id)/recipients/($recipient_id)/reassign")
  let body = {id: $body_id, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send Manual Reminder
#
# POST /public/v1/documents/{document_id}/send-reminder
# operationId: createManualReminder
# --reminders item shape: {recipient_id?: string, delivery_methods?: record, email_customization?: record}
export def "public-documents-send-reminder createManualReminder" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reminders: list # A list of reminders to be sent to specified recipients. Use this field to specify which recipients should receive a reminder and through which delivery methods.  Each email reminder contains document sender in the From field,  ensuring the recipient always sees consistent sender details and branding. — item shape: {recipient_id?: string, delivery_methods?: record, email_customization?: record}
]: any -> record<result: table<recipient_id: string, sms: record, email: record, email_customization: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/send-reminder")
  let body = {reminders: $reminders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Document Sections
#
# GET /public/v1/documents/{document_id}/sections
# operationId: listSections
export def "public-documents-sections listSections" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: table<uuid: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/sections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Document Section
#
# POST /public/v1/documents/{document_id}/sections/uploads
# operationId: uploadSection
export def "public-documents-sections-uploads uploadSection" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merge-field-scope: string@merge-field-scope-completer # Determines how the fields are mapped when creating a section.   * document: Default value. The fields of the entire document are updated.   * upload: Only the fields from the created section are updated. The merge field is appended with the upload ID.  (e.g. document)
  --body: record
]: any -> record<uuid: string, name: string, document_uuid: string, status: string, date_created: string, date_modified: string, date_completed: string, info_message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge_field_scope" $merge_field_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/sections/uploads" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Document Section from File Upload
#
# POST /public/v1/documents/{document_id}/sections/uploads?upload
# operationId: uploadSectionWithUpload
export def "public-documents-sections-uploads-upload uploadSectionWithUpload" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --merge-field-scope: string@merge-field-scope-completer # Determines how the fields are mapped when creating a section.   * document: Default value. The fields of the entire document are updated.   * upload: Only the fields from the created section are updated. The merge field is appended with the upload ID.  (e.g. document)
  --file: string # Binary PDF/DocX/RTF File. (format: binary)
  --data: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merge_field_scope" $merge_field_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/sections/uploads?upload" $qp)
  let body = {file: $file, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Document Section Upload Status
#
# GET /public/v1/documents/{document_id}/sections/uploads/{upload_id}
# operationId: sectionDetails
export def "public-documents-sections-uploads sectionDetails" [
  document_id: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, document_uuid: string, status: string, name: string, sections_uuids: list<string>, date_created: string, date_modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/sections/uploads/($upload_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Document Section Details
#
# GET /public/v1/documents/{document_id}/sections/{section_id}
# operationId: sectionInfo
export def "public-documents-sections sectionInfo" [
  document_id: string
  section_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, name: string, document_uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/sections/($section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Document Section
#
# DELETE /public/v1/documents/{document_id}/sections/{section_id}
# operationId: deleteSection
export def "public-documents-sections delete" [
  document_id: string
  section_id: string
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
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/sections/($section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add DSV Named Items to a Document
#
# POST /public/v2/dsv/{document_id}/add-named-items
# operationId: addDsvNamedItems
# --items item shape: {name: string, level: int, page_name: string}
export def "public-dsv-add-named-items addDsvNamedItems" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # List of named items representing structural elements of the document. — item shape: {name: string, level: int, page_name: string}
]: any -> record<results: table<id: string, name: string, level: int, page_name: string, page_uuid: string>, count: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/dsv/($document_id)/add-named-items")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Content Library Item
#
# GET /public/v1/content-library-items
# operationId: listContentLibraryItems
export def "public-content-library-items listContentLibraryItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search query. Filter by content library item name. (e.g. Sample Pricing Table)
  --id: string # Specify content library item ID. (e.g. UXdP7Lnbvvr4WEb2wzM2hc)
  --deleted: oneof<nothing, bool> # Returns only the deleted content library items. (e.g. false)
  --folder-uuid: string # The UUID of the folder where the content library items are stored. (e.g. S6xX7saJfA44mtJxGWd95L)
  --count: int # Specify how many content library items to return. Default is 50 content library items, maximum is 100 content library items. (format: int32, e.g. 10)
  --page: int # Specify which page of the dataset to return. (format: int32, e.g. 1)
  --tag: string # Search tag. Filter by content library item tag. (e.g. pricing_tables)
]: nothing -> record<results: table<id: string, name: string, date_created: string, date_modified: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "folder_uuid" $folder_uuid "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/content-library-items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Content Library Item
#
# POST /public/v1/content-library-items
# operationId: createContentLibraryItem
export def "public-content-library-items createContentLibraryItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # Secure (HTTPS) and publicly accessible URL to the PDF document. (e.g. https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf)
  --name: string # The name of the Content Library Item. (e.g. CLI name example)
]: any -> record<id: string, name: string, date_created: string, date_modified: string, version: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/content-library-items")
  let body = {url: $body_url, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Content Library Item from File Upload
#
# POST /public/v1/content-library-items?upload
# operationId: createContentLibraryItemFromUpload
export def "public-content-library-items-upload createContentLibraryItemFromUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: string # Binary PDF File (format: binary)
  --data: any
]: any -> record<id: string, name: string, date_created: string, date_modified: string, version: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/content-library-items?upload")
  let body = {file: $file, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Content Library Item Status
#
# GET /public/v1/content-library-items/{id}
# operationId: statusContentLibraryItem
export def "public-content-library-items statusContentLibraryItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, date_created: string, date_modified: string, version: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/content-library-items/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Content Library Item Details
#
# GET /public/v1/content-library-items/{id}/details
# operationId: detailsContentLibraryItem
export def "public-content-library-items-details detailsContentLibraryItem" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, date_created: string, date_modified: string, content_date_modified: string, created_by: record<id: string, email: string, first_name: string, last_name: string, avatar: string>, metadata: record, tokens: list<record>, fields: list<record>, pricing: record<tables: list<record>, quotes: list<record>, total: string>, tags: list<string>, roles: list<record>, version: string, content_placeholders: list<record>, tables: table<name: string>, images: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/content-library-items/($id)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Templates
#
# GET /public/v1/templates
# operationId: listTemplates
export def "public-templates listTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search query. Filter by template name. (e.g. Sample onboarding template)
  --shared: oneof<nothing, bool> # Returns only the shared templates. (e.g. false)
  --deleted: oneof<nothing, bool> # Returns only the deleted templates. (e.g. false)
  --count: int # Specify how many templates to return. (format: int32, default: 50, e.g. 10)
  --page: int # Specify which page of the dataset to return. (format: int32, e.g. 1)
  --id: string # Specify template ID. (e.g. e9LxBesSL73AeZMzeYdfvV)
  --folder-uuid: string # UUID of the folder where the templates are stored.
  --tag: list # Search tag. Filter by template tag. (e.g. [onboarding])
  --qp-fields: list # A comma-separated list of additional fields to include in the response. (e.g. [content_date_modified])
]: nothing -> record<results: table<id: string, name: string, date_created: string, date_modified: string, version: string, content_date_modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "shared" $shared "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "folder_uuid" $folder_uuid "scalar") (serialize-qp "tag" $tag "multi") (serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Template
#
# POST /public/v1/templates
# operationId: createTemplate
# --owner shape: {membership_id?: string, email?: string}
# --tokens item shape: {name: string, value: string}
export def "public-templates createTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of additional fields to include in the response. (e.g. [content_date_modified])
  --body-url: string # Secure (HTTPS) and publicly accessible URL to the PDF document. (e.g. https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf)
  --name: string # The name of the template. (e.g. Template name example)
  --folder-uuid: string # The ID of the folder where the created template should be stored. (e.g. EE8yUNg5HztqVAuH85He8V)
  --owner: record # You can set an owner of a template as an `email` or `membership_id`. — shape: {membership_id?: string, email?: string}
  --metadata: record # You can pass arbitrary data in the key-value format to associate custom information with a template. This information is returned in any API requests for the template details by id. (nullable, e.g. {my_favorite_pet: Panda})
  --tokens: list # Create or initialize multiple CUSTOM variables with their values using tokens/values list. Template's predefined variables are read-only. Any attempts to do so will be ignored. (e.g. [{name: Favorite.Pet, value: Panda}]) — item shape: {name: string, value: string}
]: any -> record<id: string, name: string, date_created: string, date_modified: string, version: string, content_date_modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/templates" $qp)
  let body = {url: $body_url, name: $name, folder_uuid: $folder_uuid, owner: $owner, metadata: $metadata, tokens: $tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Template from File Upload
#
# POST /public/v1/templates?upload
# operationId: createTemplateWithUpload
export def "public-templates-upload createTemplateWithUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-fields: list # A comma-separated list of additional fields to include in the response. (e.g. [content_date_modified])
  --file: string # Binary PDF/DocX/RTF File. (format: binary)
  --data: any
]: any -> record<id: string, name: string, date_created: string, date_modified: string, version: string, content_date_modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/templates?upload" $qp)
  let body = {file: $file, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Template Details
#
# GET /public/v1/templates/{id}/details
# operationId: detailsTemplate
export def "public-templates-details detailsTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, folder_uuid: string, date_created: string, date_modified: string, content_date_modified: string, created_by: record<id: string, email: string, first_name: string, last_name: string, avatar: string>, metadata: record, tokens: table<name: string, value: string>, fields: list<record>, pricing: record<tables: list<record>, quotes: list<record>, total: string>, tags: list<string>, roles: table<id: string, name: string, signing_order: string, preassigned_person: record>, version: string, content_placeholders: table<uuid: string, block_id: string, description: string>, tables: table<name: string>, images: table<name: string, block_uuid: string, urls: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/templates/($id)/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Template
#
# DELETE /public/v1/templates/{id}
# operationId: deleteTemplate
export def "public-templates delete" [
  id: string
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
  let full_url = (build-url $base $"/public/v1/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Template Status
#
# GET /public/v1/templates/{id}
# operationId: statusTemplate
export def "public-templates statusTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, date_created: string, date_modified: string, version: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/templates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Template Update
#
# PATCH /public/v1/templates/{id}
# operationId: updateTemplate
# --tokens item shape: {name: string, value: string}
# --roles item shape: {id?: string, name: string, signing_order?: int}
export def "public-templates updateTemplate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokens: list # Create or initialize multiple CUSTOM variables with their values using tokens/values list. Template's predefined variables are read-only. Any attempts to do so will be ignored. (e.g. [{name: Favorite.Pet, value: Panda}]) — item shape: {name: string, value: string}
  --roles: list # Replace the full set of template roles. Items with an existing `id` are updated, items without an `id` are created as new roles, and existing roles whose `id` is not present in the list are deleted. (e.g. [{id: BqL3PVsB2tPLfaSqUiQQRf, name: Client, signing_order: 1}, {name: Manager, signing_order: 2}]) — item shape: {id?: string, name: string, signing_order?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/templates/($id)")
  let body = {tokens: $tokens, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Template Editing Session
#
# POST /public/v1/templates/{id}/editing-sessions
# operationId: createTemplateEditingSession
export def "public-templates-editing-sessions createTemplateEditingSession" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email of the user to create the editing session for (format: email, e.g. john.doe@pandadoc.com)
  --lifetime: int # Lifetime of the E-Token in seconds. (format: int32, default: 3600, e.g. 3600)
]: any -> record<id: string, email: string, expires_at: string, key: string, token: string, template_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/templates/($id)/editing-sessions")
  let body = {email: $email, lifetime: $lifetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get template settings
#
# GET /public/v2/templates/{template_id}/settings
# operationId: templateSettingsGet
export def "public-templates-settings templateSettingsGet" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<language: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/templates/($template_id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update template settings
#
# PATCH /public/v2/templates/{template_id}/settings
# operationId: templateSettingsUpdate
export def "public-templates-settings templateSettingsUpdate" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string@language-completer # Document language code (e.g., 'en-US', 'fr-FR').
]: any -> record<language: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/templates/($template_id)/settings")
  let body = {language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Forms
#
# GET /public/v1/forms
# operationId: listForm
export def "public-forms listForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Specify how many forms to return. Default is 50 forms, maximum is 100 forms. (format: int32, e.g. 10)
  --page: int # Specify which page of the dataset to return. (format: int32, e.g. 1)
  --status: list # Specify which status of the forms dataset to return. (e.g. [draft, active])
  --order-by: string@order-by-completer-1 # Specify the form dataset order to return. (e.g. name)
  --asc: oneof<nothing, bool> # Specify sorting the result-set in ascending or descending order. (e.g. true)
  --name: string # Specify the form name. (e.g. New Form)
]: nothing -> record<results: table<id: string, name: string, date_created: string, date_modified: string, status: string>, has_next_page: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "multi") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "asc" $asc "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Documents Folders
#
# GET /public/v1/documents/folders
# operationId: listDocumentFolders
export def "public-documents-folders listDocumentFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-uuid: string # The UUID of the folder containing folders. To list the folders located in the root folder, remove this parameter in the request. (e.g. Nq8htXxFssmhRxAPSP4SBP)
  --count: int # Optionally, specify how many folders to return. (format: int32, default: 50, e.g. 50)
  --page: int # Optionally, specify which page of the dataset to return. (format: int32, e.g. 1)
]: nothing -> record<results: table<uuid: string, name: string, date_created: string, has_folders: bool, has_items: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_uuid" $parent_uuid "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/documents/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Documents Folder
#
# POST /public/v1/documents/folders
# operationId: createDocumentFolder
export def "public-documents-folders createDocumentFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name the folder for the Documents you are creating. (e.g. A new document folder)
  --parent-uuid: string # ID of the parent folder. To create a new folder in the root folder, remove this parameter in the request. (e.g. Nq8htXxFssmhRxAPSP4SBP)
]: any -> record<uuid: string, name: string, date_created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/documents/folders")
  let body = {name: $name, parent_uuid: $parent_uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename Documents Folder
#
# PUT /public/v1/documents/folders/{id}
# operationId: renameDocumentFolder
export def "public-documents-folders renameDocumentFolder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Provide a new name for the folder. (e.g. Another document folder')
]: any -> record<uuid: string, name: string, date_created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/folders/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Templates Folders
#
# GET /public/v1/templates/folders
# operationId: listTemplateFolders
export def "public-templates-folders listTemplateFolders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parent-uuid: string # The UUID of the folder containing folders. To list the folders located in the root folder, remove this parameter in the request. (e.g. Nq8htXxFssmhRxAPSP4SBP)
  --count: int # Optionally, specify how many folders to return. (format: int32, default: 50, e.g. 50)
  --page: int # Optionally, specify which page of the dataset to return. (format: int32, e.g. 1)
]: nothing -> record<results: table<uuid: string, name: string, date_created: string, has_folders: bool, has_items: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_uuid" $parent_uuid "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/templates/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Templates Folder
#
# POST /public/v1/templates/folders
# operationId: createTemplateFolder
export def "public-templates-folders createTemplateFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name the folder for Templates you are creating. (e.g. A new template folder)
  --parent-uuid: string # ID of the parent folder. To create a new folder in the root folder, remove this parameter in the request. (e.g. Nq8htXxFssmhRxAPSP4SBP)
]: any -> record<uuid: string, name: string, date_created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/templates/folders")
  let body = {name: $name, parent_uuid: $parent_uuid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rename Templates Folder
#
# PUT /public/v1/templates/folders/{id}
# operationId: renameTemplateFolder
export def "public-templates-folders renameTemplateFolder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Provide a new name for the folder. (e.g. Another template folder)
]: any -> record<uuid: string, name: string, date_created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/templates/folders/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List API Log
#
# GET /public/v1/logs
# DEPRECATED
# operationId: listLogs
@deprecated
export def "public-logs listLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Determines a point in time from which logs should be fetched. Either a specific ISO 8601 datetime or a relative identifier such as "-90d" (for past 90 days). (default: -90d, e.g. -7d)
  --qp-to: string # Determines a point in time from which logs should be fetched. Either a specific ISO 8601 datetime or a relative identifier such as "-10d" (for past 10 days) or a special "now" value. (e.g. now)
  --count: int # The amount of items on each page. The total number of accessible items (`count × page`) must not exceed 10,000. (format: int32, default: 100, e.g. 10)
  --page: int # Returns page of the results by number. The total number of accessible items (`count × page`) must not exceed 10,000. (format: int32, default: 1, e.g. 1)
  --statuses: list # Returns only the predefined status codes.
  --methods: list # Returns only the predefined HTTP methods. Allows GET, POST, PUT, PATCH, and DELETE. (e.g. [GET, POST])
  --search: string # Returns the results containing a string. (e.g. documents/hryJY9mqYZHjQCYQuSjRQg/send)
  --environment-type: string@environment-type-completer # Returns logs for production/sandbox. (e.g. PRODUCTION)
]: nothing -> record<results: table<id: string, url: string, status: int, request_time: string, response_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "statuses" $statuses "multi") (serialize-qp "methods" $methods "multi") (serialize-qp "search" $search "scalar") (serialize-qp "environment_type" $environment_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Log Details
#
# GET /public/v1/logs/{id}
# DEPRECATED
# operationId: detailsLog
@deprecated
export def "public-logs detailsLog" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, method: string, status: int, request_time: string, response_time: string, response_body: record, query_params_string: string, query_params_object: record, request_body: record, token_type: string, application: string, key: string, request_id: string, user_email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/logs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API Log
#
# GET /public/v2/logs
# operationId: listLogsV2
export def "public-logs listLogsV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # Determines a point in time from which logs should be fetched. Either a specific ISO 8601 datetime or a relative identifier such as "-90d" (for past 90 days). (default: -90d, e.g. -7d)
  --qp-to: string # Determines a point in time from which logs should be fetched. Either a specific ISO 8601 datetime or a relative identifier such as "-10d" (for past 10 days) or a special "now" value. (e.g. now)
  --count: int # The amount of items on each page. The total number of accessible items (`count × page`) must not exceed 10,000. (format: int32, default: 100, e.g. 10)
  --page: int # Returns page of the results by number. The total number of accessible items (`count × page`) must not exceed 10,000. (format: int32, default: 1, e.g. 1)
  --statuses: list # Returns only the predefined status codes.
  --methods: list # Returns only the predefined HTTP methods. Allows GET, POST, PUT, PATCH, and DELETE. (e.g. [GET, POST])
  --search: string # Returns the results containing a string. (e.g. documents/hryJY9mqYZHjQCYQuSjRQg/send)
  --environment-type: string@environment-type-completer # Returns logs for production/sandbox. (e.g. PRODUCTION)
]: nothing -> record<results: table<id: string, url: string, status: int, request_time: string, response_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "statuses" $statuses "multi") (serialize-qp "methods" $methods "multi") (serialize-qp "search" $search "scalar") (serialize-qp "environment_type" $environment_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v2/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Log Details
#
# GET /public/v2/logs/{id}
# operationId: detailsLogV2
export def "public-logs detailsLogV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, url: string, method: string, status: int, request_time: string, response_time: string, response_body: record, query_params_string: string, query_params_object: record, request_body: record, token_type: string, application: string, key: string, request_id: string, user_email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/logs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List contacts
#
# GET /public/v1/contacts
# operationId: listContacts
export def "public-contacts listContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Optional search parameter. Filter results by exact match.
]: nothing -> record<results: table<id: string, email: string, first_name: string, last_name: string, company: string, job_title: string, phone: string, country: string, state: string, street_address: string, city: string, postal_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create contact
#
# POST /public/v1/contacts
# operationId: createContact
export def "public-contacts createContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # An email address of the contact (nullable, e.g. user01@pandadoc.com)
  --first-name: string # Contact's first name (nullable, e.g. John)
  --last-name: string # Contact's last name (nullable, e.g. Doe)
  --company: string # Contact's company name (nullable, e.g. John Doe Inc.)
  --job-title: string # Contact's job title (nullable, e.g. CTO)
  --phone: string # A phone number (nullable, e.g. +14842634627)
  --country: string # A country name (nullable, e.g. USA)
  --state: string # A state name (nullable, e.g. Texas)
  --street-address: string # A street address (nullable, e.g. 1313 Mockingbird Lane)
  --city: string # A city name (nullable, e.g. Austin)
  --postal-code: string # A postal code (nullable, e.g. 75001)
]: any -> record<id: string, email: string, first_name: string, last_name: string, company: string, job_title: string, phone: string, country: string, state: string, street_address: string, city: string, postal_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/contacts")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, company: $company, job_title: $job_title, phone: $phone, country: $country, state: $state, street_address: $street_address, city: $city, postal_code: $postal_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Contact Details
#
# GET /public/v1/contacts/{id}
# operationId: detailsContact
export def "public-contacts detailsContact" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, email: string, first_name: string, last_name: string, company: string, job_title: string, phone: string, country: string, state: string, street_address: string, city: string, postal_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Contact
#
# DELETE /public/v1/contacts/{id}
# operationId: deleteContact
export def "public-contacts delete" [
  id: string
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
  let full_url = (build-url $base $"/public/v1/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Contact
#
# PATCH /public/v1/contacts/{id}
# operationId: updateContact
export def "public-contacts updateContact" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --first-name: string # nullable, e.g. John
  --last-name: string # nullable, e.g. Doe
  --company: string # nullable, e.g. John Doe Inc.
  --job-title: string # nullable, e.g. CTO
  --phone: string # nullable, e.g. +14842634627
  --state: string # nullable, e.g. Texas
  --street-address: string # nullable, e.g. 1313 Mockingbird Lane
  --city: string # nullable, e.g. Austin
  --postal-code: string # nullable, e.g. 75001
]: any -> record<id: string, email: string, first_name: string, last_name: string, company: string, job_title: string, phone: string, country: string, state: string, street_address: string, city: string, postal_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/contacts/($id)")
  let body = {first_name: $first_name, last_name: $last_name, company: $company, job_title: $job_title, phone: $phone, state: $state, street_address: $street_address, city: $city, postal_code: $postal_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Members
#
# GET /public/v1/members
# operationId: listMembers
export def "public-members listMembers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<results: table<user_id: string, membership_id: string, email: string, first_name: string, last_name: string, is_active: bool, workspace: string, workspace_name: string, emails_verified: bool, role: string, user_license: string, date_created: string, date_modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Current Member Details
#
# GET /public/v1/members/current
# operationId: detailsCurrentMember
export def "public-members-current detailsCurrentMember" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_id: string, membership_id: string, email: string, first_name: string, last_name: string, is_active: bool, workspace: string, workspace_name: string, emails_verified: bool, role: string, user_license: string, date_created: string, date_modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/members/current")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Member Details
#
# GET /public/v1/members/{id}
# operationId: detailsMember
export def "public-members detailsMember" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_id: string, membership_id: string, email: string, first_name: string, last_name: string, is_active: bool, workspace: string, workspace_name: string, emails_verified: bool, role: string, user_license: string, date_created: string, date_modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/members/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Member Token
#
# POST /public/v1/members/{member_id}/token
# operationId: createMemberToken
export def "public-members-token createMemberToken" [
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lifetime: int # Token lifetime in seconds. (default: 3600)
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/members/($member_id)/token")
  let body = {lifetime: $lifetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Webhook Subscriptions
#
# GET /public/v1/webhook-subscriptions
# operationId: listWebhookSubscriptions
export def "public-webhook-subscriptions listWebhookSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<uuid: string, name: string, url: string, active: bool, payload: list, triggers: list, workspace_id: string, shared_key: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/webhook-subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webhook Subscription
#
# POST /public/v1/webhook-subscriptions
# operationId: createWebhookSubscription
export def "public-webhook-subscriptions createWebhookSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Set a name for the Webhooks subscription. (e.g. My Subscription)
  --body-url: string # Set the Webhooks subscription URL. (format: url, e.g. https://example.com)
  --active: oneof<nothing, bool> # Set the status of the Webhooks subscription. (default: true)
  --payload: list # Set a payload structure. (nullable)
  --triggers: list # Set trigger events for the Webhooks subscription. (nullable)
]: any -> record<uuid: string, name: string, url: string, active: bool, payload: list<string>, triggers: list<string>, workspace_id: string, shared_key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/webhook-subscriptions")
  let body = {name: $name, url: $body_url, active: $active, payload: $payload, triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Webhook Subscription Details
#
# GET /public/v1/webhook-subscriptions/{id}
# operationId: detailsWebhookSubscription
export def "public-webhook-subscriptions detailsWebhookSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, name: string, url: string, active: bool, payload: list<string>, triggers: list<string>, workspace_id: string, shared_key: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/webhook-subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webhook Subscription
#
# PATCH /public/v1/webhook-subscriptions/{id}
# operationId: updateWebhookSubscription
export def "public-webhook-subscriptions updateWebhookSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Set a new name for the Webhooks subscription. (e.g. My Subscription)
  --body-url: string # Set the new Webhooks subscription URL. (format: url, e.g. https://example.com)
  --active: oneof<nothing, bool> # Set the status of the Webhooks subscription. (default: true, e.g. true)
  --payload: list # Set a new payload structure. (nullable)
  --triggers: list # Set trigger events for the Webhooks subscription. (nullable)
]: any -> record<uuid: string, name: string, url: string, active: bool, payload: list<string>, triggers: list<string>, workspace_id: string, shared_key: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/webhook-subscriptions/($id)")
  let body = {name: $name, url: $body_url, active: $active, payload: $payload, triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webhook Subscription
#
# DELETE /public/v1/webhook-subscriptions/{id}
# operationId: deleteWebhookSubscription
export def "public-webhook-subscriptions delete" [
  id: string
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
  let full_url = (build-url $base $"/public/v1/webhook-subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webhook Subscription Shared Key
#
# PATCH /public/v1/webhook-subscriptions/{id}/shared-key
# operationId: updateWebhookSubscriptionSharedKey
export def "public-webhook-subscriptions-shared-key updateWebhookSubscriptionSharedKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<shared_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/webhook-subscriptions/($id)/shared-key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webhook Events
#
# GET /public/v1/webhook-events
# operationId: listWebhookEvent
export def "public-webhook-events listWebhookEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Specify how many event results to return. (format: int32, e.g. 10)
  --page: int # Specify which page of the dataset to return. (format: int32, e.g. 1)
  --since: string # Return results where the event creation time is greater than or equal to this value. (format: date-time, e.g. 2022-06-01T00:00:00Z)
  --qp-to: string # Return results where the event creation time is less than this value. (format: date-time, e.g. 2022-06-30T23:59:59Z)
  --type: list # Returns results by the specified event types. (e.g. [recipient_completed])
  --http-status-code: list # Returns results with the specified HTTP status codes. (e.g. [400])
  --qp-error: list # Returns results with the following errors. (e.g. [INTERNAL_ERROR, NOT_VALID_URL])
]: nothing -> record<items: table<uuid: string, name: string, type: string, http_status_code: int, error: string, delivery_time: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "type" $type "multi") (serialize-qp "http_status_code" $http_status_code "multi") (serialize-qp "error" $qp_error "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/webhook-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Webhook Event Details
#
# GET /public/v1/webhook-events/{id}
# operationId: detailsWebhookEvent
export def "public-webhook-events detailsWebhookEvent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, name: string, type: string, http_status_code: int, error: string, delivery_time: string, url: string, signature: string, request_body: string, response_body: string, response_headers: string, event_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/webhook-events/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Notaries
#
# GET /public/v2/notary/notaries
# operationId: listNotaries
export def "public-notary-notaries listNotaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Filter by status (comma-separated values supported). Valid values are INVITED, UNDER_REVIEW, ACTIVE, REJECTED, INACTIVE (e.g. [ACTIVE, UNDER_REVIEW])
  --commission-state: list # Filter by commission state (comma-separated values supported) (e.g. [California, Arizona])
  --offset: int # Number of results to skip (default: 0, e.g. 0)
  --limit: int # Maximum number of results to return (default: 50, e.g. 50)
  --order-by: string@order-by-completer-2 # Sort by name, email, or status (default is email). Use a - prefix for descending order (e.g., -email) (default: email, e.g. email)
]: nothing -> record<results: table<id: string, email: string, name: string, status: string, commission_state: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "commission_state" $commission_state "multi") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v2/notary/notaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Notarization Requests
#
# GET /public/v2/notary/notarization-requests
# operationId: listNotarizationRequests
export def "public-notary-notarization-requests listNotarizationRequests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Filter by status (comma-separated values supported). (e.g. [SENT])
  --created-by-user-id: list # Filter by creator user ID (comma-separated values supported). (e.g. [nyAnVpY7pZ23FBve8s9xgk])
  --document-id: list # Filter by document ID (comma-separated values supported). (e.g. [D3okRfgHRX7NEhavcACReB])
  --offset: int # Number of results to skip. (default: 0, e.g. 0)
  --limit: int # Maximum number of results to return. (default: 50, e.g. 50)
  --order-by: string@order-by-completer-3 # Sort field. Use a `-` prefix for descending order (e.g., `-date_created`). When omitted, results are sorted by `date_created` ascending (oldest first).  (default: date_created, e.g. -date_created)
]: nothing -> record<results: table<id: string, status: string, name: string, document_id: string, date_created: string, date_started: string, date_completed: string, created_by_user_id: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "csv") (serialize-qp "created_by_user_id" $created_by_user_id "csv") (serialize-qp "document_id" $document_id "csv") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v2/notary/notarization-requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Notarization Request
#
# POST /public/v2/notary/notarization-requests
# operationId: createNotarizationRequest
# --invitation shape: {message?: string, invitees?: list}
# --notary shape: {id: string, scheduled_at: string, message?: string}
export def "public-notary-notarization-requests createNotarizationRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  document_id: string # ID of the Document for notarization. (e.g. 8DstGmLJDBXBKrh3wnqzpe)
  --disable-invitees-notifications: oneof<nothing, bool> # Disable all notifications for invitees including email with invitation for notarization. This is useful when you are using alternative delivery methods. (nullable, default: false, e.g. true)
  invitation: record # shape: {message?: string, invitees?: list}
  --notary: record # Optional notary assignment for in-house notary requests. Used for Bring you own notary use case. Only ACTIVE notaries can be used — shape: {id: string, scheduled_at: string, message?: string}
]: any -> record<id: string, name: string, status: string, date_created: string, date_accepted: string, created_by: record<user_id: string, email: string, first_name: string, last_name: string>, invitees: table<id: string, email: string, first_name: string, last_name: string, notarization_link: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v2/notary/notarization-requests")
  let body = {document_id: $document_id, disable_invitees_notifications: $disable_invitees_notifications, invitation: $invitation, notary: $notary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Notarization Request Details
#
# GET /public/v2/notary/notarization-requests/{session_request_id}
# operationId: notarizationRequestDetails
export def "public-notary-notarization-requests notarizationRequestDetails" [
  session_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, document_id: string, date_created: string, date_started: string, date_completed: string, created_by: record<user_id: string, email: string, first_name: string, last_name: string>, invitees: table<id: string, email: string, first_name: string, last_name: string>, signed_documents: table<url: string, document_name: string, size: float, document_type: string>, recording: record<url: string, name: string, size: float>, termination_reason: string, termination_details: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/notary/notarization-requests/($session_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Notarization Request
#
# DELETE /public/v2/notary/notarization-requests/{session_request_id}
# operationId: deleteNotarizationRequest
export def "public-notary-notarization-requests delete" [
  session_request_id: string
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
  let full_url = (build-url $base $"/public/v2/notary/notarization-requests/($session_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Catalog Items Search
#
# GET /public/v2/product-catalog/items/search
# operationId: searchCatalogItems
export def "public-product-catalog-items-search searchCatalogItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # Page number. (e.g. 1)
  --per-page: float # Items per page. (e.g. 10)
  --qp-query: string # Search query. Searches the following fields: Title, SKU, description, category name, custom fields name and value.  (e.g. coffee)
  --order-by: string@order-by-completer-4 # Ordering principle for displaying search results. (e.g. -date_modified)
  --types: list # Filter by catalog item types. (e.g. [regular])
  --billing-types: list # Filter by billing types. (e.g. [one_time])
  --exclude-uuids: list # A list of item uuids to be excluded from search. (e.g. [1725f759-3a1c-64e3-2daa-f67eafa589d7, 06cb0ce9-094b-1f38-2fe6-0a9d226cd22c])
  --category-id: string # Category id. (e.g. 06cb0ce9-094b-1f38-2fe6-0a9d226cd22c)
  --no-category: oneof<nothing, bool> # e.g. true
]: nothing -> record<items: table<billing_cycle: int, billing_type: string, bundle_items_count: int, workspace_id: string, category_id: string, category_name: string, created_by: string, cost: float, currency: string, custom_fields: list, date_created: string, date_modified: string, description: string, image_src: string, images: list, max_tier_value: float, min_tier_value: float, modified_by: string, price: float, pricing_method: int, sku: string, title: string, tiers: list, type: string, uuid: string, highlights: record>, has_more_items: bool, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "types" $types "multi") (serialize-qp "billing_types" $billing_types "multi") (serialize-qp "exclude_uuids" $exclude_uuids "multi") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "no_category" $no_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v2/product-catalog/items/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Catalog Item
#
# POST /public/v2/product-catalog/items
# operationId: createCatalogItem
# --bundle_items item shape: {quantity?: int, item_or_uuid?: any}
# --images item shape: {is_main?: bool, order?: float, src?: string}
# --custom_fields item shape: {name?: string, value?: string}
# --price_configuration shape: {currency: string, price?: float, cost?: float, billing_type?: string, billing_cycle?: string, tiers?: list, pricing_method: "0"|"1"|"2"}
export def "public-product-catalog-items createCatalogItem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string
  --category-id: string # nullable
  --sku: string # nullable
  --description: string # nullable
  --type: string@type-completer # default: regular, e.g. regular
  --bundle-items: list # nullable — item shape: {quantity?: int, item_or_uuid?: any}
  --images: list # nullable — item shape: {is_main?: bool, order?: float, src?: string}
  --custom-fields: list # nullable — item shape: {name?: string, value?: string}
  price_configuration: record # shape: {currency: string, price?: float, cost?: float, billing_type?: string, billing_cycle?: string, tiers?: list, pricing_method: "0"|"1"|"2"}
]: any -> record<uuid: string, title: string, date_created: string, date_modified: string, created_by: string, modified_by: string, category_id: string, category_name: string, type: string, bundle_items: table<quantity: int, item: any>, default_price_configuration: record<currency: string, price: float, cost: float, billing_type: string, billing_cycle: string, tiers: list<record>, pricing_method: float, uuid: string>, variants: table<uuid: string, sku: string, description: string, custom_fields: list, images: list, date_created: string, date_modified: string, status: float, price_configurations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v2/product-catalog/items")
  let body = {title: $title, category_id: $category_id, sku: $sku, description: $description, type: $type, bundle_items: $bundle_items, images: $images, custom_fields: $custom_fields, price_configuration: $price_configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Catalog Item Details
#
# GET /public/v2/product-catalog/items/{item_uuid}
# operationId: getCatalogItem
export def "public-product-catalog-items get" [
  item_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<uuid: string, title: string, date_created: string, date_modified: string, created_by: string, modified_by: string, category_id: string, category_name: string, type: string, bundle_items: table<quantity: int, item: any>, default_price_configuration: record<currency: string, price: float, cost: float, billing_type: string, billing_cycle: string, tiers: list<record>, pricing_method: float, uuid: string>, variants: table<uuid: string, sku: string, description: string, custom_fields: list, images: list, date_created: string, date_modified: string, status: float, price_configurations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/product-catalog/items/($item_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Catalog Item
#
# PATCH /public/v2/product-catalog/items/{item_uuid}
# operationId: updateCatalogItem
# --bundle_items item shape: {quantity?: int, item_or_uuid?: any}
# --product_variant shape: {sku?: string, description?: string, images?: list, custom_fields?: list, price_configuration?: record}
export def "public-product-catalog-items updateCatalogItem" [
  item_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string
  --category-id: string # nullable
  --type: string@type-completer # default: regular, e.g. regular
  --bundle-items: list # nullable — item shape: {quantity?: int, item_or_uuid?: any}
  --product-variant: record # shape: {sku?: string, description?: string, images?: list, custom_fields?: list, price_configuration?: record}
]: any -> record<uuid: string, title: string, date_created: string, date_modified: string, created_by: string, modified_by: string, category_id: string, category_name: string, type: string, bundle_items: table<quantity: int, item: any>, default_price_configuration: record<currency: string, price: float, cost: float, billing_type: string, billing_cycle: string, tiers: list<record>, pricing_method: float, uuid: string>, variants: table<uuid: string, sku: string, description: string, custom_fields: list, images: list, date_created: string, date_modified: string, status: float, price_configurations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v2/product-catalog/items/($item_uuid)")
  let body = {title: $title, category_id: $category_id, type: $type, bundle_items: $bundle_items, product_variant: $product_variant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Catalog Item
#
# DELETE /public/v2/product-catalog/items/{item_uuid}
# operationId: deleteCatalogItem
export def "public-product-catalog-items delete" [
  item_uuid: string
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
  let full_url = (build-url $base $"/public/v2/product-catalog/items/($item_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quote update
#
# PUT /public/v1/documents/{document_id}/quotes/{quote_id}
# operationId: quoteUpdate
# --summary shape: {custom_columns?: record, discounts?: record, fees?: record, taxes?: record}
# --sections item shape: {id?: string, name?: string, summary?: record, items?: list, settings?: record}
# --settings shape: {selection_type?: "custom"|"single"|"multiple"}
export def "public-documents-quotes quoteUpdate" [
  document_id: string
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency: string # Currency code (ISO 4217) (e.g. USD)
  --summary: record # Summary settings containing adjustments (discounts, fees, taxes) and custom columns that apply to the entire quote / section total. — shape: {custom_columns?: record, discounts?: record, fees?: record, taxes?: record}
  --sections: list # Quote sections - this property overrides existing sections in the specified order. If you want to change only one section, you must still pass other sections IDs. Otherwise these sections will be removed. — item shape: {id?: string, name?: string, summary?: record, items?: list, settings?: record}
  --settings: record # Quote settings. Denotes whether a quote is optional or selected, and selection type inside the section - single, multiple, or custom. — shape: {selection_type?: "custom"|"single"|"multiple"}
]: any -> record<id: string, currency: string, total: string, summary: record<total: string, subtotal: string, one_time_subtotal: string, recurring_subtotal: list<record>, total_qty: string, discounts: record, taxes: record, fees: record, custom_fields: record, total_discount: string, total_tax: string, total_fee: string, total_savings: string, total_contract_value: string>, sections: table<id: string, name: string, summary: record, columns: list, items: list, total: string, settings: record>, merge_rules: table<id: string, enabled: bool, action: record, condition: record>, settings: record<selection_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/documents/($document_id)/quotes/($quote_id)")
  let body = {currency: $currency, summary: $summary, sections: $sections, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Workspaces
#
# GET /public/v1/workspaces
# operationId: getWorkspacesList
export def "public-workspaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of elements in page. (format: int32, default: 50, e.g. 10)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
]: nothing -> record<total: int, results: table<id: string, name: string, date_created: string, owner: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/workspaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Workspace
#
# POST /public/v1/workspaces
# operationId: createWorkspace
export def "public-workspaces createWorkspace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A name for the new workspace. (e.g. A new workspace)
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/public/v1/workspaces")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate Workspace
#
# POST /public/v1/workspaces/{workspace_id}/deactivate
# operationId: deactivateWorkspace
export def "public-workspaces-deactivate deactivateWorkspace" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspace_id)/deactivate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Users
#
# GET /public/v1/users
# operationId: listUsers
export def "public-users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of elements in page. (format: int32, default: 50, e.g. 10)
  --page: int # Page number. (format: int32, default: 1, e.g. 1)
  --show-removed: oneof<nothing, bool> # Filter option - show users with removed memberships. (default: true, e.g. false)
]: nothing -> record<total: int, results: table<user_id: string, email: string, first_name: string, last_name: string, phone_number: string, license: string, is_organization_owner: bool, workspaces: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "show_removed" $show_removed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create User
#
# POST /public/v1/users
# operationId: createUser
# --user shape: {email?: string, first_name?: string, last_name?: string, phone_number?: string}
# --workspaces item shape: {workspace_id?: string, role?: "Admin"|"Manager"|"Member"|"Collaborator"}
export def "public-users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notify-user: oneof<nothing, bool> # Send a confirmation email to the user that was added to workspace(s). (e.g. true)
  --notify-ws-admins: oneof<nothing, bool> # Send a confirmation email to all workspace admins indicating that the user has been added to the workspace. (e.g. false)
  user: record # User info — shape: {email?: string, first_name?: string, last_name?: string, phone_number?: string}
  workspaces: list # Info for adding a user to a workspace(s) — item shape: {workspace_id?: string, role?: "Admin"|"Manager"|"Member"|"Collaborator"}
  license: string@license-completer
]: any -> record<user_id: string, workspaces: table<workspace_id: string, role: string, member_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify_user" $notify_user "scalar") (serialize-qp "notify_ws_admins" $notify_ws_admins "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/users" $qp)
  let body = {user: $user, workspaces: $workspaces, license: $license} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get User Details by ID
#
# GET /public/v1/users/{user_id}
# operationId: detailsUser
export def "public-users detailsUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user_id: string, email: string, first_name: string, last_name: string, phone_number: string, license: string, is_organization_owner: bool, workspaces: table<role: string, workspace_id: string, membership_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Member to Workspace
#
# POST /public/v1/workspaces/{workspace_id}/members
# operationId: addMember
export def "public-workspaces-members addMember" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notify-user: oneof<nothing, bool> # Send a confirmation email to the user that was added to workspace(s). (e.g. true)
  --notify-ws-admins: oneof<nothing, bool> # Send a confirmation email to all workspace admins indicating that the user has been added to the workspace. (e.g. false)
  user_id: string # User id. (e.g. 2eWSKSvVqmuVCnuUK3iWwD)
  role: string@role-completer # Role for a member. (e.g. Member)
]: any -> record<member_id: string, workspace_id: string, role: string, email: string, first_name: string, last_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify_user" $notify_user "scalar") (serialize-qp "notify_ws_admins" $notify_ws_admins "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/v1/workspaces/($workspace_id)/members" $qp)
  let body = {user_id: $user_id, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Member from Workspace
#
# DELETE /public/v1/workspaces/{workspace_id}/members/{member_id}
# operationId: removeMember
export def "public-workspaces-members removeMember" [
  workspace_id: string
  member_id: string
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
  let full_url = (build-url $base $"/public/v1/workspaces/($workspace_id)/members/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Member Role in Workspace
#
# PATCH /public/v1/workspaces/{workspace_id}/members/{member_id}/role
# operationId: changeMemberRole
export def "public-workspaces-members-role changeMemberRole" [
  workspace_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: string@role-completer # Role for a member. (e.g. Member)
]: any -> record<member_id: string, workspace_id: string, role: string, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspace_id)/members/($member_id)/role")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create API Key
#
# POST /public/v1/workspaces/{workspace_id}/api-keys
# operationId: createApiKey
export def "public-workspaces-api-keys createApiKey" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # e.g. 2eWSKSvVqmuVCnuUK3iWwD
  type: string@type-completer-1 # A type of API key. (default: sandbox, e.g. sandbox)
]: any -> record<user_id: string, type: string, workspace_id: string, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/v1/workspaces/($workspace_id)/api-keys")
  let body = {user_id: $user_id, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recent SMS Opt-out
#
# GET /public/v1/sms-opt-outs
# operationId: listRecentSmsOptOuts
export def "public-sms-opt-outs listRecentSmsOptOuts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --timestamp-from: string # The start of the timestamp.   If no timestamp is provided, 1 hour before the current time will be used.  (format: date-time, e.g. 2025-01-28T00:00:00Z)
  --timestamp-to: string # The end of the timestamp range.   If no timestamp is provided the current time will be used.  (format: date-time, e.g. 2025-01-28T23:59:59Z)
]: nothing -> record<results: table<phone_number: string, status: string, opt_out_changed: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp_from" $timestamp_from "scalar") (serialize-qp "timestamp_to" $timestamp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/v1/sms-opt-outs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] Create DOCX Export Task
#
# POST /public/beta/documents/{document_id}/docx-export-tasks
# operationId: createExportDocxTask
export def "public-beta-documents-docx-export-tasks createExportDocxTask" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, document_id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/beta/documents/($document_id)/docx-export-tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] DOCX Export Task
#
# GET /public/beta/documents/{document_id}/docx-export-tasks/{task_id}
# operationId: getDocxExportTask
export def "public-beta-documents-docx-export-tasks get" [
  document_id: string
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, document_id: string, status: string, docx_items: table<section_title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/beta/documents/($document_id)/docx-export-tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] Document Summary
#
# GET /public/beta/documents/{document_id}/summary
# operationId: getDocumentSummary
export def "public-beta-documents-summary get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2 # Document summary granularity to return.  (e.g. detailed)
]: nothing -> record<type: string, summary: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/beta/documents/($document_id)/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] Document Content
#
# GET /public/beta/documents/{document_id}/content
# operationId: getDocumentContent
export def "public-beta-documents-content get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Document content representation to return.  (e.g. plaintext)
]: nothing -> record<format: string, content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/beta/documents/($document_id)/content" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] Get AI Metadata for a Document
#
# GET /public/beta/documents/{document_id}/ai-metadata
# operationId: getDocumentAiMetadata
export def "public-beta-documents-ai-metadata get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of fields to return in one response. (default: 100, e.g. 100)
  --offset: int # Number of fields to skip before starting to collect the result set. For predictable paging, use multiples of `limit`.  (default: 0, e.g. 0)
]: nothing -> record<count: int, results: table<id: string, key: string, field_type: string, settings: record, value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/beta/documents/($document_id)/ai-metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# [Beta] List Documents Search
#
# GET /public/beta/documents/search
# operationId: searchDocumentsAi
export def "public-beta-documents-search searchDocumentsAi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Natural-language search query. Supports filtering by status, owner, dates, and folder. Also supports keyword content search across document titles and body text.
]: nothing -> record<results: table<document_id: string, name: string, status: string, date_created: string, owner: record, folder: record, extra_fields: record>, count: int, suggestions: table<text: string>, message: string, intent: table<field: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/public/beta/documents/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
