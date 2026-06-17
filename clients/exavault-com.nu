# Auto-generated client for ExaVault v2.0
# Source: https://api.apis.guru/v2/specs/exavault.com/2.0/openapi.json
# Auth: --token flag or $env.EXAVAULT_TOKEN

const BASE_URL = "https://accountname.exavault.com/api/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EXAVAULT_TOKEN | default "" }
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

def base-url-completer [] { ["https://accountname.exavault.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def include-completer [] { ["share"] }
def type-completer [] { ["file" "file_drop" "folder" "send_receipt" "share_receipt" "shared_folder"] }
def include-completer-1 [] { ["resource" "share" "user"] }
def action-completer [] { ["all" "connect" "delete" "download" "upload"] }
def action-completer-1 [] { ["all" "delete" "download" "upload"] }
def type-completer-1 [] { ["file" "folder"] }
def accept-completer [] { ["application/octet-stream" "application/zip"] }
def size-completer [] { ["large" "medium" "small"] }
def scope-completer [] { ["active" "all" "currentUser"] }
def sort-completer [] { ["-created" "created"] }
def type-completer-2 [] { ["receive" "send" "shared_folder"] }
def role-completer [] { ["admin" "user"] }
def response-version-completer [] { ["v1" "v2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Get account settings
#
# GET /account
# operationId: getAccount
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Related records to include in the response. Valid option is **masterUser** (e.g. masterUser)
  --ev-api-key: string # API Key required for the request (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token for the request (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: record<attributes: record<accountName: string, accountOnboarding: bool, allowedIp: list, branding: bool, brandingSettings: record, clientId: int, complexPasswords: bool, created: string, customDomain: bool, customSignature: string, externalDomains: list, maxUsers: int, modified: string, planDetails: record, quota: record, secureOnly: bool, showReferralLinks: bool, status: int, userCount: int, welcomeEmailContent: string, welcomeEmailSubject: string>, id: int, relationships: record<masterUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update account settings
#
# PATCH /account
# operationId: updateAccount
# --allowedIpRanges item shape: {ipEnd?: string, ipStart?: string}
# --brandingSettings shape: {companyName?: string, customEmail?: string, theme?: string}
# --quota shape: {noticeEnabled?: bool, noticeThreshold?: int, transactionsNoticeEnabled?: bool, transactionsNoticeThreshold?: int}
export def "account update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  --account-onboarding: oneof<nothing, bool> # Whether extra help popups can be enabled for users in the web file manager. (e.g. true)
  --allowed-ip-ranges: list # IP Address Ranges for restricting account access — item shape: {ipEnd?: string, ipStart?: string}
  --branding-settings: record # shape: {companyName?: string, customEmail?: string, theme?: string}
  --complex-passwords: oneof<nothing, bool> # Whether to require complex passwords for all passwords. (e.g. false)
  --custom-signature: string # Signature to be automatically added to the bottom of emails generated by the account.
  --email-content: string # Content of welcome email template. (e.g. Great news, your new account is ready! For your records, we've listed information you'll use to log in below: FTP Server: [[ftpserver]] Username (Web and FTP access): [[username]] [[setpassword]])
  --email-subject: string # Subject line for welcome emails (e.g. ExaVault File Sharing Account)
  --external-domain: string # Custom address used for web file manager. Not available for all account types.
  --quota: record # shape: {noticeEnabled?: bool, noticeThreshold?: int, transactionsNoticeEnabled?: bool, transactionsNoticeThreshold?: int}
  --secure-only: oneof<nothing, bool> # Whether unencrypted FTP connections should be denied for the account. (e.g. false)
  --show-referral-links: oneof<nothing, bool> # Whether to display links for others to sign up on share views and invitation emails (e.g. false)
]: any -> record<data: record<attributes: record<accountName: string, accountOnboarding: bool, allowedIp: list, branding: bool, brandingSettings: record, clientId: int, complexPasswords: bool, created: string, customDomain: bool, customSignature: string, externalDomains: list, maxUsers: int, modified: string, planDetails: record, quota: record, secureOnly: bool, showReferralLinks: bool, status: int, userCount: int, welcomeEmailContent: string, welcomeEmailSubject: string>, id: int, relationships: record<masterUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let body = {"accountOnboarding": $account_onboarding, "allowedIpRanges": $allowed_ip_ranges, "brandingSettings": $branding_settings, "complexPasswords": $complex_passwords, "customSignature": $custom_signature, "emailContent": $email_content, "emailSubject": $email_subject, "externalDomain": $external_domain, "quota": $quota, "secureOnly": $secure_only, "showReferralLinks": $show_referral_links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get activity logs
#
# GET /activity/session
# operationId: getSessionLogs
export def "activity-session get-session-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date of the filter data range (format: date-time, e.g. 2019-10-18T06:48:40Z)
  --end-date: string # End date of the filter data range (format: date-time, e.g. 2019-10-18T06:48:40Z)
  --ip-address: string # Used to filter session logs by ip address. (e.g. 127.0.0.1)
  --username: string # Username used for filtering a list (e.g. jdoe)
  --path: string # Path used to filter records (e.g. /folder*)
  --type: string # Filter session logs for operation type (see table above for acceptable values) (e.g. EDIT_SHARE)
  --offset: int # Offset of the records list (e.g. 100)
  --limit: int # Limit of the records list (e.g. 10)
  --qp-sort: string # Comma separated list sort params (e.g. -date)
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: table<attributes: record, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "ipAddress" $ip_address "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/session" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get webhook logs
#
# GET /activity/webhooks
# operationId: getWebhookLogs
export def "activity-webhooks get-webhook-logs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Earliest date of entries to include in list (format: date-time)
  --end-date: string # Latest date of entries to include in list (format: date-time)
  --endpoint-url: string # Webhook listener endpoint (format: uri)
  --event: string # Type of activity that triggered the webhook attempt (e.g. resources.upload)
  --status-code: int # Response code from the webhook endpoint (e.g. 200)
  --resource-path: string # Path of the resource that triggered the webhook attempt (e.g. /Production)
  --username: string # Filter by triggering username. (e.g. exampleuser)
  --offset: int # Records to skip before returning results. (e.g. 100)
  --limit: int # Limit of the records list (e.g. 100)
  --qp-sort: string # Comma separated list sort params (e.g. -date,event)
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: table<attributes: any, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "endpointUrl" $endpoint_url "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "statusCode" $status_code "scalar") (serialize-qp "resourcePath" $resource_path "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity/webhooks" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all email groups
#
# GET /email-lists
# operationId: getEmailLists
export def "email-lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Related record types to include in the response. Valid option is `ownerUser`
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/email-lists" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new email list
#
# POST /email-lists
# operationId: addEmailList
export def "email-lists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  emails: list # Array of email addresses to include in the email list.  (e.g. [johns@example.com, jdoe@example.com])
  name: string # Name of the email list.  (e.g. My friends list)
]: any -> record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email-lists")
  let body = {"emails": $emails, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an email group with given id
#
# DELETE /email-lists/{id}
# operationId: deleteEmailListById
export def "email-lists delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/email-lists/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get individual email group
#
# GET /email-lists/{id}
# operationId: getEmailListById
export def "email-lists get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Related record types to include in the response. Valid option is `ownerUser`
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/email-lists/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an email group
#
# PATCH /email-lists/{id}
# operationId: updateEmailListById
export def "email-lists update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --emails: list # Email addresses that replace existing list. (e.g. [yuk@example.com, jdoe@example.com])
  --name: string # Name of the email list. (e.g. My friends list)
]: any -> record<data: record<attributes: record<created: string, emails: list, modified: string, name: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/email-lists/{id}"))
  let body = {"emails": $emails, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send referral email to a given address
#
# POST /email/referral
# operationId: sendReferralEmail
export def "email-referral send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  emails: list
  message: string # e.g. I use ExaVault for secure file sending, and so should you. Follow my link to sign up for a trial.
]: any -> record<data: list<string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/email/referral")
  let body = {"emails": $emails, "message": $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend welcome email to specific user
#
# POST /email/welcome/{username}
# operationId: sendWelcomeEmail
export def "email-welcome send" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: $username} | format pattern "/email/welcome/{username}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get receive folder form settings
#
# GET /forms
# operationId: getFormByShareHash
export def "forms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --share-hash: string # Share hash to retrieve the form for.
  --include: string@include-completer # Related record types to include in the response. Valid option is **share**
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access Token required to make the API call.
]: nothing -> record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shareHash" $share_hash "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/forms" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a receive form submission
#
# DELETE /forms/entries/{id}
# operationId: deleteFormMessageById
export def "forms-entries delete-form-message" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. 
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/forms/entries/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get form data entries for a receive
#
# GET /forms/entries/{id}
# operationId: getFormEntries
export def "forms-entries get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit of records to be returned (for pagination) (e.g. 10)
  --offset: int # Current offset of records (for pagination) (e.g. 100)
  --ev-api-key: string # API Key required to make the API call. 
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, type: string>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/forms/entries/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get receive folder form by Id
#
# GET /forms/{id}
# operationId: getFormById
export def "forms get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Enter "**share**" to get information about associated receive folder. (e.g. share)
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access Token required to make the API call.
]: nothing -> record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/forms/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a form with given parameters
#
# PATCH /forms/{id}
# operationId: updateFormById
# --elements item shape: {id?: int, name?: string, order?: int, settings?: record, type?: "name"|"email"|"text"|"textarea"|"upload_area"}
export def "forms update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --css-styles: string # e.g. #ev-widget-form {   /*Change this to change the font. Remove to use your website font*/   font-family: Helvetica Neue, sans-serif;   /*Makes the form the same width as your website */   margin: 0 -2%; } #ev-widget-form label{   width: 100%; } #ev-widget-form input, #ev-widget-form textarea {   /*Changes color and thickness of borders on form elements */   border: 2px solid #ccc;   /*Changes spacing inside the form elements (top/bottom and left/right */   padding: 5px 5px;   /* Changes how far away the inputs are from their label */   margin-top: 2px; }  #ev-widget-form input:focus, #ev-widget-form textarea:focus {   /*Changes the color of the form elements when they are clicked in to */   border: 2px solid #b2cf88;   /*Removes glow effect from form elements that are clicked in to */   outline: none; }  #ev-widget-form label {   font-size: 14px;   font-weight: bold;   /*Changes color of labels */   color: #232323 }  #ev-widget-form .ev-form-element-description {   /*Changes size of descriptions */   font-size: 12px;   /*Changes color of descriptions */   color: #777;   /* Changes how far away the descriptions are from their input */   margin-top: 2px; }  #ev-widget-form textarea {   /* Makes textareas (multiline inputs) a taller. */   min-height: 90px; }     
  --elements: list # item shape: {id?: int, name?: string, order?: int, settings?: record, type?: "name"|"email"|"text"|"textarea"|"upload_area"}
  --form-description: string # Set a description for the form that will be visible to recipients.  (e.g. Send your files)
  --submit-button-text: string # Text to be displayed on the submission button. (e.g. Send Files)
  --success-message: string # Text to be displayed when a recipient has submitted the form.  (e.g. Your files were uploaded)
]: any -> record<data: record<attributes: record<cssStyles: string, elements: list, formDescription: string, submitButtonText: string, successMessage: string>, id: int, relationships: record<share: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/forms/{id}"))
  let body = {"cssStyles": $css_styles, "elements": $elements, "formDescription": $form_description, "submitButtonText": $submit_button_text, "successMessage": $success_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of notifications
#
# GET /notifications
# operationId: listNotifications
export def "notifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Type of notification include in the list. Valid options are **file**, **folder**, **send_receipt**, **share_receipt**, **file_drop**  If this parameter is not used, only **file** and **folder** type notifications are included in the list. (e.g. file)
  --offset: int # Starting notification record in the result set. Can be used for pagination. (format: int32, default: 0, e.g. 50)
  --qp-sort: string # What order the list of matches should be in. Valid sort fields are **resourcename**, **date**, **action** and **type**. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending.  You can chose multiple options for the sort by separating them with commmas, such as "type,-date" to sort by type, then most recent. (e.g. date)
  --limit: int # Number of notification records to return. Can be used for pagination. (format: int32, default: 25, e.g. 100)
  --include: string@include-completer-1 # Related records to include in the response. Valid options are **ownerUser**, **resource**, **share** (e.g. resource,share,user)
  --action: string@action-completer # The kind of action which triggers the notification. Valid choices are **connect** (only for delivery receipts), **download**, **upload**, **delete**, or **all**   **Note** The **all** action matches notifications set to "all", not all notifications. For example, notifications set to trigger only on delete are not included if you filter for action=all (e.g. all)
  --ev-api-key: string # API Key required to make the API call. 
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new notification
#
# POST /notifications
# operationId: addNotification
export def "notifications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make API call. 
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  action: string@action-completer-1 # Type of action be notified about. Notifications will only be fired for the given type of action. Valid choices are **upload**, **download**, **delete** or **all** (upload/download/delete) (e.g. upload)
  --message: string # Custom message to include in notification emails.
  --recipients: list # Email addresses to send notification emails to. If not specified, sends to the current user's email address. (e.g. [myemail@example.com])
  resource: string # Resources for this notification. See details on [how to specify resources](#section/Identifying-Resources) above.
  --send-email: oneof<nothing, bool> # Set to true if the user should be notified by email when the notification is triggered. (e.g. true)
  type: string@type-completer-1 # What kind of notification you're making. Valid choices are:  - **file** to monitor activity for a file resource - **folder** to monitor activity for a folder resource (e.g. file)
  usernames: list # Determines which users' actions should trigger the notification.   Rather than listing  individual users, you can also use 3 special options:  - **notice\_user\_all** for activity by any user or share recipient - **notice\_user\_all\_users** for activity only by user accounts - **notice\_user\_all\_recipient** for activity only by share recipients
]: any -> record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications")
  let body = {"action": $action, "message": $message, "recipients": $recipients, "resource": $resource, "sendEmail": $send_email, "type": $type, "usernames": $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a notification
#
# DELETE /notifications/{id}
# operationId: deleteNotificationById
export def "notifications delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/notifications/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get notification details
#
# GET /notifications/{id}
# operationId: getNotificationById
export def "notifications get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Related record types to include in the response. You can include multiple types by separating them with commas. Valid options are **ownerUser**, **resource**, and **share**. (e.g. resource,share)
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/notifications/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a notification
#
# PATCH /notifications/{id}
# operationId: updateNotificationById
export def "notifications update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --action: string@action-completer-1 # Type of action be notified about. Notifications will only be sent for the given type of action. Valid choices are **upload**, **download**, **delete** or **all** (upload/download/delete) (e.g. all)
  --message: string # Custom message to insert into the notification emails, along with the matching activity.
  --recipients: list # Email addresses to send notification emails to. If empty, sends to the current user's email address. (e.g. [myemail@example.com])
  --send-email: oneof<nothing, bool> # Whether an email should be sent to the recipients when matching activity happens. (e.g. true)
  --usernames: list # Determines which users' actions should trigger the notification.   Rather than listing  individual users, you can also use 3 special options:  - **notice\_user\_all** for activity by any user or share recipient - **notice\_user\_all\_users** for activity only by user accounts - **notice\_user\_all\_recipients** for activity only by share recipients (e.g. [notice_user_all])
]: any -> record<data: record<attributes: record<action: string, created: string, message: string, modified: string, name: string, path: string, readableDescription: string, readableDescriptionWithoutPath: string, recipients: list, sendEmail: bool, shareId: string, type: string, userId: string, usernames: list>, id: int, relationships: record<ownerUser: record, resource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/notifications/{id}"))
  let body = {"action": $action, "message": $message, "recipients": $recipients, "sendEmail": $send_email, "usernames": $usernames} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend invitations to share recipients
