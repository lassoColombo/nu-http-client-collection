# Auto-generated client for DocuSign Rooms API - v2 vv2
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/rooms.rest.swagger-v2.json
# Auth: --token flag or $env.DOCUSIGN_ROOMS_API_V2_TOKEN

const BASE_URL = "https://demo.rooms.docusign.com/restapi"
const DEFAULT_AUTH = "jwt"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DOCUSIGN_ROOMS_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "jwt" => { {headers: {Authorization: $"JWT ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://demo.rooms.docusign.com/restapi"] }
def auth-scheme-completer [] { ["jwt"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/plain" "text/xml"] }
def listingSource-completer [] { ["MLS" "PublicRecords"] }
def accessLevel-completer [] { ["Admin" "Company" "Contributor" "Office" "Region"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts GetAccountInformation" } } | get name | first)
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

# Gets account information.
#
# GET /v2/accounts/{accountId}
# operationId: Accounts_GetAccountInformation
export def "accounts GetAccountInformation" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<companyId: int, name: string, companyVersion: string, docuSignAccountGuid: string, defaultFieldSetId: string, requireOfficeLibraryAssignments: bool> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about or the contents of a document.
#
# GET /v2/accounts/{accountId}/documents/{documentId}
# operationId: Documents_GetDocument
export def "accounts-documents GetDocument" [
  documentId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --includeContents: string@bool-completer # When **true,** includes the contents of the document in the `base64Contents` property of the response. The default value is **false.** (default: false)
]: nothing -> record<documentId: int, name: string, roomId: int, ownerId: int, size: int, folderId: int, createdDate: string, isSigned: bool, contentType: string, base64Contents: string, isDynamic: bool> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeContents" $includeContents "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/documents/($documentId)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a specified document.
#
# DELETE /v2/accounts/{accountId}/documents/{documentId}
# operationId: Documents_DeleteDocument
export def "accounts-documents DeleteDocument" [
  documentId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/documents/($documentId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Grants a user access to a document.
#
# POST /v2/accounts/{accountId}/documents/{documentId}/users
# operationId: Documents_CreateDocumentUser
export def "accounts-documents-users CreateDocumentUser" [
  documentId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  userId: int # The ID of the user. (format: int32)
]: any -> record<userId: int, documentId: int, name: string, hasAccess: bool, canApproveTask: bool, canAssignToTaskList: bool, canCopy: bool, canDelete: bool, canRemoveFromTaskList: bool, canRemoveApproval: bool, canRename: bool, canShare: bool, canViewActivity: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/documents/($documentId)/users")
  let body = {userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets eSignature Permission Profiles.
#
# GET /v2/accounts/{accountId}/esign_permission_profiles
# operationId: ESignPermissionProfiles_GetESignPermissionProfiles
export def "accounts-esign-permission-profiles GetESignPermissionProfiles" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<permissionProfiles: table<eSignPermissionProfileId: string, name: string, settings: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/esign_permission_profiles")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an external form fill session.
#
# POST /v2/accounts/{accountId}/external_form_fill_sessions
# operationId: ExternalFormFillSessions_CreateExternalFormFillSession
export def "accounts-external-form-fill-sessions CreateExternalFormFillSession" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --formId: string # (Required) The ID of the form.  Example: `5be324eb-xxxx-xxxx-xxxx-208065181be9`
  roomId: int # (Required) The ID of the room. (format: int32)
  --formIds: list
  --xFrameAllowedUrl: string # (Optional) This property specifies the origin on which the page is allowed to display in a frame.
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/external_form_fill_sessions")
  let body = {formId: $formId, roomId: $roomId, formIds: $formIds, xFrameAllowedUrl: $xFrameAllowedUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a field set.
#
# GET /v2/accounts/{accountId}/field_sets/{fieldSetId}
# operationId: Fields_GetFieldSet
export def "accounts-field-sets GetFieldSet" [
  fieldSetId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --fieldsCustomDataFilters: list # An comma-separated list that limits the fields to return:  - `IsRequiredOnCreate`: include fields that are required in room creation. - `IsRequiredOnSubmit`: include fields that are required when submitting a room for review.
]: nothing -> record<fieldSetId: string, title: string, fields: table<fieldId: string, fieldDefinitionId: string, title: string, apiName: string, type: string, fields: list, configuration: record, customData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsCustomDataFilters" $fieldsCustomDataFilters "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/field_sets/($fieldSetId)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets form groups.
#
# GET /v2/accounts/{accountId}/form_groups
# operationId: FormGroups_GetFormGroups
export def "accounts-form-groups GetFormGroups" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The starting zero-based index position of the results set. The default value is `0`. (format: int32, default: 0)
]: nothing -> record<formGroups: table<formGroupId: string, name: string, formCount: int>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a form group.
#
# POST /v2/accounts/{accountId}/form_groups
# operationId: FormGroups_CreateFormGroup
export def "accounts-form-groups CreateFormGroup" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the group.
]: any -> record<formGroupId: string, name: string, officeIds: list<int>, forms: table<formId: string, name: string, isRequired: bool, lastUpdatedDate: string, viewingUserHasAccess: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a form group.
#
# GET /v2/accounts/{accountId}/form_groups/{formGroupId}
# operationId: FormGroups_GetFormGroup
export def "accounts-form-groups GetFormGroup" [
  formGroupId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<formGroupId: string, name: string, officeIds: list<int>, forms: table<formId: string, name: string, isRequired: bool, lastUpdatedDate: string, viewingUserHasAccess: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renames a form group.
#
# PUT /v2/accounts/{accountId}/form_groups/{formGroupId}
# operationId: FormGroups_RenameFormGroup
export def "accounts-form-groups RenameFormGroup" [
  formGroupId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the office.
]: any -> record<formGroupId: string, name: string, officeIds: list<int>, forms: table<formId: string, name: string, isRequired: bool, lastUpdatedDate: string, viewingUserHasAccess: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a form group.
#
# DELETE /v2/accounts/{accountId}/form_groups/{formGroupId}
# operationId: FormGroups_DeleteFormGroup
export def "accounts-form-groups DeleteFormGroup" [
  formGroupId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the user's form group forms.
#
# GET /v2/accounts/{accountId}/form_groups/{formGroupId}/forms
# operationId: FormGroupForms_GetFormGroupForms
export def "accounts-form-groups-forms GetFormGroupForms" [
  formGroupId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return.  Default value is 100 and max value is 100  (format: int32, default: 100)
  --startPosition: int # The starting point of the list. The default is 0.  (format: int32, default: 0)
]: nothing -> record<forms: table<formId: string, name: string, isRequired: bool, lastUpdatedDate: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)/forms" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes a form from a form group.
#
# POST /v2/accounts/{accountId}/form_groups/{formGroupId}/unassign_form/{formId}
# operationId: FormGroups_RemoveFormGroupForm
export def "accounts-form-groups-unassign-form RemoveFormGroupForm" [
  formGroupId: string
  formId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)/unassign_form/($formId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assigns a form to a form group.
#
# POST /v2/accounts/{accountId}/form_groups/{formGroupId}/assign_form
# operationId: FormGroups_AssignFormGroupForm
export def "accounts-form-groups-assign-form AssignFormGroupForm" [
  formGroupId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  formId: string # The ID of the form.  Example: `5be324eb-xxxx-xxxx-xxxx-208065181be9`  (format: uuid)
  --isRequired: string@bool-completer # **True** if the form is required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)/assign_form")
  let body = {formId: $formId, isRequired: $isRequired} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Grants an office access to a form group.
#
# POST /v2/accounts/{accountId}/form_groups/{formGroupId}/grant_office_access/{officeId}
# operationId: FormGroups_GrantOfficeAccessToFormGroup
export def "accounts-form-groups-grant-office-access GrantOfficeAccessToFormGroup" [
  formGroupId: string
  officeId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)/grant_office_access/($officeId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke an office's access to a form group.
#
# POST /v2/accounts/{accountId}/form_groups/{formGroupId}/revoke_office_access/{officeId}
# operationId: FormGroups_RevokeOfficeAccessFromFormGroup
export def "accounts-form-groups-revoke-office-access RevokeOfficeAccessFromFormGroup" [
  formGroupId: string
  officeId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_groups/($formGroupId)/revoke_office_access/($officeId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets form libraries.
#
# GET /v2/accounts/{accountId}/form_libraries
# operationId: FormLibraries_GetFormLibraries
export def "accounts-form-libraries GetFormLibraries" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The starting zero-based index position of the results set. The default value is `0`. (format: int32, default: 0)
]: nothing -> record<formsLibrarySummaries: table<formsLibraryId: string, name: string, formCount: int>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_libraries" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the forms in a form library.
#
# GET /v2/accounts/{accountId}/form_libraries/{formLibraryId}/forms
# operationId: FormLibraries_GetFormLibraryForms
export def "accounts-form-libraries-forms GetFormLibraryForms" [
  formLibraryId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # (Optional) The starting zero-based index position of the results set. The default value is `0`. (format: int32, default: 0)
]: nothing -> record<forms: table<libraryFormId: string, name: string, lastUpdatedDate: string, viewingUserHasAccess: bool>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_libraries/($formLibraryId)/forms" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all associations by provider.
#
# GET /v2/accounts/{accountId}/form_providers/{providerId}/associations
# operationId: FormProviderAssociations_GetFormProviderAssociations
export def "accounts-form-providers-associations GetFormProviderAssociations" [
  providerId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The total number of associations to be returned.  (format: int32, default: 100)
  --startPosition: int # The starting position on the list.  (format: int32, default: 0)
]: nothing -> record<formProviderAssociations: table<associationId: string, providerId: string, lastUpdateDate: string, formProviderAssociationGuid: string, formProviderAssociationName: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/form_providers/($providerId)/associations" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets form details.
#
# GET /v2/accounts/{accountId}/forms/{formId}/details
# operationId: FormDetails_GetFormDetails
export def "accounts-forms-details GetFormDetails" [
  formId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<formId: string, name: string, createdDate: string, lastUpdatedDate: string, availableOnDate: string, ownerName: string, version: string, numberOfPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/forms/($formId)/details")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets countries.
#
# GET /v2/countries
# operationId: Countries_GetCountries
export def "countries GetCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<countries: table<countryId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/countries")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets closing statuses.
#
# GET /v2/closing_statuses
# operationId: ClosingStatuses_GetClosingStatuses
export def "closing-statuses GetClosingStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<closingStatuses: table<closingStatusId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/closing_statuses")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets contact sides.
#
# GET /v2/contact_sides
# operationId: ContactSides_GetContactSides
export def "contact-sides GetContactSides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<contactSides: table<contactSideId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contact_sides")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets financing types.
#
# GET /v2/financing_types
# operationId: FinancingTypes_GetFinancingTypes
export def "financing-types GetFinancingTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<financingTypes: table<financingTypeId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/financing_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets origins of leads.
#
# GET /v2/origins_of_leads
# operationId: OriginsOfLeads_GetOriginsOfLeads
export def "origins-of-leads GetOriginsOfLeads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<originsOfLeads: table<originOfLeadId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/origins_of_leads")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets property types.
#
# GET /v2/property_types
# operationId: PropertyTypes_GetPropertyTypes
export def "property-types GetPropertyTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<propertyTypes: table<propertyTypeId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/property_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets room contact types.
#
# GET /v2/room_contact_types
# operationId: RoomContactTypes_GetRoomContactTypes
export def "room-contact-types GetRoomContactTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<roomContactTypes: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/room_contact_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets seller decision types.
#
# GET /v2/seller_decision_types
# operationId: SellerDecisionTypes_GetSellerDecisionTypes
export def "seller-decision-types GetSellerDecisionTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<sellerDecisionTypes: table<sellerDecisionTypeId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/seller_decision_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets special circumstance types.
#
# GET /v2/special_circumstance_types
# operationId: SpecialCircumstanceTypes_GetSpecialCircumstanceTypes
export def "special-circumstance-types GetSpecialCircumstanceTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<specialCircumstanceTypes: table<specialCircumstanceTypeId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/special_circumstance_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets task date types.
#
# GET /v2/task_date_types
# operationId: TaskDateTypes_GetTaskDateTypes
export def "task-date-types GetTaskDateTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<taskDateTypes: table<taskDateTypeId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/task_date_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets task responsibility types.
#
# GET /v2/task_responsibility_types
# operationId: TaskResponsibilityTypes_GetTaskResponsibilityTypes
export def "task-responsibility-types GetTaskResponsibilityTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<taskResponsibilityTypes: table<taskResponsibilityTypeId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/task_responsibility_types")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the list of valid task statuses.
#
# GET /v2/task_statuses
# operationId: TaskStatuses_GetTaskStatuses
export def "task-statuses GetTaskStatuses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<taskStatuses: table<taskStatusId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/task_statuses")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets transaction sides.
#
# GET /v2/transaction_sides
# operationId: TransactionSides_GetTransactionSides
export def "transaction-sides GetTransactionSides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<transactionSides: table<transactionSideId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/transaction_sides")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets states.
#
# GET /v2/states
# operationId: States_GetStates
export def "states GetStates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<states: table<stateId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/states")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets valid currencies.
#
# GET /v2/currencies
# operationId: Currencies_GetCurrencies
export def "currencies GetCurrencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<currencies: table<currencyId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/currencies")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets time zones.
#
# GET /v2/time_zones
# operationId: TimeZones_GetTimeZones
export def "time-zones GetTimeZones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<timeZones: table<timeZoneId: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/time_zones")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets offices.
#
# GET /v2/accounts/{accountId}/offices
# operationId: Offices_GetOffices
export def "accounts-offices GetOffices" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The starting zero-based index position of the results set from which to begin returning values. The default value is `0`. (format: int32, default: 0)
  --onlyAccessible: string@bool-completer # When **true,** the response only includes the offices that are accessible to the current user. (default: false)
  --search: string # Filters returned records by the specified string. The response only includes records containing this string in the office `name` field.
]: nothing -> record<officeSummaries: table<officeId: int, name: string, regionId: int, address1: string, address2: string, city: string, stateId: string, postalCode: string, countryId: string, timeZoneId: string, phone: string, createdDate: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "onlyAccessible" $onlyAccessible "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/offices" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an office.
#
# POST /v2/accounts/{accountId}/offices
# operationId: Offices_CreateOffice
export def "accounts-offices CreateOffice" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # The name of the office.
  --regionId: int # The ID of the region. This is the ID that the system generated when you created the region. (format: int32)
  --address1: string # First line of the office street address.
  --address2: string # Second line of the office street address.
  --city: string # City name or metropolitan area of the office address.
  --stateId: string # A concatenation of the two-letter country code with the state/province/region of the office address.  Example: `US-OH` (for Ohio)
  --postalCode: string # Postal code or ZIP code of the office address.
  --countryId: string # The two-letter country code of the office address (for example, "UK" for United Kingdom).
  --timeZoneId: string # The ID of the time zone for the office address.  Example: `eastern` (for the Eastern US Time Zone)
  --phone: string # Phone number of the office.
]: any -> record<officeId: int, name: string, regionId: int, address1: string, address2: string, city: string, stateId: string, postalCode: string, countryId: string, timeZoneId: string, phone: string, createdDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/offices")
  let body = {name: $name, regionId: $regionId, address1: $address1, address2: $address2, city: $city, stateId: $stateId, postalCode: $postalCode, countryId: $countryId, timeZoneId: $timeZoneId, phone: $phone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets information about an office.
#
# GET /v2/accounts/{accountId}/offices/{officeId}
# operationId: Offices_GetOffice
export def "accounts-offices GetOffice" [
  officeId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<officeId: int, name: string, regionId: int, address1: string, address2: string, city: string, stateId: string, postalCode: string, countryId: string, timeZoneId: string, phone: string, createdDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/offices/($officeId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an office.
#
# DELETE /v2/accounts/{accountId}/offices/{officeId}
# operationId: Offices_DeleteOffice
export def "accounts-offices DeleteOffice" [
  officeId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/offices/($officeId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the number and type of objects that reference an office.
#
# GET /v2/accounts/{accountId}/offices/{officeId}/reference_counts
# operationId: Offices_GetReferenceCounts
export def "accounts-offices-reference-counts GetReferenceCounts" [
  officeId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<referencesCounts: table<referenceType: string, referencedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/offices/($officeId)/reference_counts")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a region.
#
# POST /v2/accounts/{accountId}/regions
# operationId: Regions_CreateRegion
export def "accounts-regions CreateRegion" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --regionId: int # The ID of the region. This is the ID that the system generated when you created the region. (format: int32)
  name: string # The name of the office.
  --createdDate: string # The UTC date and time when the item was created. This is a read-only value that the service assigns.  Example: `2019-07-17T17:45:42.783Z`   (format: date-time)
]: any -> record<regionId: int, name: string, createdDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/regions")
  let body = {regionId: $regionId, name: $name, createdDate: $createdDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets regions.
#
# GET /v2/accounts/{accountId}/regions
# operationId: Regions_GetRegions
export def "accounts-regions GetRegions" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The starting zero-based index position of the results set from which to begin returning values. The default value is `0`. (format: int32, default: 0)
  --managedOnly: string@bool-completer # When **true,** only the regions that the current user manages are returned. The default value is **false.** (default: false)
]: nothing -> record<regionSummaries: table<regionId: int, name: string, createdDate: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "managedOnly" $managedOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/regions" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a region.
#
# GET /v2/accounts/{accountId}/regions/{regionId}
# operationId: Regions_GetRegion
export def "accounts-regions GetRegion" [
  regionId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<regionId: int, name: string, createdDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/regions/($regionId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a region.
#
# DELETE /v2/accounts/{accountId}/regions/{regionId}
# operationId: Regions_DeleteRegion
export def "accounts-regions DeleteRegion" [
  regionId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/regions/($regionId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the number and type of objects that reference a region.
#
# GET /v2/accounts/{accountId}/regions/{regionId}/reference_counts
# operationId: Regions_GetRegionReferenceCounts
export def "accounts-regions-reference-counts GetRegionReferenceCounts" [
  regionId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<referenceCounts: table<referenceType: string, referenceCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/regions/($regionId)/reference_counts")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a role.
#
# POST /v2/accounts/{accountId}/roles
# operationId: Roles_CreateRole
# --permissions shape: {canAddUsersToRooms?: bool, canCreateRooms?: bool, canSubmitRoomsForReview?: bool, canCloseRooms?: bool, canReopenRooms?: bool, canDeleteOwnedRooms?: bool, autoAccessToRooms?: bool, canExportRoomActivityDetailsPeople?: bool, canCopyRoomDetails?: bool, canEditAnyRoomRole?: bool, canEditInvitedRoomRole?: bool, canEditRoomSide?: bool, canManageAnyUserRoomAccess?: bool, canManageInvitedUserRoomAccess?: bool, isHiddenInRoom?: bool, canManageRoomOwners?: bool, canDeleteRooms?: bool, canConnectToMortgageCadence?: bool, autoAccessToRoomsInOfficeOnly?: bool, canViewRoomDetails?: bool, canViewAndEditRoomDetails?: bool, canSendRoomDetailsToLoneWolf?: bool, canAddDocuments?: bool, canAddDocumentsFromFormGroups?: bool, canAddDocumentsFromFormLibraries?: bool, documentsViewableByOthersInRoomFromOffice?: bool, documentsAutoOwnedByPeers?: bool, canDeleteOwnedDocuments?: bool, canDeleteSignedDocuments?: bool, canDeleteUnsignedDocuments?: bool, canManageSharedDocs?: bool, canManageFormGroups?: bool, canShareDocsNotOwned?: bool, canCreateFormTemplates?: bool, canManageFormPackets?: bool, canAddTasksToAnyTaskLists?: bool, canEditEditableTasks?: bool, canEditAnyTasks?: bool, canDeleteDeletableTasks?: bool, canDeleteAnyTasks?: bool, canApplyTaskList?: bool, canRemoveAnyTaskList?: bool, canSubmitTaskList?: bool, canAutoSubmitTaskList?: bool, canReviewTaskList?: bool, canAutoApproveTaskList?: bool, canManageTaskTemplatesForAllRegionsAllOffices?: bool, canApplyRoomTemplates?: bool, canAddTasksToRooms?: bool, canReviewAnyTask?: bool, canManageDocsOnAnyTask?: bool, canAddMemberAndSetRoleLowerAccessLevel?: bool, canAddMemberAndSetRoleSameAccessLevel?: bool, canChangeMemberRoleLowerAccessLevel?: bool, canChangeMemberRoleSameAccessLevel?: bool, canManageMemberLowerAccessLevel?: bool, canManageMemberSameAccessLevel?: bool, canRemoveCompanyMemberLowerAccessLevel?: bool, canRemoveCompanyMemberSameAccessLevel?: bool, canManageAccount?: bool, canManageLogo?: bool, canManageRolesAndPermissions?: bool, canManageRoomDetails?: bool, canManageRoomTemplates?: bool, canManageIntegrationSettings?: bool, canExportCompanyUsageReport?: bool}
export def "accounts-roles CreateRole" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # The name of the role.
  --isExternal: string@bool-completer # When **true,** the role is an external role. You assign external roles to people from outside your company when you invite them into a room.
  --permissions: record # Contains details about permissions. — shape: {canAddUsersToRooms?: bool, canCreateRooms?: bool, canSubmitRoomsForReview?: bool, canCloseRooms?: bool, canReopenRooms?: bool, canDeleteOwnedRooms?: bool, autoAccessToRooms?: bool, canExportRoomActivityDetailsPeople?: bool, canCopyRoomDetails?: bool, canEditAnyRoomRole?: bool, canEditInvitedRoomRole?: bool, canEditRoomSide?: bool, canManageAnyUserRoomAccess?: bool, canManageInvitedUserRoomAccess?: bool, isHiddenInRoom?: bool, canManageRoomOwners?: bool, canDeleteRooms?: bool, canConnectToMortgageCadence?: bool, autoAccessToRoomsInOfficeOnly?: bool, canViewRoomDetails?: bool, canViewAndEditRoomDetails?: bool, canSendRoomDetailsToLoneWolf?: bool, canAddDocuments?: bool, canAddDocumentsFromFormGroups?: bool, canAddDocumentsFromFormLibraries?: bool, documentsViewableByOthersInRoomFromOffice?: bool, documentsAutoOwnedByPeers?: bool, canDeleteOwnedDocuments?: bool, canDeleteSignedDocuments?: bool, canDeleteUnsignedDocuments?: bool, canManageSharedDocs?: bool, canManageFormGroups?: bool, canShareDocsNotOwned?: bool, canCreateFormTemplates?: bool, canManageFormPackets?: bool, canAddTasksToAnyTaskLists?: bool, canEditEditableTasks?: bool, canEditAnyTasks?: bool, canDeleteDeletableTasks?: bool, canDeleteAnyTasks?: bool, canApplyTaskList?: bool, canRemoveAnyTaskList?: bool, canSubmitTaskList?: bool, canAutoSubmitTaskList?: bool, canReviewTaskList?: bool, canAutoApproveTaskList?: bool, canManageTaskTemplatesForAllRegionsAllOffices?: bool, canApplyRoomTemplates?: bool, canAddTasksToRooms?: bool, canReviewAnyTask?: bool, canManageDocsOnAnyTask?: bool, canAddMemberAndSetRoleLowerAccessLevel?: bool, canAddMemberAndSetRoleSameAccessLevel?: bool, canChangeMemberRoleLowerAccessLevel?: bool, canChangeMemberRoleSameAccessLevel?: bool, canManageMemberLowerAccessLevel?: bool, canManageMemberSameAccessLevel?: bool, canRemoveCompanyMemberLowerAccessLevel?: bool, canRemoveCompanyMemberSameAccessLevel?: bool, canManageAccount?: bool, canManageLogo?: bool, canManageRolesAndPermissions?: bool, canManageRoomDetails?: bool, canManageRoomTemplates?: bool, canManageIntegrationSettings?: bool, canExportCompanyUsageReport?: bool}
]: any -> record<roleId: int, legacyRoleId: string, name: string, isDefaultForAdmin: bool, isExternal: bool, createdDate: string, isAssigned: bool, permissions: record<canAddUsersToRooms: bool, canCreateRooms: bool, canSubmitRoomsForReview: bool, canCloseRooms: bool, canReopenRooms: bool, canDeleteOwnedRooms: bool, autoAccessToRooms: bool, canExportRoomActivityDetailsPeople: bool, canCopyRoomDetails: bool, canEditAnyRoomRole: bool, canEditInvitedRoomRole: bool, canEditRoomSide: bool, canManageAnyUserRoomAccess: bool, canManageInvitedUserRoomAccess: bool, isHiddenInRoom: bool, canManageRoomOwners: bool, canDeleteRooms: bool, canConnectToMortgageCadence: bool, autoAccessToRoomsInOfficeOnly: bool, canViewRoomDetails: bool, canViewAndEditRoomDetails: bool, canSendRoomDetailsToLoneWolf: bool, canAddDocuments: bool, canAddDocumentsFromFormGroups: bool, canAddDocumentsFromFormLibraries: bool, documentsViewableByOthersInRoomFromOffice: bool, documentsAutoOwnedByPeers: bool, canDeleteOwnedDocuments: bool, canDeleteSignedDocuments: bool, canDeleteUnsignedDocuments: bool, canManageSharedDocs: bool, canManageFormGroups: bool, canShareDocsNotOwned: bool, canCreateFormTemplates: bool, canManageFormPackets: bool, canAddTasksToAnyTaskLists: bool, canEditEditableTasks: bool, canEditAnyTasks: bool, canDeleteDeletableTasks: bool, canDeleteAnyTasks: bool, canApplyTaskList: bool, canRemoveAnyTaskList: bool, canSubmitTaskList: bool, canAutoSubmitTaskList: bool, canReviewTaskList: bool, canAutoApproveTaskList: bool, canManageTaskTemplatesForAllRegionsAllOffices: bool, canApplyRoomTemplates: bool, canAddTasksToRooms: bool, canReviewAnyTask: bool, canManageDocsOnAnyTask: bool, canAddMemberAndSetRoleLowerAccessLevel: bool, canAddMemberAndSetRoleSameAccessLevel: bool, canChangeMemberRoleLowerAccessLevel: bool, canChangeMemberRoleSameAccessLevel: bool, canManageMemberLowerAccessLevel: bool, canManageMemberSameAccessLevel: bool, canRemoveCompanyMemberLowerAccessLevel: bool, canRemoveCompanyMemberSameAccessLevel: bool, canManageAccount: bool, canManageLogo: bool, canManageRolesAndPermissions: bool, canManageRoomDetails: bool, canManageRoomTemplates: bool, canManageIntegrationSettings: bool, canExportCompanyUsageReport: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/roles")
  let body = {name: $name, isExternal: $isExternal, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets roles.
#
# GET /v2/accounts/{accountId}/roles
# operationId: Roles_GetRoles
export def "accounts-roles GetRoles" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --onlyAssignable: string@bool-completer # This parameter is deprecated. Use `filterContext` instead. Note that `filterContext=AssignableRolesBasedOnCompanyPermissions` is equivalent to `onlyAssignable=true`. (default: false)
  --filterContext: string # Filters the roles by the calling user's permissions. Valid values are:  - `AllRoles` (default): All roles are returned. - `AssignableRolesBasedOnAllPermissions`: Only roles that the current user can assign to someone else are returned. In other words, given the permission set of the current user, only roles with a subset of those permissions (including the same exact permissions) will be returned. - `AssignableRolesBasedOnCompanyPermissions`: Only roles that the current user can assign to someone else based on company permissions are returned. Other permissions are not taken into account. In other words, given the company permissions of the current user, only roles with a subset of those company permissions (including the same exact company permissions) will be returned.
  --filter: string # A search filter that returns roles by the beginning of the role name. You can enter the beginning of the role name only to return all of the roles that begin with the text that you entered.   For example, if your company has set up roles such as Manager Beginner, Manager Pro, Agent Expert, and Agent Superstar, you could enter `Manager` to return all of the Manager roles (Manager Beginner and Manager Pro).  **Note:** You do not enter a wildcard (*) at the end of the name fragment.
  --startPosition: int # The starting zero-based index position of the result set. The default value is 0. (format: int32, default: 0)
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
]: nothing -> record<roles: table<roleId: int, legacyRoleId: string, name: string, isDefaultForAdmin: bool, isExternal: bool, createdDate: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "onlyAssignable" $onlyAssignable "scalar") (serialize-qp "filterContext" $filterContext "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/roles" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a role.
#
# GET /v2/accounts/{accountId}/roles/{roleId}
# operationId: Roles_GetRole
export def "accounts-roles GetRole" [
  roleId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --includeIsAssigned: string@bool-completer # When **true,** the response includes the `isAssigned` property, which specifies whether the role is currently assigned to any users. The default is **false.** (default: false)
]: nothing -> record<roleId: int, legacyRoleId: string, name: string, isDefaultForAdmin: bool, isExternal: bool, createdDate: string, isAssigned: bool, permissions: record<canAddUsersToRooms: bool, canCreateRooms: bool, canSubmitRoomsForReview: bool, canCloseRooms: bool, canReopenRooms: bool, canDeleteOwnedRooms: bool, autoAccessToRooms: bool, canExportRoomActivityDetailsPeople: bool, canCopyRoomDetails: bool, canEditAnyRoomRole: bool, canEditInvitedRoomRole: bool, canEditRoomSide: bool, canManageAnyUserRoomAccess: bool, canManageInvitedUserRoomAccess: bool, isHiddenInRoom: bool, canManageRoomOwners: bool, canDeleteRooms: bool, canConnectToMortgageCadence: bool, autoAccessToRoomsInOfficeOnly: bool, canViewRoomDetails: bool, canViewAndEditRoomDetails: bool, canSendRoomDetailsToLoneWolf: bool, canAddDocuments: bool, canAddDocumentsFromFormGroups: bool, canAddDocumentsFromFormLibraries: bool, documentsViewableByOthersInRoomFromOffice: bool, documentsAutoOwnedByPeers: bool, canDeleteOwnedDocuments: bool, canDeleteSignedDocuments: bool, canDeleteUnsignedDocuments: bool, canManageSharedDocs: bool, canManageFormGroups: bool, canShareDocsNotOwned: bool, canCreateFormTemplates: bool, canManageFormPackets: bool, canAddTasksToAnyTaskLists: bool, canEditEditableTasks: bool, canEditAnyTasks: bool, canDeleteDeletableTasks: bool, canDeleteAnyTasks: bool, canApplyTaskList: bool, canRemoveAnyTaskList: bool, canSubmitTaskList: bool, canAutoSubmitTaskList: bool, canReviewTaskList: bool, canAutoApproveTaskList: bool, canManageTaskTemplatesForAllRegionsAllOffices: bool, canApplyRoomTemplates: bool, canAddTasksToRooms: bool, canReviewAnyTask: bool, canManageDocsOnAnyTask: bool, canAddMemberAndSetRoleLowerAccessLevel: bool, canAddMemberAndSetRoleSameAccessLevel: bool, canChangeMemberRoleLowerAccessLevel: bool, canChangeMemberRoleSameAccessLevel: bool, canManageMemberLowerAccessLevel: bool, canManageMemberSameAccessLevel: bool, canRemoveCompanyMemberLowerAccessLevel: bool, canRemoveCompanyMemberSameAccessLevel: bool, canManageAccount: bool, canManageLogo: bool, canManageRolesAndPermissions: bool, canManageRoomDetails: bool, canManageRoomTemplates: bool, canManageIntegrationSettings: bool, canExportCompanyUsageReport: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeIsAssigned" $includeIsAssigned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/roles/($roleId)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a role.
#
# PUT /v2/accounts/{accountId}/roles/{roleId}
# operationId: Roles_UpdateRole
# --permissions shape: {canAddUsersToRooms?: bool, canCreateRooms?: bool, canSubmitRoomsForReview?: bool, canCloseRooms?: bool, canReopenRooms?: bool, canDeleteOwnedRooms?: bool, autoAccessToRooms?: bool, canExportRoomActivityDetailsPeople?: bool, canCopyRoomDetails?: bool, canEditAnyRoomRole?: bool, canEditInvitedRoomRole?: bool, canEditRoomSide?: bool, canManageAnyUserRoomAccess?: bool, canManageInvitedUserRoomAccess?: bool, isHiddenInRoom?: bool, canManageRoomOwners?: bool, canDeleteRooms?: bool, canConnectToMortgageCadence?: bool, autoAccessToRoomsInOfficeOnly?: bool, canViewRoomDetails?: bool, canViewAndEditRoomDetails?: bool, canSendRoomDetailsToLoneWolf?: bool, canAddDocuments?: bool, canAddDocumentsFromFormGroups?: bool, canAddDocumentsFromFormLibraries?: bool, documentsViewableByOthersInRoomFromOffice?: bool, documentsAutoOwnedByPeers?: bool, canDeleteOwnedDocuments?: bool, canDeleteSignedDocuments?: bool, canDeleteUnsignedDocuments?: bool, canManageSharedDocs?: bool, canManageFormGroups?: bool, canShareDocsNotOwned?: bool, canCreateFormTemplates?: bool, canManageFormPackets?: bool, canAddTasksToAnyTaskLists?: bool, canEditEditableTasks?: bool, canEditAnyTasks?: bool, canDeleteDeletableTasks?: bool, canDeleteAnyTasks?: bool, canApplyTaskList?: bool, canRemoveAnyTaskList?: bool, canSubmitTaskList?: bool, canAutoSubmitTaskList?: bool, canReviewTaskList?: bool, canAutoApproveTaskList?: bool, canManageTaskTemplatesForAllRegionsAllOffices?: bool, canApplyRoomTemplates?: bool, canAddTasksToRooms?: bool, canReviewAnyTask?: bool, canManageDocsOnAnyTask?: bool, canAddMemberAndSetRoleLowerAccessLevel?: bool, canAddMemberAndSetRoleSameAccessLevel?: bool, canChangeMemberRoleLowerAccessLevel?: bool, canChangeMemberRoleSameAccessLevel?: bool, canManageMemberLowerAccessLevel?: bool, canManageMemberSameAccessLevel?: bool, canRemoveCompanyMemberLowerAccessLevel?: bool, canRemoveCompanyMemberSameAccessLevel?: bool, canManageAccount?: bool, canManageLogo?: bool, canManageRolesAndPermissions?: bool, canManageRoomDetails?: bool, canManageRoomTemplates?: bool, canManageIntegrationSettings?: bool, canExportCompanyUsageReport?: bool}
export def "accounts-roles UpdateRole" [
  roleId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --name: string # The name of the role.
  --isExternal: string@bool-completer # When **true,** the role is an external role. You assign external roles to people from outside your company when you invite them into a room.
  --permissions: record # Contains details about permissions. — shape: {canAddUsersToRooms?: bool, canCreateRooms?: bool, canSubmitRoomsForReview?: bool, canCloseRooms?: bool, canReopenRooms?: bool, canDeleteOwnedRooms?: bool, autoAccessToRooms?: bool, canExportRoomActivityDetailsPeople?: bool, canCopyRoomDetails?: bool, canEditAnyRoomRole?: bool, canEditInvitedRoomRole?: bool, canEditRoomSide?: bool, canManageAnyUserRoomAccess?: bool, canManageInvitedUserRoomAccess?: bool, isHiddenInRoom?: bool, canManageRoomOwners?: bool, canDeleteRooms?: bool, canConnectToMortgageCadence?: bool, autoAccessToRoomsInOfficeOnly?: bool, canViewRoomDetails?: bool, canViewAndEditRoomDetails?: bool, canSendRoomDetailsToLoneWolf?: bool, canAddDocuments?: bool, canAddDocumentsFromFormGroups?: bool, canAddDocumentsFromFormLibraries?: bool, documentsViewableByOthersInRoomFromOffice?: bool, documentsAutoOwnedByPeers?: bool, canDeleteOwnedDocuments?: bool, canDeleteSignedDocuments?: bool, canDeleteUnsignedDocuments?: bool, canManageSharedDocs?: bool, canManageFormGroups?: bool, canShareDocsNotOwned?: bool, canCreateFormTemplates?: bool, canManageFormPackets?: bool, canAddTasksToAnyTaskLists?: bool, canEditEditableTasks?: bool, canEditAnyTasks?: bool, canDeleteDeletableTasks?: bool, canDeleteAnyTasks?: bool, canApplyTaskList?: bool, canRemoveAnyTaskList?: bool, canSubmitTaskList?: bool, canAutoSubmitTaskList?: bool, canReviewTaskList?: bool, canAutoApproveTaskList?: bool, canManageTaskTemplatesForAllRegionsAllOffices?: bool, canApplyRoomTemplates?: bool, canAddTasksToRooms?: bool, canReviewAnyTask?: bool, canManageDocsOnAnyTask?: bool, canAddMemberAndSetRoleLowerAccessLevel?: bool, canAddMemberAndSetRoleSameAccessLevel?: bool, canChangeMemberRoleLowerAccessLevel?: bool, canChangeMemberRoleSameAccessLevel?: bool, canManageMemberLowerAccessLevel?: bool, canManageMemberSameAccessLevel?: bool, canRemoveCompanyMemberLowerAccessLevel?: bool, canRemoveCompanyMemberSameAccessLevel?: bool, canManageAccount?: bool, canManageLogo?: bool, canManageRolesAndPermissions?: bool, canManageRoomDetails?: bool, canManageRoomTemplates?: bool, canManageIntegrationSettings?: bool, canExportCompanyUsageReport?: bool}
]: any -> record<roleId: int, legacyRoleId: string, name: string, isDefaultForAdmin: bool, isExternal: bool, createdDate: string, isAssigned: bool, permissions: record<canAddUsersToRooms: bool, canCreateRooms: bool, canSubmitRoomsForReview: bool, canCloseRooms: bool, canReopenRooms: bool, canDeleteOwnedRooms: bool, autoAccessToRooms: bool, canExportRoomActivityDetailsPeople: bool, canCopyRoomDetails: bool, canEditAnyRoomRole: bool, canEditInvitedRoomRole: bool, canEditRoomSide: bool, canManageAnyUserRoomAccess: bool, canManageInvitedUserRoomAccess: bool, isHiddenInRoom: bool, canManageRoomOwners: bool, canDeleteRooms: bool, canConnectToMortgageCadence: bool, autoAccessToRoomsInOfficeOnly: bool, canViewRoomDetails: bool, canViewAndEditRoomDetails: bool, canSendRoomDetailsToLoneWolf: bool, canAddDocuments: bool, canAddDocumentsFromFormGroups: bool, canAddDocumentsFromFormLibraries: bool, documentsViewableByOthersInRoomFromOffice: bool, documentsAutoOwnedByPeers: bool, canDeleteOwnedDocuments: bool, canDeleteSignedDocuments: bool, canDeleteUnsignedDocuments: bool, canManageSharedDocs: bool, canManageFormGroups: bool, canShareDocsNotOwned: bool, canCreateFormTemplates: bool, canManageFormPackets: bool, canAddTasksToAnyTaskLists: bool, canEditEditableTasks: bool, canEditAnyTasks: bool, canDeleteDeletableTasks: bool, canDeleteAnyTasks: bool, canApplyTaskList: bool, canRemoveAnyTaskList: bool, canSubmitTaskList: bool, canAutoSubmitTaskList: bool, canReviewTaskList: bool, canAutoApproveTaskList: bool, canManageTaskTemplatesForAllRegionsAllOffices: bool, canApplyRoomTemplates: bool, canAddTasksToRooms: bool, canReviewAnyTask: bool, canManageDocsOnAnyTask: bool, canAddMemberAndSetRoleLowerAccessLevel: bool, canAddMemberAndSetRoleSameAccessLevel: bool, canChangeMemberRoleLowerAccessLevel: bool, canChangeMemberRoleSameAccessLevel: bool, canManageMemberLowerAccessLevel: bool, canManageMemberSameAccessLevel: bool, canRemoveCompanyMemberLowerAccessLevel: bool, canRemoveCompanyMemberSameAccessLevel: bool, canManageAccount: bool, canManageLogo: bool, canManageRolesAndPermissions: bool, canManageRoomDetails: bool, canManageRoomTemplates: bool, canManageIntegrationSettings: bool, canExportCompanyUsageReport: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/roles/($roleId)")
  let body = {name: $name, isExternal: $isExternal, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a role.
#
# DELETE /v2/accounts/{accountId}/roles/{roleId}
# operationId: Roles_DeleteRole
export def "accounts-roles DeleteRole" [
  roleId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/roles/($roleId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an envelope with the given documents. Returns the eSignature envelope ID of the envelope that was created.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/envelopes
# operationId: RoomEnvelopes_CreateRoomEnvelope
export def "accounts-rooms-envelopes CreateRoomEnvelope" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --envelopeName: string
  --documentIds: list
]: any -> record<eSignEnvelopeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/envelopes")
  let body = {envelopeName: $envelopeName, documentIds: $documentIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a room's field data.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/field_data
# operationId: Rooms_GetRoomFieldData
export def "accounts-rooms-field-data GetRoomFieldData" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<data: record> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/field_data")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a room's field data.
#
# PUT /v2/accounts/{accountId}/rooms/{roomId}/field_data
# operationId: Rooms_UpdateRoomFieldData
export def "accounts-rooms-field-data UpdateRoomFieldData" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --data: record # Field data is a collection of name/value pairs where the names correspond to the fields in the room's **Details** tab. The value of a name/value pair can be a field data collection itself. These collections are implemented as JSON objects.  The fields `address1`, `state`, `postalCode`, and `city` are required. The `state` value must be a `stateId` value returned by the [getStates](/docs/rooms-api/reference/globalresources/states/getstates/) endpoint. For example, use "US-WA" instead of "Washington".  For example, the data for fields named "Tax annual amount" and "buyer1" (along with the required fields) might look like this:   ``` {   "data": {     "taxAnnualAmount": 3389.12,     "buyer1": {       "name": "Elle Woods",       "homePhone": "123-456-7890",       "state": "US-CA",       "email": "elle.woods@harvard.edu"     },     "address1": "123 Harvard Street",     "state": "US-MA",     "postalCode": "02138",     "city": "Cambridge"   } } ```
]: any -> record<data: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/field_data")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of room folders accessible to the current user.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/room_folders
# operationId: RoomFolders_GetRoomFolders
export def "accounts-rooms-room-folders GetRoomFolders" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --startPosition: int # The starting zero-based index position of the results set. When this property is used as a query parameter, the default value is `0`. (format: int32, default: 0)
  --count: int # The number of results. When this property is used as a request parameter specifying the number of results to return, the value must be a number between `1` and `100` (default). (format: int32, default: 100)
]: nothing -> record<folders: table<roomFolderId: int, name: string, isDefault: bool>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/room_folders" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a form to a room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/forms
# operationId: Rooms_AddFormToRoom
export def "accounts-rooms-forms AddFormToRoom" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  formId: string # (Required) The ID of the form. (format: uuid)
]: any -> record<documentId: int, name: string, ownerId: int, size: int, folderId: int, createdDate: string, isSigned: bool, docuSignFormId: string, isArchived: bool, isVirtual: bool, isDynamic: bool, owner: record<userId: int, firstName: string, lastName: string, companyName: string, imageSrc: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/forms")
  let body = {formId: $formId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invites a user to a room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/users
# operationId: Rooms_InviteUser
export def "accounts-rooms-users InviteUser" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  email: string # The user's email address.
  firstName: string # The user's first name.
  lastName: string # The user's last name.
  roleId: int # The ID of the company role assigned to the user.  You can assign external roles to users who aren't a part of your organization. (format: int32)
  --transactionSideId: string # Required for a real estate company; otherwise ignored.
]: any -> record<userId: int, roomId: int, email: string, firstName: string, lastName: string, transactionSideId: string, roleId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/users")
  let body = {email: $email, firstName: $firstName, lastName: $lastName, roleId: $roleId, transactionSideId: $transactionSideId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a room's users.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/users
# operationId: Rooms_GetRoomUsers
export def "accounts-rooms-users GetRoomUsers" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The index position within the total result set from which to start returning values. The default value is `0`. (format: int32, default: 0)
  --filter: string # A search filter that returns users by the beginning of the user's first name, last name, or email address. You can enter the beginning of the name or email only to return all of the users whose names or email addresses begin with the text that you entered.   **Note:** You do not enter a wildcard (*) at the end of the name or email fragment.
  --qp-sort: string # The order in which to return results. Valid values are:  - `firstNameAsc`: Sort on first name in ascending order.  - `firstNameDesc`:  Sort on first name in descending order.  - `lastNameAsc`: Sort on last name in ascending order.  - `lastNameDesc`: Sort on last name in descending order. This is the default value.
]: nothing -> record<users: table<userId: int, email: string, firstName: string, lastName: string, transactionSideId: string, roleId: int, titleId: int, companyName: string, roleName: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/users" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a room user.
#
# PUT /v2/accounts/{accountId}/rooms/{roomId}/users/{userId}
# operationId: Rooms_PutRoomUser
export def "accounts-rooms-users PutRoomUser" [
  roomId: int
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --roleId: int # The ID of the company role assigned to the user.  You can assign external roles to users who aren't a part of your organization. (format: int32)
  --transactionSideId: string # The ID of the transaction side. Valid values are:  - `buy` - `sell` - `listbuy` - `refi`
]: any -> record<userId: int, email: string, firstName: string, lastName: string, transactionSideId: string, roleId: int, isRevoked: bool, invitedByUserId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/users/($userId)")
  let body = {roleId: $roleId, transactionSideId: $transactionSideId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revokes the specified user's access to the room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/users/{userId}/revoke_access
# operationId: Rooms_RevokeRoomUserAccess
export def "accounts-rooms-users-revoke-access RevokeRoomUserAccess" [
  roomId: int
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --revocationDate: string # The date on which the users room access should be revoked in ISO 8601 fomat: `1973-12-31T07:54Z`. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/users/($userId)/revoke_access")
  let body = {revocationDate: $revocationDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Restores the specified user's access to the room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/users/{userId}/restore_access
# operationId: Rooms_RestoreRoomUserAccess
export def "accounts-rooms-users-restore-access RestoreRoomUserAccess" [
  roomId: int
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/users/($userId)/restore_access")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of rooms.
#
# GET /v2/accounts/{accountId}/rooms
# operationId: Rooms_GetRooms
export def "accounts-rooms GetRooms" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results. When this property is used as a request parameter specifying the number of results to return, the value must be a number between 1 and 100 (default). (format: int32, default: 100)
  --startPosition: int # The index position within the total result set from which to start returning values. The default value is `0`. (format: int32, default: 0)
  --roomStatus: string # The status of the room. Valid values are:  - `active`: This is the default value. - `pending` - `open`: Includes both `active` and `pending` statuses. - `closed`  To return rooms with multiple statuses, enter a comma-separated list of statuses.   Example:  `closed,open`
  --officeId: int # The ID of the office. (format: int32)
  --fieldDataChangedStartDate: string # Starting date and time to filter rooms whose field data has changed after this date. Date and time is always given as UTC. If the time (`hh:mm:ss`) is omitted, it defaults to `00:00:00`.  Valid formats:  - `yyyy-mm-dd hh:mm:ss` - `yyyy/mm/dd hh:mm:ss`  The default start date is the beginning of time.
  --fieldDataChangedEndDate: string # Ending date and time to filter rooms whose field data has changed before this date. Date and time is always given as UTC. If the time (`hh:mm:ss`) is omitted, it defaults to `00:00:00`.   Valid formats:  - `yyyy-mm-dd hh:mm:ss` - `yyyy/mm/dd hh:mm:ss`  If this query parameter is omitted, the default end date is now.
  --roomClosedStartDate: string # Starting date and time to filter rooms that were closed this date. Date and time is always given as UTC. If the time (`hh:mm:ss`) is omitted, it defaults to `00:00:00`.  Valid formats:  - `yyyy-mm-dd hh:mm:ss` - `yyyy/mm/dd hh:mm:ss`  The default start date is the beginning of time.
  --roomClosedEndDate: string # Ending date and time to filter rooms that were closed before this date. Date and time is always given as UTC. If the time (`hh:mm:ss`) is omitted, it defaults to `00:00:00`.  Valid formats:  - `yyyy-mm-dd hh:mm:ss` - `yyyy/mm/dd hh:mm:ss`  If this query parameter is omitted, the default end date is now.
]: nothing -> record<rooms: table<roomId: int, name: string, officeId: int, createdDate: string, submittedForReviewDate: string, closedDate: string, rejectedDate: string, createdByUserId: int, rejectedByUserId: int, closedStatusId: string, fieldDataLastUpdatedDate: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "roomStatus" $roomStatus "scalar") (serialize-qp "officeId" $officeId "scalar") (serialize-qp "fieldDataChangedStartDate" $fieldDataChangedStartDate "scalar") (serialize-qp "fieldDataChangedEndDate" $fieldDataChangedEndDate "scalar") (serialize-qp "roomClosedStartDate" $roomClosedStartDate "scalar") (serialize-qp "roomClosedEndDate" $roomClosedEndDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a room.
#
# POST /v2/accounts/{accountId}/rooms
# operationId: Rooms_CreateRoom
# --fieldData shape: {data?: record}
export def "accounts-rooms CreateRoom" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  name: string # (Required) The name of the room.
  roleId: int # (Required) The ID of the role that the owner has in the room. (format: int32)
  --transactionSideId: string # The ID of the transaction side. Valid values are:  - `buy` - `sell` - `listbuy` - `refi`  **Note:** This property is required for real estate companies, and otherwise ignored.
  --ownerId: int # The ID of the user who owns the room. (format: int32)
  --templateId: int # (Optional) The ID of the template to use to create the room. (format: int32)
  --officeId: int # (Optional) The ID of the office associated with the room. Required when creating a room on behalf of someone else or a Manager-owned room.  (format: int32)
  --fieldData: record # Contains key-value pairs that specify the properties of the room and their values. — shape: {data?: record}
  --listingSource: string@listingSource-completer
]: any -> record<roomId: int, companyId: int, name: string, officeId: int, createdDate: string, submittedForReviewDate: string, closedDate: string, rejectedDate: string, createdByUserId: int, roomOwnerIds: list<int>, rejectedByUserId: int, closedStatusId: string, fieldDataLastUpdatedDate: string, fieldData: record<data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms")
  let body = {name: $name, roleId: $roleId, transactionSideId: $transactionSideId, ownerId: $ownerId, templateId: $templateId, officeId: $officeId, fieldData: $fieldData, listingSource: $listingSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a room.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}
# operationId: Rooms_GetRoom
export def "accounts-rooms GetRoom" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --includeFieldData: string@bool-completer # When **true,** the response includes the field data from the room. This is the information that appears on the room's **Details** tab. (default: false)
]: nothing -> record<roomId: int, companyId: int, name: string, officeId: int, createdDate: string, submittedForReviewDate: string, closedDate: string, rejectedDate: string, createdByUserId: int, roomOwnerIds: list<int>, rejectedByUserId: int, closedStatusId: string, fieldDataLastUpdatedDate: string, fieldData: record<data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeFieldData" $includeFieldData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a room.
#
# DELETE /v2/accounts/{accountId}/rooms/{roomId}
# operationId: Rooms_DeleteRoom
export def "accounts-rooms DeleteRoom" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets assignable room-level roles in v6.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/assignable_roles
# operationId: Rooms_GetAssignableRoles
export def "accounts-rooms-assignable-roles GetAssignableRoles" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --assigneeEmail: string # The email address of a specific member. Using this parameter returns only the roles that the current user can assign to the member with that email address.
  --filter: string # A search filter that returns assignable roles by the beginning of the role name.  **Note:** You do not enter a wildcard (*) at the end of the name fragment.
  --startPosition: int # The index position within the total result set from which to start returning values. The default value is `0`. (format: int32, default: 0)
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
]: nothing -> record<currentRoleId: int, roles: table<roleId: int, legacyRoleId: string, name: string, isDefaultForAdmin: bool, isExternal: bool, createdDate: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assigneeEmail" $assigneeEmail "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/assignable_roles" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a document to a room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/documents
# operationId: Rooms_AddDocumentToRoom
export def "accounts-rooms-documents AddDocumentToRoom" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --documentId: int # The ID of the document. (format: int32)
  name: string # The file name associated with the document.
  --body-roomId: int # The ID of the room associated with the document. (format: int32)
  --ownerId: int # The ID of the user who owns the document. (format: int32)
  --size: int # The size of the document in bytes. (format: int64)
  --folderId: int # The ID of the folder that holds the document. (format: int32)
  --createdDate: string # The date and time when the document was created. This is a read-only value that the service assigns.  Example: `2019-11-11T17:15:14.82` (format: date-time)
  --isSigned: string@bool-completer # When **true,** indicates that the document is signed.
  --contentType: string
  base64Contents: string # The base64-encoded contents of the document. This property is only included in the response when you use the `includeContents` query parameter and set it to **true.**
  --isDynamic: string@bool-completer
]: any -> record<documentId: int, name: string, ownerId: int, size: int, folderId: int, createdDate: string, isSigned: bool, docuSignFormId: string, isArchived: bool, isVirtual: bool, isDynamic: bool, owner: record<userId: int, firstName: string, lastName: string, companyName: string, imageSrc: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/documents")
  let body = {documentId: $documentId, name: $name, roomId: $body_roomId, ownerId: $ownerId, size: $size, folderId: $folderId, createdDate: $createdDate, isSigned: $isSigned, contentType: $contentType, base64Contents: $base64Contents, isDynamic: $isDynamic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a list of documents in a room.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/documents
# operationId: Rooms_GetDocuments
export def "accounts-rooms-documents GetDocuments" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The index position within the total result set from which to start returning values. The default value is `0`. (format: int32, default: 0)
  --requireContentForDynamicDocuments: string@bool-completer # When **true,** dynamic documents without content will not be returned. The default value is **false.** (default: false)
  --roomFolderId: int # Filters results by `folderId`. If this property is not set, no filtering is applied. (format: int32)
  --nameFilter: string # Filters results by `name`. If this property is not set, no filtering is applied.
  --includeArchived: string@bool-completer # Filters results by `isArchived`. For example, when **true,** only documents with the property `isArchived=true` will be returned. If this property is not set, no filtering is applied. (default: true)
]: nothing -> record<resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int, documents: table<documentId: int, name: string, ownerId: int, size: int, folderId: int, createdDate: string, isSigned: bool, docuSignFormId: string, isArchived: bool, isVirtual: bool, isDynamic: bool, owner: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "requireContentForDynamicDocuments" $requireContentForDynamicDocuments "scalar") (serialize-qp "roomFolderId" $roomFolderId "scalar") (serialize-qp "nameFilter" $nameFilter "scalar") (serialize-qp "includeArchived" $includeArchived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/documents" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Uploads the contents of a file as a document to a room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/documents/contents
# operationId: Rooms_AddDocumentToRoomViaFileUpload
export def "accounts-rooms-documents-contents AddDocumentToRoomViaFileUpload" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --file: path # File to be uploaded
]: any -> record<documentId: int, name: string, ownerId: int, size: int, folderId: int, createdDate: string, isSigned: bool, docuSignFormId: string, isArchived: bool, isVirtual: bool, isDynamic: bool, owner: record<userId: int, firstName: string, lastName: string, companyName: string, imageSrc: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/documents/contents")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Updates the picture for a room.
#
# PUT /v2/accounts/{accountId}/rooms/{roomId}/picture
# operationId: Rooms_UpdatePicture
export def "accounts-rooms-picture UpdatePicture" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --file: path # File to be uploaded
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/picture")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Gets the field set for a room.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/field_set
# operationId: Rooms_GetRoomFieldSet
export def "accounts-rooms-field-set GetRoomFieldSet" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<fieldSetId: string, title: string, fields: table<fieldId: string, fieldDefinitionId: string, title: string, apiName: string, type: string, fields: list, configuration: record, customData: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/field_set")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets task lists for a room.
#
# GET /v2/accounts/{accountId}/rooms/{roomId}/task_lists
# operationId: TaskLists_GetTaskLists
export def "accounts-rooms-task-lists GetTaskLists" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<taskListSummaries: table<taskListId: int, name: string, taskListTemplateId: int, submittedForReviewDate: string, approvalDate: string, rejectedDate: string, createdDate: string, approvedByUserId: int, rejectedByUserId: int, comment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/task_lists")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Applies a task list to a room.
#
# POST /v2/accounts/{accountId}/rooms/{roomId}/task_lists
# operationId: TaskLists_CreateTaskList
export def "accounts-rooms-task-lists CreateTaskList" [
  roomId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --taskListTemplateId: int # (Required) The ID of the task list template. (format: int32)
]: any -> record<taskListId: int, name: string, taskListTemplateId: int, submittedForReviewDate: string, approvalDate: string, rejectedDate: string, createdDate: string, approvedByUserId: int, rejectedByUserId: int, comment: string, tasks: table<taskId: int, name: string, requiresApproval: bool, dueDateTypeId: string, dueDateOffset: int, fixedDueDate: string, ownerUserId: int, completionDate: string, approvalDate: string, rejectedDate: string, createdDate: string, isDocumentTask: bool, requiresReview: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/rooms/($roomId)/task_lists")
  let body = {taskListTemplateId: $taskListTemplateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets room templates.
#
# GET /v2/accounts/{accountId}/room_templates
# operationId: RoomTemplates_GetRoomTemplates
export def "accounts-room-templates GetRoomTemplates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --officeId: int # The ID of the office for which the user wants to create a room. When you pass in a value for this parameter, only room templates that are valid for that office appear in the results. For users who are not Admins, the default is the ID of the user's default office. However, you can specify a value if the user belongs to multiple offices.  If the user is an Admin, set the `forAdmin` search parameter to **true** instead and omit the `officeId` parameter.  (format: int32)
  --onlyAssignable: string@bool-completer # When **true,** returns only the roles that the current user can assign to someone else. The default value is **false.** (default: false)
  --onlyEnabled: string@bool-completer # When true, only returns room templates that are not disabled. (default: true)
  --count: int # The number of results. When this property is used as a request parameter specifying the number of results to return, the value must be a number between `1` and `100` (default). (format: int32, default: 100)
  --startPosition: int # The index position within the total result set from which to start returning values. The default value is `0`. (format: int32, default: 0)
]: nothing -> record<roomTemplates: table<roomTemplateId: int, name: string, taskTemplateCount: int>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "officeId" $officeId "scalar") (serialize-qp "onlyAssignable" $onlyAssignable "scalar") (serialize-qp "onlyEnabled" $onlyEnabled "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "startPosition" $startPosition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/room_templates" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a task list from a room.
#
# DELETE /v2/accounts/{accountId}/task_lists/{taskListId}
# operationId: TaskLists_DeleteTaskList
export def "accounts-task-lists DeleteTaskList" [
  taskListId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/task_lists/($taskListId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets task list templates.
#
# GET /v2/accounts/{accountId}/task_list_templates
# operationId: TaskListTemplates_GetTaskListTemplates
export def "accounts-task-list-templates GetTaskListTemplates" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --startPosition: int # The starting zero-based index position from which to start returning values. The default is `0`. (format: int32, default: 0)
  --count: int # The number of results to return. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
]: nothing -> record<taskListTemplates: table<taskListTemplateId: int, name: string, taskCount: int, tasksWithDocumentsCount: int>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/task_list_templates" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of users.
#
# GET /v2/accounts/{accountId}/users
# operationId: Users_GetUsers
export def "accounts-users GetUsers" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filter: string # Filters results by name and email address. This is a  "starts with" filter, which means that you can enter only the beginning of a name or email address.   **Note:** You do not use a wildcard with this filter.
  --qp-sort: string # Specifies how to sort the results. Valid values are:  - `FirstNameAsc` - `LastNameAsc` - `EmailAsc` - `FirstNameDesc` - `LastNameDesc` - `EmailDesc`
  --defaultOfficeId: int # Filters for users who have this office ID as their default office ID. (format: int32)
  --accessLevel: string # Filters for users who have the specified access level. A user's access level and role determine the types of resources and actions that are available to them.  Valid values are: - Company: Users with this access level can administer resources across the company. - Region: Users with this access level can administer offices and other resources within their regions.  - Office: Users with this access level can administer resources within their offices. - Contributor: Users with this access level can only administer their own resources.  **Note:** In requests, the values that you may use for this property depend on your permissions and whether you can add users at your access level or lower.
  --titleId: int # This field is deprecated in Rooms Version 6. (format: int32)
  --roleId: int # Filters for users who have the specified `roleId`. (format: int32)
  --status: string # Filters for users who have the specified `status`.  Valid values are:  - `Active`: The user is active. - `Pending`: The user has been invited but has not yet accepted the invitation.
  --lockedOnly: string@bool-completer # When **true,** filters for users whose accounts are locked.
  --startPosition: int # The starting zero-based index position within the result set from which to begin the response. The default is `0`.  (format: int32, default: 0)
  --count: int # The maximum number of users to return in the response. This value must be a number between `1` and `100` (default). (format: int32, default: 100)
]: nothing -> record<userSummaries: table<userId: int, email: string, firstName: string, lastName: string, isLockedOut: bool, status: string, accessLevel: string, defaultOfficeId: int, titleId: int, roleId: int, profileImageUrl: string>, resultSetSize: int, startPosition: int, endPosition: int, nextUri: string, priorUri: string, totalRowCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "defaultOfficeId" $defaultOfficeId "scalar") (serialize-qp "accessLevel" $accessLevel "scalar") (serialize-qp "titleId" $titleId "scalar") (serialize-qp "roleId" $roleId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "lockedOnly" $lockedOnly "scalar") (serialize-qp "startPosition" $startPosition "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a user.
#
# GET /v2/accounts/{accountId}/users/{userId}
# operationId: Users_GetUser
export def "accounts-users GetUser" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<userId: int, email: string, firstName: string, lastName: string, isLockedOut: bool, status: string, accessLevel: string, defaultOfficeId: int, titleId: int, roleId: int, profileImageUrl: string, offices: list<int>, regions: list<int>, permissions: record<isVisibleInTransactionRooms: bool, canDeleteCompanyRooms: bool, canDeleteCompanyDocuments: bool, canManageCompanyRooms: bool, canManageCompanyAccount: bool, canManageCompanySharedLibrary: bool, canManageCompanyMembers: bool, canCloseCompanyRooms: bool, canApproveCompanyChecklists: bool, isCompanySystemAdmin: bool, isRegionManager: bool, isOfficeManager: bool, autoAccessToCompanyRooms: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a user's default office.
#
# PUT /v2/accounts/{accountId}/users/{userId}
# operationId: Users_UpdateUser
export def "accounts-users UpdateUser" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  defaultOfficeId: int # (Required) The ID of the user's default office. (format: int32)
]: any -> record<userId: int, email: string, firstName: string, lastName: string, isLockedOut: bool, status: string, accessLevel: string, defaultOfficeId: int, titleId: int, roleId: int, profileImageUrl: string, offices: list<int>, regions: list<int>, permissions: record<isVisibleInTransactionRooms: bool, canDeleteCompanyRooms: bool, canDeleteCompanyDocuments: bool, canManageCompanyRooms: bool, canManageCompanyAccount: bool, canManageCompanySharedLibrary: bool, canManageCompanyMembers: bool, canCloseCompanyRooms: bool, canApproveCompanyChecklists: bool, isCompanySystemAdmin: bool, isRegionManager: bool, isOfficeManager: bool, autoAccessToCompanyRooms: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)")
  let body = {defaultOfficeId: $defaultOfficeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a user from a company account.
#
# DELETE /v2/accounts/{accountId}/users/{userId}
# operationId: Users_RemoveUser
export def "accounts-users RemoveUser" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invites a user to a company account.
#
# POST /v2/accounts/{accountId}/users/invite_user
# operationId: Users_InviteUser
export def "accounts-users-invite-user InviteUser" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  firstName: string # (Required) The user's first name.
  lastName: string # (Required) The user's last name.
  email: string # (Required) The user's email address.
  roleId: int # (Required) The ID of the company role assigned to the user.  You can assign external roles to users who are not part of your organization.  (format: int32)
  accessLevel: string@accessLevel-completer # (Required) The user's level of access to the account. This property determines what the user can see in the system.  In contrast, a user's permissions determine the actions that they can take in a room. For example, a user who has `accessLevel` set to `Company` can see all of the rooms associated with their company. However, if they do not have a role for which the **Add documents to room** permission is set to **true,** they can't add documents to those rooms.  Valid values are:  - `Company`: The user has access to rooms, and if they have permission to manage users, they have access to users across the entire company. What they can do in the rooms and with users is controlled by their permissions. - `Region`: The user has access to rooms and, and if they have permission to manage users, they have access to users across their regions. - `Office`: The user has access to rooms, and if they have permission to manage users, they have access to users across their regions. - `Contributor`: The user has access only to their own rooms and those to which they are invited. They cannot perform any user management actions because they do not oversee other users. For example, agents typically have the `Contributor` access level.  **Note:** In requests, the values that you may use for this property depend on your permissions and whether you can add users at your access level or lower.
  defaultOfficeId: int # (Required) The ID of the user's default office. (format: int32)
  --regions: list # An array of region IDs for the regions in which a user with the `Region accessLevel` has been granted the ability to participate. If the value for `accessLevel` is `Region`, this property is required.
  --offices: list # An array of office IDs for the offices in which a user with an `Office` or `Contributor` `accessLevel` has been granted the ability to participate. If the value for `accessLevel` is `Office`, this property is required.
  --subscribeToRoomsActivityNotifications: string@bool-completer # default: true
  eSignPermissionProfileId: string # (Required) When an administrator or authorized member invites a new user to become an account member, the system also creates an eSignature account for the invitee at the same time. The eSignPermissionProfileId is the ID of the eSignature permission set to assign to the member.
  --redirectUrl: string # URL to redirect to after inviting. (format: uri)
]: any -> record<userId: int, email: string, firstName: string, lastName: string, isLockedOut: bool, status: string, accessLevel: string, defaultOfficeId: int, titleId: int, roleId: int, profileImageUrl: string, offices: list<int>, regions: list<int>, permissions: record<isVisibleInTransactionRooms: bool, canDeleteCompanyRooms: bool, canDeleteCompanyDocuments: bool, canManageCompanyRooms: bool, canManageCompanyAccount: bool, canManageCompanySharedLibrary: bool, canManageCompanyMembers: bool, canCloseCompanyRooms: bool, canApproveCompanyChecklists: bool, isCompanySystemAdmin: bool, isRegionManager: bool, isOfficeManager: bool, autoAccessToCompanyRooms: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/invite_user")
  let body = {firstName: $firstName, lastName: $lastName, email: $email, roleId: $roleId, accessLevel: $accessLevel, defaultOfficeId: $defaultOfficeId, regions: $regions, offices: $offices, subscribeToRoomsActivityNotifications: $subscribeToRoomsActivityNotifications, eSignPermissionProfileId: $eSignPermissionProfileId, redirectUrl: $redirectUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reinvites a user to join a company account.
#
# POST /v2/accounts/{accountId}/users/{userId}/reinvite
# operationId: Users_ReinviteUser
export def "accounts-users-reinvite ReinviteUser" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/reinvite")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a user to an office.
#
# POST /v2/accounts/{accountId}/users/{userId}/add_to_office
# operationId: Users_AddUserToOffice
export def "accounts-users-add-to-office AddUserToOffice" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  officeId: int # (Required) The ID of the office. This is the ID that the system generated when you created the office. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/add_to_office")
  let body = {officeId: $officeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a user from an office.
#
# POST /v2/accounts/{accountId}/users/{userId}/remove_from_office
# operationId: Users_RemoveUserFromOffice
export def "accounts-users-remove-from-office RemoveUserFromOffice" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  officeId: int # (Required) The ID of the office. This is the ID that the system generated when you created the office. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/remove_from_office")
  let body = {officeId: $officeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Adds a user to a region.
#
# POST /v2/accounts/{accountId}/users/{userId}/add_to_region
# operationId: Users_AddUserToRegion
export def "accounts-users-add-to-region AddUserToRegion" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  regionId: int # (Required) The ID of the region. This is the ID that the system generated when you created the region. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/add_to_region")
  let body = {regionId: $regionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes a user from a region.
#
# POST /v2/accounts/{accountId}/users/{userId}/remove_from_region
# operationId: Users_RemoveUserFromRegion
export def "accounts-users-remove-from-region RemoveUserFromRegion" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  regionId: int # (Required) The ID of the region. This is the ID that the system generated when you created the region. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/remove_from_region")
  let body = {regionId: $regionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Locks a user's account.
#
# POST /v2/accounts/{accountId}/users/{userId}/lock
# operationId: Users_LockUser
export def "accounts-users-lock LockUser" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  reason: string # The reason the account was locked.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/lock")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlocks  a user's account.
#
# POST /v2/accounts/{accountId}/users/{userId}/unlock
# operationId: Users_UnlockUser
export def "accounts-users-unlock UnlockUser" [
  userId: int
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/accounts/($accountId)/users/($userId)/unlock")
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
