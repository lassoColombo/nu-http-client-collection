# Auto-generated client for DocuSign Click API vv1
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/click.rest.swagger-v2.json
# Auth: --token flag or $env.DOCUSIGN_CLICK_API_TOKEN

const BASE_URL = "https://www.demo.docusign.net/clickapi"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DOCUSIGN_CLICK_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://www.demo.docusign.net/clickapi"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "service-information GetServiceInformation" } } | get name | first)
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

# Gets the current version and other information about the Click API.
#
# GET /service_information
# operationId: ServiceInformation_GetServiceInformation
export def "service-information GetServiceInformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<buildBranch: string, buildBranchDeployedDateTime: string, buildSHA: string, buildVersion: string, linkedSites: list<string>, serviceVersions: table<version: string, versionUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/service_information")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all the clickwraps for an account.
#
# GET /v1/accounts/{accountId}/clickwraps
# operationId: Clickwraps_GetClickwraps
export def "accounts-clickwraps GetClickwraps" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --from-date: string # Optional. The earliest date to return agreements from.
  --ownerUserId: string # Optional. The user ID of the owner.
  --page-number: string # Optional. The page number to return.
  --shared: string
  --status: string # Optional. The status of the clickwraps to filter by. One of:  - `active` - `inactive` 
  --to-date: string # Optional. The latest date to return agreements from.
]: nothing -> record<clickwraps: table<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record, status: string, versionId: string, versionNumber: string>, minimumPagesRemaining: int, page: int, pageSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_date" $from_date "scalar") (serialize-qp "ownerUserId" $ownerUserId "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "shared" $shared "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "to_date" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a clickwrap for an account.
#
# POST /v1/accounts/{accountId}/clickwraps
# operationId: Clickwraps_PostClickwrap
# --displaySettings shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
# --documents item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
# --scheduledReacceptance shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
export def "accounts-clickwraps PostClickwrap" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickwrapName: string # The name of the clickwrap.
  --displaySettings: record # Information about how an agreement is displayed. — shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
  --documents: list # An array of documents. — item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
  --fieldsToNull: string # Specifies whether `scheduledReacceptance` and `scheduledDate` should be cleared. May be one of:  - `"scheduledReacceptance"` - `"scheduledDate"` - `"scheduledReacceptance,scheduledDate"`
  --isMajorVersion: string@bool-completer # When **true**, the next version created is a major version. When **false** the next version created is minor.
  --isShared: string@bool-completer
  --name: string # Name of the clickwrap.
  --requireReacceptance: string@bool-completer # When **true**, requires signers who have previously agreed to this clickwrap to sign again. The version number is incremented.
  --scheduledDate: record # The time and date when this clickwrap is activated.
  --scheduledReacceptance: record # shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
  --status: record # Clickwrap status. Possible values:  - `active` - `inactive` - `deleted`
  --transferFromUserId: string # The user ID of current owner of the clickwrap.
  --transferToUserId: string # The user ID of the new owner of the clickwrap.
]: any -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps")
  let body = {clickwrapName: $clickwrapName, displaySettings: $displaySettings, documents: $documents, fieldsToNull: $fieldsToNull, isMajorVersion: $isMajorVersion, isShared: $isShared, name: $name, requireReacceptance: $requireReacceptance, scheduledDate: $scheduledDate, scheduledReacceptance: $scheduledReacceptance, status: $status, transferFromUserId: $transferFromUserId, transferToUserId: $transferToUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes clickwraps for an account.
#
# DELETE /v1/accounts/{accountId}/clickwraps
# operationId: Clickwraps_DeleteClickwraps
export def "accounts-clickwraps DeleteClickwraps" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickwrapIds: string # A comma-separated list of clickwrap IDs to delete.
]: nothing -> record<clickwraps: table<clickwrapId: string, clickwrapName: string, deletionMessage: string, deletionSuccess: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clickwrapIds" $clickwrapIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a  single clickwrap object.
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}
# operationId: Clickwraps_GetClickwrap
export def "accounts-clickwraps GetClickwrap" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, displaySettings: record<actionButtonAlignment: string, allowClientOnly: bool, allowedHosts: list<string>, brandId: string, consentButtonText: string, consentText: string, declineButtonText: string, displayName: string, documentDisplay: string, downloadable: bool, format: string, hasDeclineButton: bool, hostOrigin: string, mustRead: bool, mustView: bool, recordDeclineResponses: bool, requireAccept: bool, sendToEmail: bool>, documents: table<documentBase64: string, documentHtml: string, documentName: string, fileExtension: string, order: int>, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the user ID of a clickwrap.
#
# PUT /v1/accounts/{accountId}/clickwraps/{clickwrapId}
# operationId: Clickwraps_PutClickwrap
export def "accounts-clickwraps PutClickwrap" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transferFromUserId: string # ID of the user to transfer from.
  --transferToUserId: string # ID of the user to transfer to.
]: any -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)")
  let body = {transferFromUserId: $transferFromUserId, transferToUserId: $transferToUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a clickwrap and all of its versions.
#
# DELETE /v1/accounts/{accountId}/clickwraps/{clickwrapId}
# operationId: Clickwraps_DeleteClickwrap
export def "accounts-clickwraps DeleteClickwrap" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versions: string # A comma-separated list of versions to delete.
]: nothing -> record<clickwrapId: string, clickwrapName: string, versions: table<clickwrapVersionId: string, createdTime: record, deletionMessage: string, deletionSuccess: bool, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record, status: string, versionId: string, versionNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versions" $versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checks if a user has agreed to a clickwrap.
#
# POST /v1/accounts/{accountId}/clickwraps/{clickwrapId}/agreements
# operationId: UserAgreements_PostHasAgreed
export def "accounts-clickwraps-agreements PostHasAgreed" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientUserId: string # The user ID of the client.
  --hostOrigin: string # The host origin.
  --metadata: string # A customer-defined string you can use in requests. This string will appear in the corresponding response.
]: any -> record<accountId: string, agreedOn: record, agreementId: string, agreementUrl: string, clickwrapId: string, clientUserId: string, consumerDisclosureHtml: string, createdOn: record, declinedOn: record, documents: table<documentBase64: string, documentHtml: string, documentName: string, fileExtension: string, order: int>, metadata: string, settings: record<actionButtonAlignment: string, allowClientOnly: bool, allowedHosts: list<string>, brandId: string, consentButtonText: string, consentText: string, declineButtonText: string, displayName: string, documentDisplay: string, downloadable: bool, format: string, hasDeclineButton: bool, hostOrigin: string, mustRead: bool, mustView: bool, recordDeclineResponses: bool, requireAccept: bool, sendToEmail: bool>, status: string, version: string, versionId: string, versionNumber: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/agreements")
  let body = {clientUserId: $clientUserId, hostOrigin: $hostOrigin, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets a specific agreement for a specified clickwrap.
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/agreements/{agreementId}
# operationId: UserAgreements_GetAgreement
export def "accounts-clickwraps-agreements GetAgreement" [
  accountId: string
  agreementId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accountId: string, agreedOn: record, agreementId: string, agreementUrl: string, clickwrapId: string, clientUserId: string, consumerDisclosureHtml: string, createdOn: record, declinedOn: record, documents: table<documentBase64: string, documentHtml: string, documentName: string, fileExtension: string, order: int>, metadata: string, settings: record<actionButtonAlignment: string, allowClientOnly: bool, allowedHosts: list<string>, brandId: string, consentButtonText: string, consentText: string, declineButtonText: string, displayName: string, documentDisplay: string, downloadable: bool, format: string, hasDeclineButton: bool, hostOrigin: string, mustRead: bool, mustView: bool, recordDeclineResponses: bool, requireAccept: bool, sendToEmail: bool>, status: string, version: string, versionId: string, versionNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/agreements/($agreementId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the completed user agreement PDF.
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/agreements/{agreementId}/download
# operationId: UserAgreements_GetAgreementPdf
export def "accounts-clickwraps-agreements-download GetAgreementPdf" [
  accountId: string
  agreementId: string
  clickwrapId: string
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
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/agreements/($agreementId)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user agreements
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/users
# operationId: UserAgreements_GetClickwrapAgreements
export def "accounts-clickwraps-users GetClickwrapAgreements" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-user-id: string # The client ID.
  --from-date: string # Optional. The earliest date to return agreements from.
  --page-number: string # Optional. The page number to return.
  --status: string # Optional. The status of the clickwraps to return.
  --to-date: string # Optional. The latest date to return agreements from.
]: nothing -> record<beginCreatedOn: record, minimumPagesRemaining: int, page: int, pageSize: int, userAgreements: table<accountId: string, agreedOn: record, agreementId: string, agreementUrl: string, clickwrapId: string, clientUserId: string, consumerDisclosureHtml: string, createdOn: record, declinedOn: record, documents: list, metadata: string, settings: record, status: string, version: string, versionId: string, versionNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_user_id" $client_user_id "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "to_date" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new clickwrap version.
#
# POST /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions
# operationId: ClickwrapVersions_PostClickwrapVersion
# --displaySettings shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
# --documents item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
# --scheduledReacceptance shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
export def "accounts-clickwraps-versions PostClickwrapVersion" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickwrapName: string # The name of the clickwrap.
  --displaySettings: record # Information about how an agreement is displayed. — shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
  --documents: list # An array of documents. — item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
  --fieldsToNull: string # Specifies whether `scheduledReacceptance` and `scheduledDate` should be cleared. May be one of:  - `"scheduledReacceptance"` - `"scheduledDate"` - `"scheduledReacceptance,scheduledDate"`
  --isMajorVersion: string@bool-completer # When **true**, the next version created is a major version. When **false** the next version created is minor.
  --isShared: string@bool-completer
  --name: string # Name of the clickwrap.
  --requireReacceptance: string@bool-completer # When **true**, requires signers who have previously agreed to this clickwrap to sign again. The version number is incremented.
  --scheduledDate: record # The time and date when this clickwrap is activated.
  --scheduledReacceptance: record # shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
  --status: record # Clickwrap status. Possible values:  - `active` - `inactive` - `deleted`
  --transferFromUserId: string # The user ID of current owner of the clickwrap.
  --transferToUserId: string # The user ID of the new owner of the clickwrap.
]: any -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions")
  let body = {clickwrapName: $clickwrapName, displaySettings: $displaySettings, documents: $documents, fieldsToNull: $fieldsToNull, isMajorVersion: $isMajorVersion, isShared: $isShared, name: $name, requireReacceptance: $requireReacceptance, scheduledDate: $scheduledDate, scheduledReacceptance: $scheduledReacceptance, status: $status, transferFromUserId: $transferFromUserId, transferToUserId: $transferToUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the versions of a clickwrap.
#
# DELETE /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions
# operationId: ClickwrapVersions_DeleteClickwrapVersions
export def "accounts-clickwraps-versions DeleteClickwrapVersions" [
  accountId: string
  clickwrapId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickwrapVersionIds: string # A comma-separated list of clickwrap version IDs to delete.
]: nothing -> record<clickwrapId: string, clickwrapName: string, versions: table<clickwrapVersionId: string, createdTime: record, deletionMessage: string, deletionSuccess: bool, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record, status: string, versionId: string, versionNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clickwrapVersionIds" $clickwrapVersionIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a specific version from a clickwrap.
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionId}
# operationId: ClickwrapVersions_GetClickwrapVersion
export def "accounts-clickwraps-versions GetClickwrapVersion" [
  accountId: string
  clickwrapId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, displaySettings: record<actionButtonAlignment: string, allowClientOnly: bool, allowedHosts: list<string>, brandId: string, consentButtonText: string, consentText: string, declineButtonText: string, displayName: string, documentDisplay: string, downloadable: bool, format: string, hasDeclineButton: bool, hostOrigin: string, mustRead: bool, mustView: bool, recordDeclineResponses: bool, requireAccept: bool, sendToEmail: bool>, documents: table<documentBase64: string, documentHtml: string, documentName: string, fileExtension: string, order: int>, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a specific version of a clickwrap.
#
# PUT /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionId}
# operationId: ClickwrapVersions_PutClickwrapVersion
# --displaySettings shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
# --documents item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
# --scheduledReacceptance shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
export def "accounts-clickwraps-versions PutClickwrapVersion" [
  accountId: string
  clickwrapId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickwrapName: string # The name of the clickwrap.
  --displaySettings: record # Information about how an agreement is displayed. — shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
  --documents: list # An array of documents. — item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
  --fieldsToNull: string # Specifies whether `scheduledReacceptance` and `scheduledDate` should be cleared. May be one of:  - `"scheduledReacceptance"` - `"scheduledDate"` - `"scheduledReacceptance,scheduledDate"`
  --isMajorVersion: string@bool-completer # When **true**, the next version created is a major version. When **false** the next version created is minor.
  --isShared: string@bool-completer
  --name: string # Name of the clickwrap.
  --requireReacceptance: string@bool-completer # When **true**, requires signers who have previously agreed to this clickwrap to sign again. The version number is incremented.
  --scheduledDate: record # The time and date when this clickwrap is activated.
  --scheduledReacceptance: record # shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
  --status: record # Clickwrap status. Possible values:  - `active` - `inactive` - `deleted`
  --transferFromUserId: string # The user ID of current owner of the clickwrap.
  --transferToUserId: string # The user ID of the new owner of the clickwrap.
]: any -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionId)")
  let body = {clickwrapName: $clickwrapName, displaySettings: $displaySettings, documents: $documents, fieldsToNull: $fieldsToNull, isMajorVersion: $isMajorVersion, isShared: $isShared, name: $name, requireReacceptance: $requireReacceptance, scheduledDate: $scheduledDate, scheduledReacceptance: $scheduledReacceptance, status: $status, transferFromUserId: $transferFromUserId, transferToUserId: $transferToUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a specific version of a clickwrap.
#
# DELETE /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionId}
# operationId: ClickwrapVersions_DeleteClickwrapVersion
export def "accounts-clickwraps-versions DeleteClickwrapVersion" [
  accountId: string
  clickwrapId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<clickwrapVersionId: string, createdTime: record, deletionMessage: string, deletionSuccess: bool, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the agreement responses for a clickwrap version.
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionId}/users
# operationId: UserAgreements_GetClickwrapVersionAgreements
export def "accounts-clickwraps-versions-users GetClickwrapVersionAgreements" [
  accountId: string
  clickwrapId: string
  versionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-user-id: string
  --from-date: string # Optional. The earliest date to return agreements from.
  --page-number: string # Optional. The page number to return.
  --status: string # Clickwrap status. Possible values:  - `active` - `inactive` - `deleted`
  --to-date: string # Optional. The latest date to return agreements from.
]: nothing -> record<beginCreatedOn: record, minimumPagesRemaining: int, page: int, pageSize: int, userAgreements: table<accountId: string, agreedOn: record, agreementId: string, agreementUrl: string, clickwrapId: string, clientUserId: string, consumerDisclosureHtml: string, createdOn: record, declinedOn: record, documents: list, metadata: string, settings: record, status: string, version: string, versionId: string, versionNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_user_id" $client_user_id "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "to_date" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionId)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a clickwrap version by specifying its version number.
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionNumber}
# operationId: ClickwrapVersions_GetClickwrapVersionByNumber
export def "accounts-clickwraps-versions GetClickwrapVersionByNumber" [
  accountId: string
  clickwrapId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, displaySettings: record<actionButtonAlignment: string, allowClientOnly: bool, allowedHosts: list<string>, brandId: string, consentButtonText: string, consentText: string, declineButtonText: string, displayName: string, documentDisplay: string, downloadable: bool, format: string, hasDeclineButton: bool, hostOrigin: string, mustRead: bool, mustView: bool, recordDeclineResponses: bool, requireAccept: bool, sendToEmail: bool>, documents: table<documentBase64: string, documentHtml: string, documentName: string, fileExtension: string, order: int>, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a clickwrap version by specifying its version number.
#
# PUT /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionNumber}
# operationId: ClickwrapVersions_PutClickwrapVersionByNumber
# --displaySettings shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
# --documents item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
# --scheduledReacceptance shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
export def "accounts-clickwraps-versions PutClickwrapVersionByNumber" [
  accountId: string
  clickwrapId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clickwrapName: string # The name of the clickwrap.
  --displaySettings: record # Information about how an agreement is displayed. — shape: {actionButtonAlignment?: string, allowClientOnly?: bool, allowedHosts?: list, brandId?: string, consentButtonText?: string, consentText?: string, declineButtonText?: string, displayName?: string, documentDisplay?: string, downloadable?: bool, format?: string, hasDeclineButton?: bool, hostOrigin?: string, mustRead?: bool, mustView?: bool, recordDeclineResponses?: bool, requireAccept?: bool, sendToEmail?: bool}
  --documents: list # An array of documents. — item shape: {documentBase64?: string, documentHtml?: string, documentName?: string, fileExtension?: string, order?: int}
  --fieldsToNull: string # Specifies whether `scheduledReacceptance` and `scheduledDate` should be cleared. May be one of:  - `"scheduledReacceptance"` - `"scheduledDate"` - `"scheduledReacceptance,scheduledDate"`
  --isMajorVersion: string@bool-completer # When **true**, the next version created is a major version. When **false** the next version created is minor.
  --isShared: string@bool-completer
  --name: string # Name of the clickwrap.
  --requireReacceptance: string@bool-completer # When **true**, requires signers who have previously agreed to this clickwrap to sign again. The version number is incremented.
  --scheduledDate: record # The time and date when this clickwrap is activated.
  --scheduledReacceptance: record # shape: {recurrenceInterval?: int, recurrenceIntervalType?: string, startDateTime?: record}
  --status: record # Clickwrap status. Possible values:  - `active` - `inactive` - `deleted`
  --transferFromUserId: string # The user ID of current owner of the clickwrap.
  --transferToUserId: string # The user ID of the new owner of the clickwrap.
]: any -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionNumber)")
  let body = {clickwrapName: $clickwrapName, displaySettings: $displaySettings, documents: $documents, fieldsToNull: $fieldsToNull, isMajorVersion: $isMajorVersion, isShared: $isShared, name: $name, requireReacceptance: $requireReacceptance, scheduledDate: $scheduledDate, scheduledReacceptance: $scheduledReacceptance, status: $status, transferFromUserId: $transferFromUserId, transferToUserId: $transferToUserId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a clickwrap version from a clickwrap by specifying its version number.
#
# DELETE /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionNumber}
# operationId: ClickwrapVersions_DeleteClickwrapVersionByNumber
export def "accounts-clickwraps-versions DeleteClickwrapVersionByNumber" [
  accountId: string
  clickwrapId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<accountId: string, clickwrapId: string, clickwrapName: string, clickwrapVersionId: string, createdTime: record, lastModified: record, lastModifiedBy: string, ownerUserId: string, requireReacceptance: bool, scheduledDate: record, scheduledReacceptance: record<recurrenceInterval: int, recurrenceIntervalType: string, startDateTime: record>, status: string, versionId: string, versionNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionNumber)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the agreement responses for a clickwrap version
#
# GET /v1/accounts/{accountId}/clickwraps/{clickwrapId}/versions/{versionNumber}/users
# operationId: UserAgreements_GetClickwrapVersionAgreementsByNumber
export def "accounts-clickwraps-versions-users GetClickwrapVersionAgreementsByNumber" [
  accountId: string
  clickwrapId: string
  versionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-user-id: string # The client user ID.
  --from-date: string # Optional. The earliest date to return agreements from.
  --page-number: string # Optional. The page number to return.
  --status: string # Clickwrap status. Possible values:  - `active` - `inactive` - `deleted`
  --to-date: string # Optional. The latest date to return agreements from.
]: nothing -> record<beginCreatedOn: record, minimumPagesRemaining: int, page: int, pageSize: int, userAgreements: table<accountId: string, agreedOn: record, agreementId: string, agreementUrl: string, clickwrapId: string, clientUserId: string, consumerDisclosureHtml: string, createdOn: record, declinedOn: record, documents: list, metadata: string, settings: record, status: string, version: string, versionId: string, versionNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_user_id" $client_user_id "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "page_number" $page_number "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "to_date" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/clickwraps/($clickwrapId)/versions/($versionNumber)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