#
# POST /recipients/shares/invites/{shareId}
# operationId: resendInvitationsForShare
export def "recipients-shares-invites resendInvitationsForShare" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --recipient-id: int # ID number of recipient to send a new invitation to. (format: int32)
]: any -> record<data: list<string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/recipients/shares/invites/{share_id}"))
  let body = {"recipientId": $recipient_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Resources
#
# DELETE /resources
# operationId: deleteResources
export def "resources delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  resources: list # Resource identifiers of items to delete.
]: any -> record<data: list<string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources")
  let body = {"resources": $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Resource Properties
#
# GET /resources
# operationId: getResourceInfo
export def "resources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # Resource identifier of the file or folder to get metadata for.
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerUser**.
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a folder
#
# POST /resources
# operationId: addFolder
export def "resources create-folder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --name: string # Name of the folder to create. Required if **path** is not used
  --parent-resource: string # Resource identifier where to create a folder. Required if **path** is not used
  --path: string # Fully-qualified path to the new folder including folder's name
]: any -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources")
  let body = {"name": $name, "parentResource": $parent_resource, "path": $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Compress resources
#
# POST /resources/compress
# operationId: compressFiles
export def "resources-compress compressFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --archive-name: string # Name of the zip archive to create. If left blank, current date will be used.
  --parent-resource: string # Resource identifier of the folder where zip archive should be created.
  resources: list # Resource identifiers for file(s)/folder(s) to include in new zip file
]: any -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources/compress")
  let body = {"archiveName": $archive_name, "parentResource": $parent_resource, "resources": $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy resources
#
# POST /resources/copy
# operationId: copyResources
export def "resources-copy copy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  parent_resource: string # Resource identifier for folder where items will be copied to.
  resources: list # Resource identifier(s) of items to be copied to a new location
]: any -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, meta: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources/copy")
  let body = {"parentResource": $parent_resource, "resources": $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a file
#
# GET /resources/download
# operationId: download
export def "resources-download download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --resources: list # Path of file or folder to be downloaded, starting from the root. Can also be an array of paths.
  --download-archive-name: string # When downloading multiple files, this will be used as the name of the zip file that is created.
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resources[]" $resources "multi") (serialize-qp "downloadArchiveName" $download_archive_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/download" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/octet-stream")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Extract resources
#
# POST /resources/extract
# operationId: extractFiles
export def "resources-extract extractFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  parent_resource: string # Resource identifier for folder files should be extracted to.
  resource: string # Resource identifier of zip archive to be extracted.
]: any -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources/extract")
  let body = {"parentResource": $parent_resource, "resource": $resource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of all resources
#
# GET /resources/list
# operationId: listResources
export def "resources-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # Resource identifier to get resources for. Can be path/id/name.
  --qp-sort: string # Endpoint support multiple sort fields by allowing array of sort params. Sort fields should be applied in the order specified. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending. (e.g. name)
  --offset: int # Determines which item to start on for pagination. Use zero (0) to start at the beginning of the list. e.g, setting `offset=200` would trigger the server to skip the first 200 matching entries when returning the results. (format: int32, default: 0)
  --limit: int # The number of files to limit the result. If you have more files in your directory than this limit, make multiple calls, incrementing the `offset` parameter, above. (format: int32)
  --type: string # Limit types of resources returned to "file" or "dir" only. This is ignored if you are using the `name` parameter to trigger a search.
  --name: string # Text to match resource names. This allows you to filter the results returned. For example, to locate only zip archive files, you can enter `*zip` and only resources ending in "zip" will be included in the list of results.
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerAccount**.
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/list" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List contents of folder
#
# GET /resources/list/{id}
# operationId: listResourceContents
export def "resources-list list-resource-contents" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Endpoint support multiple sort fields by allowing array of sort params. Sort fields should be applied in the order specified. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending. (e.g. name)
  --offset: int # Determines which item to start on for pagination. Use zero (0) to start at the beginning of the list. (format: int32, default: 0)
  --limit: int # The number of files to limit the result. Cannot be set higher than 100. If you have more than one hundred files in your directory, make multiple calls, incrementing the `offset parameter, above. (format: int32)
  --type: string # Limit types of resources returned to "file" or "dir" only.
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerUser**.
  --ev-api-key: string # API Key required to make the API call. 
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/resources/list/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move resources
#
# POST /resources/move
# operationId: moveResources
export def "resources-move move" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  parent_resource: string # Resource identifier of folder to move files/folders to. (e.g. /copyhere)
  resources: list # Array containing file/folder paths to move. (e.g. [/testone.jpg, /folder])
]: any -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, meta: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resources/move")
  let body = {"parentResource": $parent_resource, "resources": $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview a file
#
# GET /resources/preview
# operationId: getPreviewImage
export def "resources-preview get-preview-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource: string # Resource identifier for the image file.
  --size: string@size-completer # The size of the image.
  --width: int # Overrides sizes. Sets to a specific width. (format: int32)
  --height: int # Overrides sizes. Sets to a specific height. (format: int32)
  --page: int # Page number to extract from a multi-page document (0 is the first page). Vaild for **.pdf** or **.doc** files. (format: int32, default: 0)
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: record<attributes: record<image: string, imageHash: string, pageCount: int, size: int>, id: int, type: string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/preview" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a file
#
# POST /resources/upload
# operationId: uploadFile
export def "resources-upload upload-file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # Destination path for the file being uploaded, including the file name.
  --file-size: int # File size, in bits, of the file being uploaded. (e.g. 2935)
  --resume: oneof<nothing, bool> # True if upload resume is supported, false if it isn't.  (default: true, e.g. true)
  --allow-overwrite: oneof<nothing, bool> # True if a file with the same name is found in the designated path, should be overwritten. False if different file names should be generated.  (default: false, e.g. true)
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --offset-bytes: int # Allows a file upload to resume at a certain number of bytes. (e.g. 4852)
  --file: string # format: binary
]: any -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "fileSize" $file_size "scalar") (serialize-qp "resume" $resume "scalar") (serialize-qp "allowOverwrite" $allow_overwrite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources/upload" $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token, "offsetBytes": $offset_bytes} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete a Resource
#
# DELETE /resources/{id}
# operationId: deleteResourceById
export def "resources delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/resources/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get resource metadata
#
# GET /resources/{id}
# operationId: getResourceInfoById
export def "resources get-resource-info" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Comma separated list of relationships to include in response. Possible values are **share**, **notifications**, **directFile**, **parentResource**, **ownerUser**, **ownerAccount**.
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/resources/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rename a resource.
#
# PATCH /resources/{id}
# operationId: updateResourceById
export def "resources update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --ev-api-key: string # API key required to make the API call.
  --name: string # The new name for the resource (file or folder). (e.g. my-renamed-file.txt)
]: any -> record<data: record<attributes: record<accessedAt: string, accessedTime: int, createdAt: string, createdBy: string, createdTime: int, extension: string, fileCount: int, hash: string, name: string, path: string, previewable: bool, size: int, type: string, updatedAt: string, updatedTime: int, uploadDate: string>, id: int, relationships: record<directFile: record, notifications: list, parentResource: record, share: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/resources/{id}"))
  let body = {"name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-access-token": $ev_access_token, "ev-api-key": $ev_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of shares
#
# GET /shares
# operationId: listShares
export def "shares list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Current offset of records (for pagination) (e.g. 100)
  --limit: int # Limit of records to be returned (for pagination) (default: 100, e.g. 10)
  --scope: string@scope-completer # Set of shares to return. (**all**=all of them, **active**=shares that are currently active, **curentUser**=shares created by you) (e.g. active)
  --qp-sort: string@sort-completer # What order the list of matches should be in. (e.g. created)
  --type: string@type-completer-2 # Limit the list of matches to only certain types of shares. (e.g. receive)
  --include: string # Comma separated list of relationships to include in response. Possible values are **owner**, **resources**, **notifications**, **activity**. (e.g. owner,notifications)
  --name: string # When provided, only shares whose names include this value will be in the list. Supports wildcards, such as **send\*** to return everything starting with "send".  Use this parameter if you are searching for shares or receives for a specific folder name. For example **/Clients/ACME/To Be Processed**. (e.g. Customer*)
  --recipient: string # Filter the results to include only shares that invited a certain email address. Supports wildcard matching so that **\*@example.com** will give back entries shared with addresses ending in "@example.com".  (e.g. test@example.com)
  --message: string # When provided, only shares with a message that contains the text will be included in the list of matches. Both the subject and the body of all messages will be checked for matches. This will always be a wildcard match, so that searching for **taxes** will return any shares with a message that contains the word "taxes". (e.g. submitted)
  --username: string # When provided, only shares created by the user with that `username` will be included in the list. Does not support wildcard searching. (e.g. example)
  --search: string # Searches the share name, username, recipients, share messages fields for the provided value. Supports wildcard searches.
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shares" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a share
#
# POST /shares
# operationId: addShare
# --accessMode shape: {delete?: bool, download?: bool, modify?: bool, upload?: bool}
# --recipients item shape: {email?: string, type?: string}
export def "shares create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --access-mode: record # An object defining what a not-logged-in visitor can do with the share contents — shape: {delete?: bool, download?: bool, modify?: bool, upload?: bool}
  --embed: oneof<nothing, bool> # Whether this share can be embedded within a web page. (e.g. false)
  --expiration: string # Expiration date for the share. If someone attempts to use the share after this date, they will receive an error that the share is not available. (format: date-time, e.g. 2017-09-25T14:12:10Z)
  --file-drop-create-folders: oneof<nothing, bool> # Only used for **receive** shares. If true, uploads will be automatically placed into sub-folders of the folder, named after the chosen field on your form.  (e.g. false)
  --has-notification: oneof<nothing, bool> # Whether delivery receipts should be sent. (e.g. false)
  --is-public: oneof<nothing, bool> # Whether someone can visit the share without following a personalized recipient link. (e.g. true)
  --message-body: string # The message to be included in email invitations for your recipients. Ignored if you have not also provided `recipients` and `messageSubject`
  --message-subject: string # Subject to use on emails inviting recipients to the share. Ignored if you have not also provided `recipients` and a `messageBody` (e.g. Invitation to a shared folder)
  name: string # A name for the share. This will be visible on the page that recipients visit.  (e.g. Shared Folder)
  --notification-emails: list # Emails that will receive delivery receipts for this share. `hasNotification` must be **true** for delivery receipts will be sent. (e.g. [notify@example.com, notify2@example.com])
  --password: string # Set a password for recipients to access the share. All recipients will use the same password.
  --recipients: list # People you want to invite to the share. **Note**: unless you also set the `messageSubject` and `messageBody` for the new share, invitation emails will not be sent to these recipients. — item shape: {email?: string, type?: string}
  --require-email: oneof<nothing, bool> # True if recipients must provide their email to view the share. (e.g. false)
  --resources: list # Array of resources for this share. See details on [how to specify resources](#section/Identifying-Resources) above.  **shared_folder** and **receive** shares must have only one `resource`, which is a directory that does not have a current share attached.  **send** shares may have multiple `resource` parameters. You can also leave this parameter null if you are planning to upload files to the send. If you are planning to upload files to the send that are not yet in your account, you will also need to call the [POST /shares/complete-send/{id}](#operation/completeDirectSend) endpoint to finish the send operation.  (e.g. [/testfolder])
  --sending-local-files: oneof<nothing, bool> # Use this only for **send** shares. Flag to indicate that you are going to upload additional files from your computer to the share. If this is **true**, you will also need to use the [POST /shares/complete-send/{id}](#operation/completeDirectSend) call to finish setting up your share after the files are uploaded.
  type: string@type-completer-2 # The type of share to create. See above for a description of each. (e.g. shared_folder)
]: any -> record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shares")
  let body = {"accessMode": $access_mode, "embed": $embed, "expiration": $expiration, "fileDropCreateFolders": $file_drop_create_folders, "hasNotification": $has_notification, "isPublic": $is_public, "messageBody": $message_body, "messageSubject": $message_subject, "name": $name, "notificationEmails": $notification_emails, "password": $password, "recipients": $recipients, "requireEmail": $require_email, "resources": $resources, "sendingLocalFiles": $sending_local_files, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete send files
#
# POST /shares/complete-send/{id}
# operationId: completeDirectSend
export def "shares-complete-send completeDirectSend" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/shares/complete-send/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deactivate a share
#
# DELETE /shares/{id}
# operationId: deleteShareById
export def "shares delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/shares/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a share
#
# GET /shares/{id}
# operationId: getShareById
export def "shares get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Comma separated list of relationships to include in response. Possible values are **owner**, **resources**, **notifications**, **activity**. (e.g. owner,notifications)
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/shares/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a share
#
# PATCH /shares/{id}
# operationId: updateShareById
# --accessMode shape: {delete?: bool, download?: bool, modify?: bool, upload?: bool}
# --recipients item shape: {email?: string, type?: string}
export def "shares update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access Token (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  --access-mode: record # An object defining what a not-logged-in visitor can do with the share contents — shape: {delete?: bool, download?: bool, modify?: bool, upload?: bool}
  --embed: oneof<nothing, bool> # Whether the share can be embedded in another web page. (e.g. false)
  --expiration: string # New expiration date and time for the share (format: date-time, e.g. 2017-09-25T14:12:10Z)
  --file-drop-create-folders: oneof<nothing, bool> # Whether uploads to a receive folder should be automatically placed into subfolders. See our [receive folder documentation](/docs/account/05-file-sharing/05-form-builder#advanced-form-settings) (e.g. false)
  --has-notification: oneof<nothing, bool> # Whether delivery receipts should be sent for this share. (e.g. false)
  --is-public: oneof<nothing, bool> # Whether people can visit the share without following a link from an invitation email (e.g. true)
  --message-body: string # Message content to use for emails inviting recipients to the share. Ignored if you have not also provided `recipients` and a `subject`
  --message-subject: string # Subject to use on emails inviting recipients to the share. Ignored if you have not also provided `recipients` and a `message` (e.g. Invitation to a shared folder)
  --name: string # Name of the share. (e.g. Shared Folder)
  --notification-emails: list # List of email addresses to send delivery receipts to. Ignored if `hasNotification` is false.  (e.g. [notify@example.com, notify2@example.com])
  --password: string # New password for the share. To leave the password unchanged, do not send this parameter.
  --recipients: list # People you want to invite to the share.   **Note**: unless you also set the `subject` and `message` for the new share, invitation emails will not be sent to these recipients.  **Note**: Recipients in this list will **REPLACE** the recipients already assigned to this share.  — item shape: {email?: string, type?: string}
  --require-email: oneof<nothing, bool> # Whether visitors to the share will be required to enter their email in order to access the share. (e.g. false)
  --resources: list # Array of resources for this share. See details on [how to specify resources](#section/Identifying-Resources) above.  **shared_folder** and **receive** shares must have only one `resource`, which is a directory that does not have a current share attached.  **send** shares may have multiple `resource` parameters.   **NOTE**: Sending this parameter will **REPLACE** the existing resources with the resources included in this request. (e.g. [/testfolder])
  --status: int # New status for the share. You can set an active share to inactive by setting the status to **0**
]: any -> record<data: record<attributes: record<accessDescription: string, accessMode: record, created: string, embed: bool, expiration: string, expired: bool, fileDropCreateFolders: bool, formId: int, hasNotification: bool, hasPassword: bool, hash: string, inherited: bool, messages: list, modified: string, name: string, ownerHash: string, paths: list, public: bool, recipients: list, requireEmail: bool, resent: string, status: int, trackingStatus: string, type: string>, id: int, relationships: record<messages: list, notifications: list, owner: record, resources: list>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/shares/{id}"))
  let body = {"accessMode": $access_mode, "embed": $embed, "expiration": $expiration, "fileDropCreateFolders": $file_drop_create_folders, "hasNotification": $has_notification, "isPublic": $is_public, "messageBody": $message_body, "messageSubject": $message_subject, "name": $name, "notificationEmails": $notification_emails, "password": $password, "recipients": $recipients, "requireEmail": $require_email, "resources": $resources, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get metadata for a list of SSH Keys
#
# GET /ssh-keys
# operationId: getSSHKeysList
export def "ssh-keys get-ssh-keys-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string #  Only return results for the given user ID. This is not the username, but the numeric ID of the user.
  --limit: int #  Limits the results by the given number. Cannot be set higher than 100.
  --offset: int #  Determines which item to start on for pagination. Use zero (0) to start at the beginning of the list.
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ssh-keys" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new SSH Key
#
# POST /ssh-keys
# operationId: addSSHKey
export def "ssh-keys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  public_key: string # Public Key to provide ExaVault. You can provide the Public Key as formatted from the ssh-keygen command or a standard rfc-4716 format. 
  user_id: int # ID of the user to assign the new key to. 
]: any -> record<data: record<attributes: record<created: string, fingerprint: string, lastLogin: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ssh-keys")
  let body = {"publicKey": $public_key, "userId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an SSH Key
#
# DELETE /ssh-keys/{id}
# operationId: deleteSSHKey
export def "ssh-keys delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/ssh-keys/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata for an SSH Key
#
# GET /ssh-keys/{id}
# operationId: getSSHKey
export def "ssh-keys get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: record<attributes: record<created: string, fingerprint: string, lastLogin: string>, id: int, relationships: record<ownerUser: record>, type: string>, included: table<attributes: record, id: int, relationships: record, type: string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/ssh-keys/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of users
#
# GET /users
# operationId: listUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # The username of the user you are looking for. Only entries with the same username as this will be in the list of results. Does not support wildcard searches. (e.g. testuser)
  --home-resource: string # Resource identifier for user's home directory. Does not support wildcard searches.
  --nickname: string # Nickname to search for. Ignored if `username` is provided. Supports wildcard searches.
  --email: string # Email to search for. Ignored if `username` is provided. Supports wildcard searches (e.g. *@example.co)
  --role: string # Types of users to include the list. Ignored if `username` is provided. Valid options are **admin**, **master** and **user** (e.g. use)
  --status: int # Whether a user is locked. Ignored if `username` is provided. **0** means user is locked, **1** means user is not locked. 
  --search: string # Searches the nickname, email, role and homeDir fields for the provided value. Ignored if `username` is provided. Supports wildcard searches.
  --offset: int # Starting user record in the result set. Can be used for pagination. (format: int32, e.g. 50)
  --qp-sort: string # Sort order or matching users. You can sort by multiple columns by separating sort options with a comma; the sort will be applied in the order specified. The sort order for each sort field is ascending unless it is prefixed with a minus (“-“), in which case it will be descending.  Valid sort fields are: **nickname**, **username**, **email**, **homeDir** and **modified** (e.g. homeDir,-modified)
  --limit: int # Number of users to return. Can be used for pagination. (format: int32, e.g. 100)
  --include: string # Comma separated list of relationships to include in response. Valid options are **homeResource** and **ownerAccount**. (e.g. homeResource,ownerAccount)
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "homeResource" $home_resource "scalar") (serialize-qp "nickname" $nickname "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /users
# operationId: addUser
# --permissions shape: {changePassword?: bool, delete?: bool, deleteFormData?: bool, download?: bool, list?: bool, modify?: bool, notification?: bool, share?: bool, upload?: bool, viewFormData?: bool}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  email: string # Email address for the user (format: email, e.g. testuser@example.com)
  --expiration: string # Optional timestamp when the user should expire, formatted in date-time. (e.g. 2011-03-21 00:18:56)
  home_resource: string # Resource identifier for the user's home folder. See details on [how to specify resources](#section/Identifying-Resources) above.  The user will be locked to this directory and unable to move 'up' in the account. If the folder does not exist in the account, it will be created when the user is created.   Users with the `role` **admin** should have their homeResource set to '/' (e.g. /)
  --locked: oneof<nothing, bool> # If true, the user will not be able to log in (e.g. true)
  --nickname: string # An optional nickname (e.g. 'David from Sales'). (e.g. testnickname)
  --onboarding: oneof<nothing, bool> # Set this to **true** to enable extra help popups in the web file manager for this user. (e.g. true)
  password: string # Password for the user
  permissions: record # An object containing name/value pairs for each permission. Any permission that is not passed will be set to `false` by default. Note that users will be unable to see any files in the account unless you include `list` permission. When creating a user with the `role` **admin**, you should set all of the permissions to `true` — shape: {changePassword?: bool, delete?: bool, deleteFormData?: bool, download?: bool, list?: bool, modify?: bool, notification?: bool, share?: bool, upload?: bool, viewFormData?: bool}
  role: string@role-completer # The type of user to create, either **user** or **admin**. (e.g. user)
  time_zone: string # Time zone, used for accurate time display within the application. See <a href='https://php.net/manual/en/timezones.php' target='blank'>this page</a> for allowed values.  (e.g. America/Los_Angeles)
  username: string # Username of the user to create. This should follow standard username conventions - spaces are not allowed, etc. We do allow email addresses as usernames.  **Note** Usernames must be unique across all ExaVault accounts. (e.g. testuser)
  --welcome-email: oneof<nothing, bool> # If **true**, send this new user a welcome email upon creation. The content of the welcome email can be configured with the [PATCH /accounts](#operation/updateAccount) method. (e.g. true)
]: any -> record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {"email": $email, "expiration": $expiration, "homeResource": $home_resource, "locked": $locked, "nickname": $nickname, "onboarding": $onboarding, "password": $password, "permissions": $permissions, "role": $role, "timeZone": $time_zone, "username": $username, "welcomeEmail": $welcome_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user
#
# DELETE /users/{id}
# operationId: deleteUser
export def "users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API Key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/users/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get info for a user
#
# GET /users/{id}
# operationId: getUserById
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # Comma-separated list of relationships to include in response. Possible values include **homeResource** and **ownerAccount**. (e.g. homeResource,ownerAccount)
  --ev-api-key: string # API Key (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
]: nothing -> record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/users/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /users/{id}
# operationId: updateUser
# --permissions shape: {changePassword: bool, delete: bool, deleteFormData: bool, download: bool, list: bool, modify: bool, notification: bool, share: bool, upload: bool, viewFormData: bool}
export def "users update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call. (e.g. exampleaccount-zwSuWUZ8S38h33qPS8v0s)
  --ev-access-token: string # Access token required to make the API call. (e.g. 19853ef63a0bc348024a9e4cfd4a92520d2dfd04e88d8679fb1ed6bc551593d1)
  --email: string # Email address for the user (format: email, e.g. testuser@example.com)
  --expiration: string # Optional timestamp when the user should expire. (e.g. 2011-03-21 00:18:56)
  --home-resource: string # Resource identifier for the user's home folder. See details on [how to specify resources](#section/Identifying-Resources) above.  The user will be locked to this directory and unable to move 'up' in the account. If the folder does not exist in the account, it will be created when the user logs in.  This setting is ignored for users with the `role` **admin**. (e.g. /)
  --locked: oneof<nothing, bool> # If true, the user will be prevented from logging in (e.g. true)
  --nickname: string # An optional nickname (e.g. 'David from Sales'). (e.g. testnickname)
  --onboarding: oneof<nothing, bool> # Set this to **true** to enable extra help popups in the web file manager for this user. (e.g. true)
  --password: string # New password for the user
  --permissions: record # shape: {changePassword: bool, delete: bool, deleteFormData: bool, download: bool, list: bool, modify: bool, notification: bool, share: bool, upload: bool, viewFormData: bool}
  --role: string@role-completer # The type of user (**admin** or **user**). Note that admin users cannot have a `homeResource` other than '/', and will have full permissions, but you must provide at least "download,upload,list,delete" in the `permissions` parameter. (e.g. user)
  --time-zone: string # Time zone, used for accurate time display within the application. See <a href='https://php.net/manual/en/timezones.php' target='blank'>this page</a> for allowed values.  (e.g. America/Los_Angeles)
  --username: string # New username for the user. This should follow standard username conventions - spaces are not allowed, etc. We do allow email addresses as usernames.  **Note** Usernames must be unique across all ExaVault accounts. (e.g. testuser)
]: any -> record<data: record<attributes: record<accessTimestamp: string, accountName: string, created: string, email: string, expiration: string, firstLogin: bool, homePath: string, locked: bool, modified: string, nickname: string, onboarding: bool, permissions: record, role: string, status: int, timeZone: string, username: string>, id: int, relationships: record<homeResource: record, ownerAccount: record>, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/users/{id}"))
  let body = {"email": $email, "expiration": $expiration, "homeResource": $home_resource, "locked": $locked, "nickname": $nickname, "onboarding": $onboarding, "password": $password, "permissions": $permissions, "role": $role, "timeZone": $time_zone, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Webhooks List
#
# GET /webhooks
# operationId: getWehooksList
export def "webhooks get-wehooks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # List of related record types to include. Valid options are `owningAccount` and `resource`
  --offset: int # Records to skip before returning results. (e.g. 100)
  --limit: int # Limit of the records list (e.g. 100)
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int, returnedResults: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add A New Webhook
#
# POST /webhooks
# operationId: addWebhook
# --triggers shape: {resources?: record, shares?: record}
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  endpoint_url: string # The endpoint is where the webhook request will be sent. (format: uri, e.g. https://example.com/webhook)
  --resource: string # Resource identifier for the top folder this webhook is associated with (e.g. /uploads-folder)
  --response-version: string@response-version-completer # What version of webhook request should be sent to the endpoint URL when messages are sent (e.g. v2)
  --triggers: record # shape: {resources?: record, shares?: record}
]: any -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {"endpointUrl": $endpoint_url, "resource": $resource, "responseVersion": $response_version, "triggers": $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Regenerate security token
#
# POST /webhooks/regenerate-token/{id}
# operationId: regenerateWebhookToken
export def "webhooks-regenerate-token regenerateWebhookToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/regenerate-token/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend a webhook message
#
# POST /webhooks/resend/{activityId}
# operationId: resendWebhookActivityEntry
export def "webhooks-resend resendWebhookActivityEntry" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({activity_id: $activity_id} | format pattern "/webhooks/resend/{activity_id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a webhook
#
# DELETE /webhooks/{id}
# operationId: deleteWebhook
export def "webhooks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: list<string>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/{id}"))
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get info for a webhook
#
# GET /webhooks/{id}
# operationId: getWebhookById
export def "webhooks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string #  Include metadata for related items; `ownerAccount` and/or `resource` 
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
]: nothing -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/{id}") $qp)
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /webhooks/{id}
# operationId: updateWebhook
# --triggers shape: {resources?: record, shares?: record}
export def "webhooks update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ev-api-key: string # API key required to make the API call.
  --ev-access-token: string # Access token required to make the API call. (e.g. 5dc97cc607985eb8da033220e7447647e7915fbf73808)
  --endpoint-url: string # New endpoint URL to use for the webhook configuration (format: uri, e.g. https://example.com/new-endpoint)
  --resource: string # Resource identifier of the top folder watched by this webhook. (e.g. /newfolder)
  --response-version: string@response-version-completer # Version of the webhooks message to send to the endpoint (e.g. v1)
  --triggers: record # shape: {resources?: record, shares?: record}
]: any -> record<data: table<attributes: record, id: int, relationships: record, type: string>, included: list<any>, responseStatus: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/webhooks/{id}"))
  let body = {"endpointUrl": $endpoint_url, "resource": $resource, "responseVersion": $response_version, "triggers": $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ev-api-key": $ev_api_key, "ev-access-token": $ev_access_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
