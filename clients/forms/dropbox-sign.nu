# Auto-generated client for Dropbox Sign API v3.0.0
# Source: https://raw.githubusercontent.com/hellosign/hellosign-openapi/main/openapi.yaml
# Auth: --token flag or $env.DROPBOX_SIGN_API_TOKEN

const BASE_URL = "https://api.hellosign.com/v3"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DROPBOX_SIGN_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.hellosign.com/v3" "https://app.hellosign.com"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def country-completer [] { ["CA" "UK" "US"] }
def state-completer [] { ["AK" "AL" "AR" "AZ" "CA" "CO" "CT" "DC" "DE" "FL" "GA" "HI" "IA" "ID" "IL" "IN" "KS" "KY" "LA" "MA" "MD" "ME" "MI" "MN" "MO" "MS" "MT" "NC" "ND" "NE" "NH" "NJ" "NM" "NV" "NY" "OH" "OK" "OR" "PA" "RI" "SC" "SD" "TN" "TX" "UT" "VA" "VT" "WA" "WI" "WV" "WY"] }
def province-completer [] { ["AB" "BC" "MB" "NB" "NL" "NS" "NT" "NU" "ON" "PE" "QC" "SK" "YT"] }
def file-type-completer [] { ["pdf" "zip"] }
def accept-completer [] { ["application/pdf" "application/zip"] }
def role-completer [] { ["Admin" "Developer" "Member" "Team Manager"] }
def new-role-completer [] { ["Admin" "Developer" "Member" "Team Manager"] }
def type-completer [] { ["request_signature" "send_document"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-create accountCreate" } } | get name | first)
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

# Create Account
#
# POST /account/create
# operationId: accountCreate
export def "account-create accountCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Used when creating a new account with OAuth authorization.  See [OAuth 2.0 Authorization](https://app.hellosign.com/api/oauthWalkthrough#OAuthAuthorization)
  --client-secret: string # Used when creating a new account with OAuth authorization.  See [OAuth 2.0 Authorization](https://app.hellosign.com/api/oauthWalkthrough#OAuthAuthorization)
  email_address: string # The email address which will be associated with the new Account. (format: email)
  --locale: string # The locale used in this Account. Check out the list of [supported locales](/api/reference/constants/#supported-locales) to learn more about the possible values.
]: any -> record<account: record<account_id: string, email_address: string, is_locked: bool, is_paid_hs: bool, is_paid_hf: bool, quotas: record<api_signature_requests_left: int, documents_left: int, templates_total: int, templates_left: int, sms_verifications_left: int, num_fax_pages_left: int>, callback_url: string, role_code: string, team_id: string, locale: string, usage: record<fax_pages_sent: int>, settings: record<signer_access_codes: bool, sms_delivery: bool, sms_authentication: bool>>, oauth_data: record<access_token: string, token_type: string, refresh_token: string, expires_in: int, state: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/create")
  let body = {client_id: $client_id, client_secret: $client_secret, email_address: $email_address, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Account
#
# GET /account
# operationId: accountGet
export def "account accountGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # `account_id` or `email_address` is required. If both are provided, the account id prevails.  The ID of the Account.
  --email-address: string # `account_id` or `email_address` is required, If both are provided, the account id prevails.  The email address of the Account.
]: nothing -> record<account: record<account_id: string, email_address: string, is_locked: bool, is_paid_hs: bool, is_paid_hf: bool, quotas: record<api_signature_requests_left: int, documents_left: int, templates_total: int, templates_left: int, sms_verifications_left: int, num_fax_pages_left: int>, callback_url: string, role_code: string, team_id: string, locale: string, usage: record<fax_pages_sent: int>, settings: record<signer_access_codes: bool, sms_delivery: bool, sms_authentication: bool>>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Account
#
# PUT /account
# operationId: accountUpdate
export def "account accountUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # The ID of the Account (nullable)
  --callback-url: string # The URL that Dropbox Sign should POST events to.
  --locale: string # The locale used in this Account. Check out the list of [supported locales](/api/reference/constants/#supported-locales) to learn more about the possible values.
]: any -> record<account: record<account_id: string, email_address: string, is_locked: bool, is_paid_hs: bool, is_paid_hf: bool, quotas: record<api_signature_requests_left: int, documents_left: int, templates_total: int, templates_left: int, sms_verifications_left: int, num_fax_pages_left: int>, callback_url: string, role_code: string, team_id: string, locale: string, usage: record<fax_pages_sent: int>, settings: record<signer_access_codes: bool, sms_delivery: bool, sms_authentication: bool>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let body = {account_id: $account_id, callback_url: $callback_url, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify Account
#
# POST /account/verify
# operationId: accountVerify
export def "account-verify accountVerify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # Email address to run the verification for. (format: email)
]: any -> record<account: record<email_address: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/verify")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create API App
#
# POST /api_app
# operationId: apiAppCreate
# --oauth shape: {callback_url?: string, scopes?: list}
# --options shape: {can_insert_everywhere?: bool}
# --white_labeling_options shape: {header_background_color?: string, legal_version?: "terms1"|"terms2", link_color?: string, page_background_color?: string, primary_button_color?: string, primary_button_color_hover?: string, primary_button_text_color?: string, primary_button_text_color_hover?: string, secondary_button_color?: string, secondary_button_color_hover?: string, secondary_button_text_color?: string, secondary_button_text_color_hover?: string, text_color1?: string, text_color2?: string, reset_to_default?: bool}
export def "api-app apiAppCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callback-url: string # The URL at which the ApiApp should receive event callbacks.
  --custom-logo-file: string # An image file to use as a custom logo in embedded contexts. (Only applies to some API plans) (format: binary)
  domains: list # The domain names the ApiApp will be associated with.
  name: string # The name you want to assign to the ApiApp.
  --oauth: record # OAuth related parameters. — shape: {callback_url?: string, scopes?: list}
  --options: record # Additional options supported by API App. — shape: {can_insert_everywhere?: bool}
  --white-labeling-options: record # An array of elements and values serialized to a string, to be used to customize the app's signer page. (Only applies to some API plans)  Take a look at our [white labeling guide](https://developers.hellosign.com/api/reference/premium-branding/) to learn more. — shape: {header_background_color?: string, legal_version?: "terms1"|"terms2", link_color?: string, page_background_color?: string, primary_button_color?: string, primary_button_color_hover?: string, primary_button_text_color?: string, primary_button_text_color_hover?: string, secondary_button_color?: string, secondary_button_color_hover?: string, secondary_button_text_color?: string, secondary_button_text_color_hover?: string, text_color1?: string, text_color2?: string, reset_to_default?: bool}
]: any -> record<api_app: record<callback_url: string, client_id: string, created_at: int, domains: list<string>, name: string, is_approved: bool, oauth: record<callback_url: string, secret: string, scopes: list, charges_users: bool>, options: record<can_insert_everywhere: bool>, owner_account: record<account_id: string, email_address: string>, white_labeling_options: record<header_background_color: string, legal_version: string, link_color: string, page_background_color: string, primary_button_color: string, primary_button_color_hover: string, primary_button_text_color: string, primary_button_text_color_hover: string, secondary_button_color: string, secondary_button_color_hover: string, secondary_button_text_color: string, secondary_button_text_color_hover: string, text_color1: string, text_color2: string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_app")
  let body = {callback_url: $callback_url, custom_logo_file: $custom_logo_file, domains: $domains, name: $name, oauth: $oauth, options: $options, white_labeling_options: $white_labeling_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get API App
#
# GET /api_app/{client_id}
# operationId: apiAppGet
export def "api-app apiAppGet" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<api_app: record<callback_url: string, client_id: string, created_at: int, domains: list<string>, name: string, is_approved: bool, oauth: record<callback_url: string, secret: string, scopes: list, charges_users: bool>, options: record<can_insert_everywhere: bool>, owner_account: record<account_id: string, email_address: string>, white_labeling_options: record<header_background_color: string, legal_version: string, link_color: string, page_background_color: string, primary_button_color: string, primary_button_color_hover: string, primary_button_text_color: string, primary_button_text_color_hover: string, secondary_button_color: string, secondary_button_color_hover: string, secondary_button_text_color: string, secondary_button_text_color_hover: string, text_color1: string, text_color2: string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_app/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update API App
#
# PUT /api_app/{client_id}
# operationId: apiAppUpdate
# --oauth shape: {callback_url?: string, scopes?: list}
# --options shape: {can_insert_everywhere?: bool}
# --white_labeling_options shape: {header_background_color?: string, legal_version?: "terms1"|"terms2", link_color?: string, page_background_color?: string, primary_button_color?: string, primary_button_color_hover?: string, primary_button_text_color?: string, primary_button_text_color_hover?: string, secondary_button_color?: string, secondary_button_color_hover?: string, secondary_button_text_color?: string, secondary_button_text_color_hover?: string, text_color1?: string, text_color2?: string, reset_to_default?: bool}
export def "api-app apiAppUpdate" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callback-url: string # The URL at which the API App should receive event callbacks.
  --custom-logo-file: string # An image file to use as a custom logo in embedded contexts. (Only applies to some API plans) (format: binary)
  --domains: list # The domain names the ApiApp will be associated with.
  --name: string # The name you want to assign to the ApiApp.
  --oauth: record # OAuth related parameters. — shape: {callback_url?: string, scopes?: list}
  --options: record # Additional options supported by API App. — shape: {can_insert_everywhere?: bool}
  --white-labeling-options: record # An array of elements and values serialized to a string, to be used to customize the app's signer page. (Only applies to some API plans)  Take a look at our [white labeling guide](https://developers.hellosign.com/api/reference/premium-branding/) to learn more. — shape: {header_background_color?: string, legal_version?: "terms1"|"terms2", link_color?: string, page_background_color?: string, primary_button_color?: string, primary_button_color_hover?: string, primary_button_text_color?: string, primary_button_text_color_hover?: string, secondary_button_color?: string, secondary_button_color_hover?: string, secondary_button_text_color?: string, secondary_button_text_color_hover?: string, text_color1?: string, text_color2?: string, reset_to_default?: bool}
]: any -> record<api_app: record<callback_url: string, client_id: string, created_at: int, domains: list<string>, name: string, is_approved: bool, oauth: record<callback_url: string, secret: string, scopes: list, charges_users: bool>, options: record<can_insert_everywhere: bool>, owner_account: record<account_id: string, email_address: string>, white_labeling_options: record<header_background_color: string, legal_version: string, link_color: string, page_background_color: string, primary_button_color: string, primary_button_color_hover: string, primary_button_text_color: string, primary_button_text_color_hover: string, secondary_button_color: string, secondary_button_color_hover: string, secondary_button_text_color: string, secondary_button_text_color_hover: string, text_color1: string, text_color2: string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_app/($client_id)")
  let body = {callback_url: $callback_url, custom_logo_file: $custom_logo_file, domains: $domains, name: $name, oauth: $oauth, options: $options, white_labeling_options: $white_labeling_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete API App
#
# DELETE /api_app/{client_id}
# operationId: apiAppDelete
export def "api-app apiAppDelete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_app/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API Apps
#
# GET /api_app/list
# operationId: apiAppList
export def "api-app-list apiAppList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page number of the API App List to return. Defaults to `1`. (default: 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20)
]: nothing -> record<api_apps: table<callback_url: string, client_id: string, created_at: int, domains: list, name: string, is_approved: bool, oauth: record, options: record, owner_account: record, white_labeling_options: record>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api_app/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bulk Send Job
#
# GET /bulk_send_job/{bulk_send_job_id}
# operationId: bulkSendJobGet
export def "bulk-send-job bulkSendJobGet" [
  bulk_send_job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page number of the BulkSendJob list to return. Defaults to `1`. (default: 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is 20. (default: 20)
]: nothing -> record<bulk_send_job: record<bulk_send_job_id: string, total: int, is_creator: bool, created_at: int>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, signature_requests: list<record>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulk_send_job/($bulk_send_job_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Bulk Send Jobs
#
# GET /bulk_send_job/list
# operationId: bulkSendJobList
export def "bulk-send-job-list bulkSendJobList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page number of the BulkSendJob List to return. Defaults to `1`. (default: 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is 20. (default: 20)
]: nothing -> record<bulk_send_jobs: table<bulk_send_job_id: string, total: int, is_creator: bool, created_at: int>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulk_send_job/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Embedded Template Edit URL
#
# POST /embedded/edit_url/{template_id}
# operationId: embeddedEditUrl
# --editor_options shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
# --merge_fields item shape: {name: string, type: "text"|"checkbox"}
export def "embedded-edit-url embeddedEditUrl" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-edit-ccs: oneof<nothing, bool> # This allows the requester to enable/disable to add or change CC roles when editing the template. (default: false)
  --cc-roles: list # The CC roles that must be assigned when using the template to send a signature request. To remove all CC roles, pass in a single role with no name. For use in a POST request.
  --editor-options: record # This allows the requester to specify editor options when a preparing a document — shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
  --force-signer-roles: oneof<nothing, bool> # Provide users the ability to review/edit the template signer roles. (default: false)
  --force-subject-message: oneof<nothing, bool> # Provide users the ability to review/edit the template subject and message. (default: false)
  --merge-fields: list # Add additional merge fields to the template, which can be used used to pre-fill data by passing values into signature requests made with that template.  Remove all merge fields on the template by passing an empty array `[]`. — item shape: {name: string, type: "text"|"checkbox"}
  --preview-only: oneof<nothing, bool> # This allows the requester to enable the preview experience (i.e. does not allow the requester's end user to add any additional fields via the editor).  **NOTE:** This parameter overwrites `show_preview=true` (if set). (default: false)
  --show-preview: oneof<nothing, bool> # This allows the requester to enable the editor/preview experience. (default: false)
  --show-progress-stepper: oneof<nothing, bool> # When only one step remains in the signature request process and this parameter is set to `false` then the progress stepper will be hidden. (default: true)
  --test-mode: oneof<nothing, bool> # Whether this is a test, locked templates will only be available for editing if this is set to `true`. Defaults to `false`. (default: false)
]: any -> record<embedded: record<edit_url: string, expires_at: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/embedded/edit_url/($template_id)")
  let body = {allow_edit_ccs: $allow_edit_ccs, cc_roles: $cc_roles, editor_options: $editor_options, force_signer_roles: $force_signer_roles, force_subject_message: $force_subject_message, merge_fields: $merge_fields, preview_only: $preview_only, show_preview: $show_preview, show_progress_stepper: $show_progress_stepper, test_mode: $test_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Embedded Sign URL
#
# GET /embedded/sign_url/{signature_id}
# operationId: embeddedSignUrl
export def "embedded-sign-url embeddedSignUrl" [
  signature_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<embedded: record<sign_url: string, expires_at: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/embedded/sign_url/($signature_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Fax
#
# GET /fax/{fax_id}
# operationId: faxGet
export def "fax faxGet" [
  fax_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fax: record<fax_id: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, sender: string, files_url: string, final_copy_uri: string, transmissions: list<record>>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fax/($fax_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Fax
#
# DELETE /fax/{fax_id}
# operationId: faxDelete
export def "fax faxDelete" [
  fax_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fax/($fax_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Fax Files
#
# GET /fax/files/{fax_id}
# operationId: faxFiles
export def "fax-files faxFiles" [
  fax_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fax/files/($fax_id)")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Fax Line User
#
# PUT /fax_line/add_user
# operationId: faxLineAddUser
export def "fax-line-add-user faxLineAddUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  number: string # The Fax Line number
  --account-id: string # Account ID (e.g. ab55cd14a97219e36b5ff5fe23f2f9329b0c1e97)
  --email-address: string # Email address (format: email)
]: any -> record<fax_line: record<number: string, created_at: int, updated_at: int, accounts: list<record>>, warnings: record<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fax_line/add_user")
  let body = {number: $number, account_id: $account_id, email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Available Fax Line Area Codes
#
# GET /fax_line/area_codes
# operationId: faxLineAreaCodeGet
export def "fax-line-area-codes faxLineAreaCodeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string@country-completer # Filter area codes by country (e.g. US)
  --state: string@state-completer # Filter area codes by state
  --province: string@province-completer # Filter area codes by province
  --city: string # Filter area codes by city
]: nothing -> record<area_codes: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "province" $province "scalar") (serialize-qp "city" $city "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fax_line/area_codes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purchase Fax Line
#
# POST /fax_line/create
# operationId: faxLineCreate
export def "fax-line-create faxLineCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  area_code: int # Area code of the new Fax Line
  country: string@country-completer # Country of the area code
  --city: string # City of the area code
  --account-id: string # Account ID of the account that will be assigned this new Fax Line (e.g. ab55cd14a97219e36b5ff5fe23f2f9329b0c1e97)
]: any -> record<fax_line: record<number: string, created_at: int, updated_at: int, accounts: list<record>>, warnings: record<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fax_line/create")
  let body = {area_code: $area_code, country: $country, city: $city, account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Fax Line
#
# GET /fax_line
# operationId: faxLineGet
export def "fax-line faxLineGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number: string # The Fax Line number (e.g. 123-123-1234)
]: nothing -> record<fax_line: record<number: string, created_at: int, updated_at: int, accounts: list<record>>, warnings: record<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fax_line" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Fax Line
#
# DELETE /fax_line
# operationId: faxLineDelete
export def "fax-line faxLineDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  number: string # The Fax Line number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fax_line")
  let body = {number: $number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Fax Lines
#
# GET /fax_line/list
# operationId: faxLineList
export def "fax-line-list faxLineList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Account ID (e.g. ab55cd14a97219e36b5ff5fe23f2f9329b0c1e97)
  --page: int # Which page number of the Fax Line List to return. Defaults to `1`. (default: 1, e.g. 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20, e.g. 20)
  --show-team-lines: oneof<nothing, bool> # Include Fax Lines belonging to team members in the list
]: nothing -> record<list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, fax_lines: table<number: string, created_at: int, updated_at: int, accounts: list>, warnings: record<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "show_team_lines" $show_team_lines "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fax_line/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove Fax Line Access
#
# PUT /fax_line/remove_user
# operationId: faxLineRemoveUser
export def "fax-line-remove-user faxLineRemoveUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  number: string # The Fax Line number
  --account-id: string # Account ID of the user to remove access (e.g. ab55cd14a97219e36b5ff5fe23f2f9329b0c1e97)
  --email-address: string # Email address of the user to remove access (format: email)
]: any -> record<fax_line: record<number: string, created_at: int, updated_at: int, accounts: list<record>>, warnings: record<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fax_line/remove_user")
  let body = {number: $number, account_id: $account_id, email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists Faxes
#
# GET /fax/list
# operationId: faxList
export def "fax-list faxList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page number of the Fax List to return. Defaults to `1`. (default: 1, e.g. 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20, e.g. 20)
]: nothing -> record<faxes: table<fax_id: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, sender: string, files_url: string, final_copy_uri: string, transmissions: list>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fax/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Fax
#
# POST /fax/send
# operationId: faxSend
export def "fax-send faxSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  recipient: string # Recipient of the fax  Can be a phone number in E.164 format or email address (e.g. recipient@example.com)
  --sender: string # Fax Send From Sender (used only with fax number) (e.g. sender@example.com)
  --files: list # Use `files[]` to indicate the uploaded file(s) to fax  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Fax download the file(s) to fax  This endpoint requires either **files** or **file_urls[]**, but not both.
  --test-mode: oneof<nothing, bool> # API Test Mode Setting (default: false)
  --cover-page-to: string # Fax cover page recipient information (e.g. Recipient Name)
  --cover-page-from: string # Fax cover page sender information (e.g. Sender Name)
  --cover-page-message: string # Fax Cover Page Message (e.g. Please find the attached documents.)
  --title: string # Fax Title (e.g. Fax Title)
]: any -> record<fax: record<fax_id: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, sender: string, files_url: string, final_copy_uri: string, transmissions: list<record>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fax/send")
  let body = {recipient: $recipient, sender: $sender, files: $files, file_urls: $file_urls, test_mode: $test_mode, cover_page_to: $cover_page_to, cover_page_from: $cover_page_from, cover_page_message: $cover_page_message, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# OAuth Token Generate
#
# POST /oauth/token
# operationId: oauthTokenGenerate
export def "oauth-token oauthTokenGenerate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The client id of the app requesting authorization.
  client_secret: string # The secret token of your app.
  code: string # The code passed to your callback when the user granted access.
  grant_type: string # When generating a new token use `authorization_code`. (default: authorization_code)
  state: string # Same as the state you specified earlier.
]: any -> record<access_token: string, token_type: string, refresh_token: string, expires_in: int, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://app.hellosign.com")
  let full_url = (build-url $base "/oauth/token")
  let body = {client_id: $client_id, client_secret: $client_secret, code: $code, grant_type: $grant_type, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# OAuth Token Refresh
#
# POST /oauth/token?refresh
# operationId: oauthTokenRefresh
export def "oauth-token-refresh oauthTokenRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grant_type: string # When refreshing an existing token use `refresh_token`. (default: refresh_token)
  refresh_token: string # The token provided when you got the expired access token.
  --client-id: string # The client ID for your API app. Required for new API apps. To enhance security, we recommend making it required for existing apps in your app settings.
  --client-secret: string # The client secret for your API app. Required for new API apps. To enhance security, we recommend making it required for existing apps in your app settings.
]: any -> record<access_token: string, token_type: string, refresh_token: string, expires_in: int, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://app.hellosign.com")
  let full_url = (build-url $base "/oauth/token?refresh")
  let body = {grant_type: $grant_type, refresh_token: $refresh_token, client_id: $client_id, client_secret: $client_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Report
#
# POST /report/create
# operationId: reportCreate
export def "report-create reportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end_date: string # The (inclusive) end date for the report data in `MM/DD/YYYY` format.
  report_type: list # The type(s) of the report you are requesting. Allowed values are `user_activity` and `document_status`. User activity reports contain list of all users and their activity during the specified date range. Document status report contain a list of signature requests created in the specified time range (and their status).
  start_date: string # The (inclusive) start date for the report data in `MM/DD/YYYY` format.
]: any -> record<report: record<success: string, start_date: string, end_date: string, report_type: list<any>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report/create")
  let body = {end_date: $end_date, report_type: $report_type, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Embedded Bulk Send with Template
#
# POST /signature_request/bulk_create_embedded_with_template
# operationId: signatureRequestBulkCreateEmbeddedWithTemplate
# --signer_list item shape: {custom_fields?: list, signers?: list}
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
export def "signature-request-bulk-create-embedded-with-template signatureRequestBulkCreateEmbeddedWithTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the template will be used.
  --signer-file: string # `signer_file` is a CSV file defining values and options for signer fields. Required unless a `signer_list` is used, you may not use both. The CSV can have the following columns:  - `name`: the name of the signer filling the role of RoleName - `email_address`: email address of the signer filling the role of RoleName - `pin`: the 4- to 12-character access code that will secure this signer's signature page (optional) - `sms_phone_number`: An E.164 formatted phone number that will receive a code via SMS to access this signer's signature page. (optional)      By using the feature, you agree you are responsible for obtaining a signer's consent to receive text messages from Dropbox Sign related to this signature request and confirm you have obtained such consent from all signers prior to enabling SMS delivery for this signature request. [Learn more](https://faq.hellosign.com/hc/en-us/articles/15815316468877-Dropbox-Sign-SMS-tools-add-on).      **NOTE:** Not available in test mode and requires a Standard plan or higher. - `*_field`: any column with a _field" suffix will be treated as a custom field (optional)      You may only specify field values here, any other options should be set in the custom_fields request parameter.  Example CSV:  ``` name, email_address, pin, company_field George, george@example.com, d79a3td, ABC Corp Mary, mary@example.com, gd9as5b, 123 LLC ``` (format: binary)
  --signer-list: list # `signer_list` is an array defining values and options for signer fields. Required unless a `signer_file` is used, you may not use both. — item shape: {custom_fields?: list, signers?: list}
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  client_id: string # Client id of the app you're using to create this embedded signature request. Used for security purposes.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
]: any -> record<bulk_send_job: record<bulk_send_job_id: string, total: int, is_creator: bool, created_at: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signature_request/bulk_create_embedded_with_template")
  let body = {template_ids: $template_ids, signer_file: $signer_file, signer_list: $signer_list, allow_decline: $allow_decline, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, message: $message, metadata: $metadata, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Send with Template
#
# POST /signature_request/bulk_send_with_template
# operationId: signatureRequestBulkSendWithTemplate
# --signer_list item shape: {custom_fields?: list, signers?: list}
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
export def "signature-request-bulk-send-with-template signatureRequestBulkSendWithTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the template will be used.
  --signer-file: string # `signer_file` is a CSV file defining values and options for signer fields. Required unless a `signer_list` is used, you may not use both. The CSV can have the following columns:  - `name`: the name of the signer filling the role of RoleName - `email_address`: email address of the signer filling the role of RoleName - `pin`: the 4- to 12-character access code that will secure this signer's signature page (optional) - `sms_phone_number`: An E.164 formatted phone number that will receive a code via SMS to access this signer's signature page. (optional)      By using the feature, you agree you are responsible for obtaining a signer's consent to receive text messages from Dropbox Sign related to this signature request and confirm you have obtained such consent from all signers prior to enabling SMS delivery for this signature request. [Learn more](https://faq.hellosign.com/hc/en-us/articles/15815316468877-Dropbox-Sign-SMS-tools-add-on).      **NOTE:** Not available in test mode and requires a Standard plan or higher. - `*_field`: any column with a _field" suffix will be treated as a custom field (optional)      You may only specify field values here, any other options should be set in the custom_fields request parameter.  Example CSV:  ``` name, email_address, pin, company_field George, george@example.com, d79a3td, ABC Corp Mary, mary@example.com, gd9as5b, 123 LLC ``` (format: binary)
  --signer-list: list # `signer_list` is an array defining values and options for signer fields. Required unless a `signer_file` is used, you may not use both. — item shape: {custom_fields?: list, signers?: list}
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  --client-id: string # The client id of the API App you want to associate with this request. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
]: any -> record<bulk_send_job: record<bulk_send_job_id: string, total: int, is_creator: bool, created_at: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signature_request/bulk_send_with_template")
  let body = {template_ids: $template_ids, signer_file: $signer_file, signer_list: $signer_list, allow_decline: $allow_decline, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, message: $message, metadata: $metadata, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Incomplete Signature Request
#
# POST /signature_request/cancel/{signature_request_id}
# operationId: signatureRequestCancel
export def "signature-request-cancel signatureRequestCancel" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/cancel/($signature_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Embedded Signature Request
#
# POST /signature_request/create_embedded
# operationId: signatureRequestCreateEmbedded
# --signers item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --grouped_signers item shape: {group: string, order?: int, signers: list}
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-create-embedded signatureRequestCreateEmbedded" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --signers: list # Add Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --grouped-signers: list # Add Grouped Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {group: string, order?: int, signers: list}
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-email-addresses: list # The email addresses that should be CCed.
  client_id: string # Client id of the app you're using to create this embedded signature request. Used for security purposes.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --hide-text-tags: oneof<nothing, bool> # Enables automatic Text Tag removal when set to true.  **NOTE:** Removing text tags this way can cause unwanted clipping. We recommend leaving this setting on `false` and instead hiding your text tags using white text or a similar approach. See the [Text Tags Walkthrough](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) for more information. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --use-text-tags: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document. Defaults to disabled, or `false`. (default: false)
  --populate-auto-fill-fields: oneof<nothing, bool> # Controls whether [auto fill fields](https://faq.hellosign.com/hc/en-us/articles/360051467511-Auto-Fill-Fields) can automatically populate a signer's information during signing.  **NOTE:** Keep your signer's information safe by ensuring that the _signer on your signature request is the intended party_ before using this feature. (default: false)
  --expires-at: int # When the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details. (nullable)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signature_request/create_embedded")
  let body = {files: $files, file_urls: $file_urls, signers: $signers, grouped_signers: $grouped_signers, allow_decline: $allow_decline, allow_reassign: $allow_reassign, attachments: $attachments, cc_email_addresses: $cc_email_addresses, client_id: $client_id, custom_fields: $custom_fields, field_options: $field_options, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, hide_text_tags: $hide_text_tags, message: $message, metadata: $metadata, signing_options: $signing_options, subject: $subject, test_mode: $test_mode, title: $title, use_text_tags: $use_text_tags, populate_auto_fill_fields: $populate_auto_fill_fields, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Embedded Signature Request with Template
#
# POST /signature_request/create_embedded_with_template
# operationId: signatureRequestCreateEmbeddedWithTemplate
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --signers item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-create-embedded-with-template signatureRequestCreateEmbeddedWithTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the template will be used.
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  client_id: string # Client id of the app you're using to create this embedded signature request. Used for security purposes.
  --custom-fields: list # An array defining values and options for custom fields. Required when a custom field exists in the Template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  signers: list # Add Signers to your Templated-based Signature Request. — item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --populate-auto-fill-fields: oneof<nothing, bool> # Controls whether [auto fill fields](https://faq.hellosign.com/hc/en-us/articles/360051467511-Auto-Fill-Fields) can automatically populate a signer's information during signing.  **NOTE:** Keep your signer's information safe by ensuring that the _signer on your signature request is the intended party_ before using this feature. (default: false)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signature_request/create_embedded_with_template")
  let body = {template_ids: $template_ids, allow_decline: $allow_decline, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, files: $files, file_urls: $file_urls, message: $message, metadata: $metadata, signers: $signers, signing_options: $signing_options, subject: $subject, test_mode: $test_mode, title: $title, populate_auto_fill_fields: $populate_auto_fill_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit Signature Request
#
# PUT /signature_request/edit/{signature_request_id}
# operationId: signatureRequestEdit
# --signers item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --grouped_signers item shape: {group: string, order?: int, signers: list}
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-edit signatureRequestEdit" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --signers: list # Add Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --grouped-signers: list # Add Grouped Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {group: string, order?: int, signers: list}
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan and higher. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-email-addresses: list # The email addresses that should be CCed.
  --client-id: string # The client id of the API App you want to associate with this request. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --hide-text-tags: oneof<nothing, bool> # Enables automatic Text Tag removal when set to true.  **NOTE:** Removing text tags this way can cause unwanted clipping. We recommend leaving this setting on `false` and instead hiding your text tags using white text or a similar approach. See the [Text Tags Walkthrough](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) for more information. (default: false)
  --is-eid: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [electronic identification (eID)](https://www.hellosign.com/features/electronic-id), which requires the signer to verify their identity with an eID provider to sign a document.<br> **NOTE:** You need the eID add-on to use this feature. Please [contact sales](https://sign.dropbox.com/form/contact-sales) for more information. Cannot be used in `test_mode`. Only works on requests with one signer. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --use-text-tags: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document. Defaults to disabled, or `false`. (default: false)
  --expires-at: int # When the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details. (nullable)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/edit/($signature_request_id)")
  let body = {files: $files, file_urls: $file_urls, signers: $signers, grouped_signers: $grouped_signers, allow_decline: $allow_decline, allow_reassign: $allow_reassign, attachments: $attachments, cc_email_addresses: $cc_email_addresses, client_id: $client_id, custom_fields: $custom_fields, field_options: $field_options, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, hide_text_tags: $hide_text_tags, is_eid: $is_eid, message: $message, metadata: $metadata, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, title: $title, use_text_tags: $use_text_tags, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit Embedded Signature Request
#
# PUT /signature_request/edit_embedded/{signature_request_id}
# operationId: signatureRequestEditEmbedded
# --signers item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --grouped_signers item shape: {group: string, order?: int, signers: list}
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-edit-embedded signatureRequestEditEmbedded" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --signers: list # Add Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --grouped-signers: list # Add Grouped Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {group: string, order?: int, signers: list}
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-email-addresses: list # The email addresses that should be CCed.
  client_id: string # Client id of the app you're using to create this embedded signature request. Used for security purposes.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --hide-text-tags: oneof<nothing, bool> # Enables automatic Text Tag removal when set to true.  **NOTE:** Removing text tags this way can cause unwanted clipping. We recommend leaving this setting on `false` and instead hiding your text tags using white text or a similar approach. See the [Text Tags Walkthrough](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) for more information. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --use-text-tags: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document. Defaults to disabled, or `false`. (default: false)
  --populate-auto-fill-fields: oneof<nothing, bool> # Controls whether [auto fill fields](https://faq.hellosign.com/hc/en-us/articles/360051467511-Auto-Fill-Fields) can automatically populate a signer's information during signing.  **NOTE:** Keep your signer's information safe by ensuring that the _signer on your signature request is the intended party_ before using this feature. (default: false)
  --expires-at: int # When the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details. (nullable)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/edit_embedded/($signature_request_id)")
  let body = {files: $files, file_urls: $file_urls, signers: $signers, grouped_signers: $grouped_signers, allow_decline: $allow_decline, allow_reassign: $allow_reassign, attachments: $attachments, cc_email_addresses: $cc_email_addresses, client_id: $client_id, custom_fields: $custom_fields, field_options: $field_options, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, hide_text_tags: $hide_text_tags, message: $message, metadata: $metadata, signing_options: $signing_options, subject: $subject, test_mode: $test_mode, title: $title, use_text_tags: $use_text_tags, populate_auto_fill_fields: $populate_auto_fill_fields, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit Embedded Signature Request with Template
#
# PUT /signature_request/edit_embedded_with_template/{signature_request_id}
# operationId: signatureRequestEditEmbeddedWithTemplate
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --signers item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-edit-embedded-with-template signatureRequestEditEmbeddedWithTemplate" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the template will be used.
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  client_id: string # Client id of the app you're using to create this embedded signature request. Used for security purposes.
  --custom-fields: list # An array defining values and options for custom fields. Required when a custom field exists in the Template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  signers: list # Add Signers to your Templated-based Signature Request. — item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --populate-auto-fill-fields: oneof<nothing, bool> # Controls whether [auto fill fields](https://faq.hellosign.com/hc/en-us/articles/360051467511-Auto-Fill-Fields) can automatically populate a signer's information during signing.  **NOTE:** Keep your signer's information safe by ensuring that the _signer on your signature request is the intended party_ before using this feature. (default: false)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/edit_embedded_with_template/($signature_request_id)")
  let body = {template_ids: $template_ids, allow_decline: $allow_decline, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, files: $files, file_urls: $file_urls, message: $message, metadata: $metadata, signers: $signers, signing_options: $signing_options, subject: $subject, test_mode: $test_mode, title: $title, populate_auto_fill_fields: $populate_auto_fill_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit Signature Request With Template
#
# PUT /signature_request/edit_with_template/{signature_request_id}
# operationId: signatureRequestEditWithTemplate
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --signers item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-edit-with-template signatureRequestEditWithTemplate" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the template will be used.
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  --client-id: string # Client id of the app to associate with the signature request. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # An array defining values and options for custom fields. Required when a custom field exists in the Template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --is-eid: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [electronic identification (eID)](https://www.hellosign.com/features/electronic-id), which requires the signer to verify their identity with an eID provider to sign a document.<br> **NOTE:** You need the eID add-on to use this feature. Please [contact sales](https://sign.dropbox.com/form/contact-sales) for more information. Cannot be used in `test_mode`. Only works on requests with one signer. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  signers: list # Add Signers to your Templated-based Signature Request. — item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/edit_with_template/($signature_request_id)")
  let body = {template_ids: $template_ids, allow_decline: $allow_decline, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, files: $files, file_urls: $file_urls, is_eid: $is_eid, message: $message, metadata: $metadata, signers: $signers, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download Files
#
# GET /signature_request/files/{signature_request_id}
# operationId: signatureRequestFiles
export def "signature-request-files signatureRequestFiles" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --file-type: string@file-type-completer # Set to `pdf` for a single merged document or `zip` for a collection of individual documents. (default: pdf)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_type" $file_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/signature_request/files/($signature_request_id)" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Files as Data Uri
#
# GET /signature_request/files_as_data_uri/{signature_request_id}
# operationId: signatureRequestFilesAsDataUri
export def "signature-request-files-as-data-uri signatureRequestFilesAsDataUri" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/files_as_data_uri/($signature_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Files as File Url
#
# GET /signature_request/files_as_file_url/{signature_request_id}
# operationId: signatureRequestFilesAsFileUrl
export def "signature-request-files-as-file-url signatureRequestFilesAsFileUrl" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-download: int # By default when opening the `file_url` a browser will download the PDF and save it locally. When set to `0` the PDF file will be displayed in the browser. (default: 1)
]: nothing -> record<file_url: string, expires_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_download" $force_download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/signature_request/files_as_file_url/($signature_request_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Signature Request
#
# GET /signature_request/{signature_request_id}
# operationId: signatureRequestGet
export def "signature-request signatureRequestGet" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/($signature_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Signature Requests
#
# GET /signature_request/list
# operationId: signatureRequestList
export def "signature-request-list signatureRequestList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Which account to return SignatureRequests for. Must be a team member. Use `all` to indicate all team members. Defaults to your account.
  --page: int # Which page number of the SignatureRequest List to return. Defaults to `1`. (default: 1, e.g. 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20)
  --qp-query: string # String that includes search terms and/or fields to be used to filter the SignatureRequest objects.
]: nothing -> record<signature_requests: table<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list, signing_redirect_url: string, final_copy_uri: string, template_ids: list, custom_fields: list, attachments: list, response_data: list, signatures: list, bulk_send_job_id: string>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/signature_request/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Release On-Hold Signature Request
#
# POST /signature_request/release_hold/{signature_request_id}
# operationId: signatureRequestReleaseHold
export def "signature-request-release-hold signatureRequestReleaseHold" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/release_hold/($signature_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Request Reminder
#
# POST /signature_request/remind/{signature_request_id}
# operationId: signatureRequestRemind
export def "signature-request-remind signatureRequestRemind" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the signer to send a reminder to. (format: email)
  --name: string # The name of the signer to send a reminder to. Include if two or more signers share an email address.
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/remind/($signature_request_id)")
  let body = {email_address: $email_address, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Signature Request Access
#
# POST /signature_request/remove/{signature_request_id}
# operationId: signatureRequestRemove
export def "signature-request-remove signatureRequestRemove" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/remove/($signature_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Signature Request
#
# POST /signature_request/send
# operationId: signatureRequestSend
# --signers item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --grouped_signers item shape: {group: string, order?: int, signers: list}
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-send signatureRequestSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --signers: list # Add Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {name: string, email_address: string, order?: int, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --grouped-signers: list # Add Grouped Signers to your Signature Request.  This endpoint requires either **signers** or **grouped_signers**, but not both. — item shape: {group: string, order?: int, signers: list}
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan and higher. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-email-addresses: list # The email addresses that should be CCed.
  --client-id: string # The client id of the API App you want to associate with this request. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --hide-text-tags: oneof<nothing, bool> # Enables automatic Text Tag removal when set to true.  **NOTE:** Removing text tags this way can cause unwanted clipping. We recommend leaving this setting on `false` and instead hiding your text tags using white text or a similar approach. See the [Text Tags Walkthrough](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) for more information. (default: false)
  --is-eid: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [electronic identification (eID)](https://www.hellosign.com/features/electronic-id), which requires the signer to verify their identity with an eID provider to sign a document.<br> **NOTE:** You need the eID add-on to use this feature. Please [contact sales](https://sign.dropbox.com/form/contact-sales) for more information. Cannot be used in `test_mode`. Only works on requests with one signer. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --use-text-tags: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document. Defaults to disabled, or `false`. (default: false)
  --expires-at: int # When the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details. (nullable)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signature_request/send")
  let body = {files: $files, file_urls: $file_urls, signers: $signers, grouped_signers: $grouped_signers, allow_decline: $allow_decline, allow_reassign: $allow_reassign, attachments: $attachments, cc_email_addresses: $cc_email_addresses, client_id: $client_id, custom_fields: $custom_fields, field_options: $field_options, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, hide_text_tags: $hide_text_tags, is_eid: $is_eid, message: $message, metadata: $metadata, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, title: $title, use_text_tags: $use_text_tags, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send with Template
#
# POST /signature_request/send_with_template
# operationId: signatureRequestSendWithTemplate
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --signers item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "signature-request-send-with-template signatureRequestSendWithTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the template will be used.
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  --client-id: string # Client id of the app to associate with the signature request. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # An array defining values and options for custom fields. Required when a custom field exists in the Template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --is-eid: oneof<nothing, bool> # Send with a value of `true` if you wish to enable [electronic identification (eID)](https://www.hellosign.com/features/electronic-id), which requires the signer to verify their identity with an eID provider to sign a document.<br> **NOTE:** You need the eID add-on to use this feature. Please [contact sales](https://sign.dropbox.com/form/contact-sales) for more information. Cannot be used in `test_mode`. Only works on requests with one signer. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  signers: list # Add Signers to your Templated-based Signature Request. — item shape: {role: string, name: string, email_address: string, pin?: string, sms_phone_number?: string, sms_phone_number_type?: "authentication"|"delivery"}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signature_request/send_with_template")
  let body = {template_ids: $template_ids, allow_decline: $allow_decline, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, files: $files, file_urls: $file_urls, is_eid: $is_eid, message: $message, metadata: $metadata, signers: $signers, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Signature Request
#
# POST /signature_request/update/{signature_request_id}
# operationId: signatureRequestUpdate
export def "signature-request-update signatureRequestUpdate" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-address: string # The new email address for the recipient.  This will generate a new `signature_id` value.  **NOTE:** Optional if `name` is provided. (format: email)
  --name: string # The new name for the recipient.  **NOTE:** Optional if `email_address` is provided.
  signature_id: string # The signature ID for the recipient.
  --expires-at: int # The new time when the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details. (nullable)
]: any -> record<signature_request: record<test_mode: bool, signature_request_id: string, requester_email_address: string, title: string, original_title: string, subject: string, message: string, metadata: record, created_at: int, expires_at: int, is_complete: bool, is_declined: bool, has_error: bool, files_url: string, signing_url: string, details_url: string, cc_email_addresses: list<string>, signing_redirect_url: string, final_copy_uri: string, template_ids: list<string>, custom_fields: list<record>, attachments: list<record>, response_data: list<record>, signatures: list<record>, bulk_send_job_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/signature_request/update/($signature_request_id)")
  let body = {email_address: $email_address, name: $name, signature_id: $signature_id, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add User to Team
#
# PUT /team/add_member
# operationId: teamAddMember
export def "team-add-member teamAddMember" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string # The id of the team. (e.g. 4fea99bfcf2b26bfccf6cea3e127fb8bb74d8d9c)
  --account-id: string # `account_id` or `email_address` is required. If both are provided, the account id prevails.  Account id of the user to invite to your Team.
  --email-address: string # `account_id` or `email_address` is required, If both are provided, the account id prevails.  Email address of the user to invite to your Team. (format: email)
  --role: string@role-completer # A role member will take in a new Team.  **NOTE:** This parameter is used only if `team_id` is provided.
]: any -> record<team: record<name: string, accounts: list<record>, invited_accounts: list<record>, invited_emails: list<string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team/add_member" $qp)
  let body = {account_id: $account_id, email_address: $email_address, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Team
#
# POST /team/create
# operationId: teamCreate
export def "team-create teamCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of your Team. (default: Untitled Team)
]: any -> record<team: record<name: string, accounts: list<record>, invited_accounts: list<record>, invited_emails: list<string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team/create")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Team
#
# DELETE /team/destroy
# operationId: teamDelete
export def "team-destroy teamDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team/destroy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Team
#
# GET /team
# operationId: teamGet
export def "team teamGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<team: record<name: string, accounts: list<record>, invited_accounts: list<record>, invited_emails: list<string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Team
#
# PUT /team
# operationId: teamUpdate
export def "team teamUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of your Team.
]: any -> record<team: record<name: string, accounts: list<record>, invited_accounts: list<record>, invited_emails: list<string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Team Info
#
# GET /team/info
# operationId: teamInfo
export def "team-info teamInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --team-id: string # The id of the team. (e.g. 4fea99bfcf2b26bfccf6cea3e127fb8bb74d8d9c)
]: nothing -> record<team: record<team_id: string, team_parent: record<team_id: string, name: string>, name: string, num_members: int, num_sub_teams: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team_id" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Team Invites
#
# GET /team/invites
# operationId: teamInvites
export def "team-invites teamInvites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-address: string # The email address for which to display the team invites.
]: nothing -> record<team_invites: table<email_address: string, team_id: string, role: string, sent_at: int, redeemed_at: int, expires_at: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/team/invites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Team Members
#
# GET /team/members/{team_id}
# operationId: teamMembers
export def "team-members teamMembers" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page number of the team member list to return. Defaults to `1`. (default: 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20)
]: nothing -> record<team_members: table<account_id: string, email_address: string, role: string>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/team/members/($team_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove User from Team
#
# POST /team/remove_member
# operationId: teamRemoveMember
export def "team-remove-member teamRemoveMember" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # **account_id** or **email_address** is required. If both are provided, the account id prevails.  Account id to remove from your Team.
  --email-address: string # **account_id** or **email_address** is required. If both are provided, the account id prevails.  Email address of the Account to remove from your Team. (format: email)
  --new-owner-email-address: string # The email address of an Account on this Team to receive all documents, templates, and API apps (if applicable) from the removed Account. If not provided, and on an Enterprise plan, this data will remain with the removed Account.  **NOTE:** Only available for Enterprise plans. (format: email)
  --new-team-id: string # Id of the new Team.
  --new-role: string@new-role-completer # A new role member will take in a new Team.  **NOTE:** This parameter is used only if `new_team_id` is provided.
]: any -> record<team: record<name: string, accounts: list<record>, invited_accounts: list<record>, invited_emails: list<string>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/team/remove_member")
  let body = {account_id: $account_id, email_address: $email_address, new_owner_email_address: $new_owner_email_address, new_team_id: $new_team_id, new_role: $new_role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Sub Teams
#
# GET /team/sub_teams/{team_id}
# operationId: teamSubTeams
export def "team-sub-teams teamSubTeams" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Which page number of the SubTeam List to return. Defaults to `1`. (default: 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20)
]: nothing -> record<sub_teams: table<team_id: string, name: string>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/team/sub_teams/($team_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add User to Template
#
# POST /template/add_user/{template_id}
# operationId: templateAddUser
export def "template-add-user templateAddUser" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # The id of the Account to give access to the Template. **NOTE:** The account id prevails if email address is also provided.
  --email-address: string # The email address of the Account to give access to the Template. **NOTE:** The account id prevails if it is also provided. (format: email)
  --skip-notification: oneof<nothing, bool> # If set to `true`, the user does not receive an email notification when a template has been shared with them. Defaults to `false`. (default: false)
]: any -> record<template: record<template_id: string, title: string, message: string, updated_at: int, is_embedded: bool, is_creator: bool, can_edit: bool, is_locked: bool, metadata: record, signer_roles: list<record>, cc_roles: list<record>, documents: list<record>, custom_fields: list<record>, named_form_fields: list<record>, accounts: list<record>, attachments: list<record>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/add_user/($template_id)")
  let body = {account_id: $account_id, email_address: $email_address, skip_notification: $skip_notification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Template
#
# POST /template/create
# operationId: templateCreate
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --merge_fields item shape: {name: string, type: "text"|"checkbox"}
# --signer_roles item shape: {name?: string, order?: int}
export def "template-create templateCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan and higher. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-roles: list # The CC roles that must be assigned when using the template to send a signature request
  --client-id: string # Client id of the app you're using to create this draft. Used to apply the branding and callback url defined for the app.
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  form_fields_per_document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --merge-fields: list # Add merge fields to the template. Merge fields are placed by the user creating the template and used to pre-fill data by passing values into signature requests with the `custom_fields` parameter. If the signature request using that template *does not* pass a value into a merge field, then an empty field remains in the document. — item shape: {name: string, type: "text"|"checkbox"}
  --message: string # The default template email message.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  signer_roles: list # An array of the designated signer roles that must be specified when sending a SignatureRequest using this Template. — item shape: {name?: string, order?: int}
  --subject: string # The template title (alias).
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --use-preexisting-fields: oneof<nothing, bool> # Enable the detection of predefined PDF fields by setting the `use_preexisting_fields` to `true` (defaults to disabled, or `false`). (default: false)
]: any -> record<template: record<template_id: string>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/template/create")
  let body = {files: $files, file_urls: $file_urls, allow_reassign: $allow_reassign, attachments: $attachments, cc_roles: $cc_roles, client_id: $client_id, field_options: $field_options, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, merge_fields: $merge_fields, message: $message, metadata: $metadata, signer_roles: $signer_roles, subject: $subject, test_mode: $test_mode, title: $title, use_preexisting_fields: $use_preexisting_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Embedded Template Draft
#
# POST /template/create_embedded_draft
# operationId: templateCreateEmbeddedDraft
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --editor_options shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --merge_fields item shape: {name: string, type: "text"|"checkbox"}
# --signer_roles item shape: {name?: string, order?: int}
export def "template-create-embedded-draft templateCreateEmbeddedDraft" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --allow-ccs: oneof<nothing, bool> # This allows the requester to specify whether the user is allowed to provide email addresses to CC when creating a template. (default: true)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan and higher. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-roles: list # The CC roles that must be assigned when using the template to send a signature request
  client_id: string # Client id of the app you're using to create this draft. Used to apply the branding and callback url defined for the app.
  --editor-options: record # This allows the requester to specify editor options when a preparing a document — shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --force-signer-roles: oneof<nothing, bool> # Provide users the ability to review/edit the template signer roles. (default: false)
  --force-subject-message: oneof<nothing, bool> # Provide users the ability to review/edit the template subject and message. (default: false)
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --merge-fields: list # Add merge fields to the template. Merge fields are placed by the user creating the template and used to pre-fill data by passing values into signature requests with the `custom_fields` parameter. If the signature request using that template *does not* pass a value into a merge field, then an empty field remains in the document. — item shape: {name: string, type: "text"|"checkbox"}
  --message: string # The default template email message.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --show-preview: oneof<nothing, bool> # This allows the requester to enable the editor/preview experience.  - `show_preview=true`: Allows requesters to enable the editor/preview experience. - `show_preview=false`: Allows requesters to disable the editor/preview experience. (default: false)
  --show-progress-stepper: oneof<nothing, bool> # When only one step remains in the signature request process and this parameter is set to `false` then the progress stepper will be hidden. (default: true)
  --signer-roles: list # An array of the designated signer roles that must be specified when sending a SignatureRequest using this Template. — item shape: {name?: string, order?: int}
  --skip-me-now: oneof<nothing, bool> # Disables the "Me (Now)" option for the person preparing the document. Does not work with type `send_document`. Defaults to `false`. (default: false)
  --subject: string # The template title (alias).
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --use-preexisting-fields: oneof<nothing, bool> # Enable the detection of predefined PDF fields by setting the `use_preexisting_fields` to `true` (defaults to disabled, or `false`). (default: false)
]: any -> record<template: record<template_id: string, edit_url: string, expires_at: int, warnings: list<record>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/template/create_embedded_draft")
  let body = {files: $files, file_urls: $file_urls, allow_ccs: $allow_ccs, allow_reassign: $allow_reassign, attachments: $attachments, cc_roles: $cc_roles, client_id: $client_id, editor_options: $editor_options, field_options: $field_options, force_signer_roles: $force_signer_roles, force_subject_message: $force_subject_message, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, merge_fields: $merge_fields, message: $message, metadata: $metadata, show_preview: $show_preview, show_progress_stepper: $show_progress_stepper, signer_roles: $signer_roles, skip_me_now: $skip_me_now, subject: $subject, test_mode: $test_mode, title: $title, use_preexisting_fields: $use_preexisting_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Template
#
# POST /template/delete/{template_id}
# operationId: templateDelete
export def "template-delete templateDelete" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/delete/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Template Files
#
# GET /template/files/{template_id}
# operationId: templateFiles
export def "template-files templateFiles" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --file-type: string@file-type-completer # Set to `pdf` for a single merged document or `zip` for a collection of individual documents.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_type" $file_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/template/files/($template_id)" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Template Files as Data Uri
#
# GET /template/files_as_data_uri/{template_id}
# operationId: templateFilesAsDataUri
export def "template-files-as-data-uri templateFilesAsDataUri" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/files_as_data_uri/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Template Files as File Url
#
# GET /template/files_as_file_url/{template_id}
# operationId: templateFilesAsFileUrl
export def "template-files-as-file-url templateFilesAsFileUrl" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --force-download: int # By default when opening the `file_url` a browser will download the PDF and save it locally. When set to `0` the PDF file will be displayed in the browser. (default: 1)
]: nothing -> record<file_url: string, expires_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force_download" $force_download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/template/files_as_file_url/($template_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Template
#
# GET /template/{template_id}
# operationId: templateGet
export def "template templateGet" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<template: record<template_id: string, title: string, message: string, updated_at: int, is_embedded: bool, is_creator: bool, can_edit: bool, is_locked: bool, metadata: record, signer_roles: list<record>, cc_roles: list<record>, documents: list<record>, custom_fields: list<record>, named_form_fields: list<record>, accounts: list<record>, attachments: list<record>>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Templates
#
# GET /template/list
# operationId: templateList
export def "template-list templateList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # Which account to return Templates for. Must be a team member. Use `all` to indicate all team members. Defaults to your account.
  --page: int # Which page number of the Template List to return. Defaults to `1`. (default: 1)
  --page-size: int # Number of objects to be returned per page. Must be between `1` and `100`. Default is `20`. (default: 20)
  --qp-query: string # String that includes search terms and/or fields to be used to filter the Template objects.
]: nothing -> record<templates: table<template_id: string, title: string, message: string, updated_at: int, is_embedded: bool, is_creator: bool, can_edit: bool, is_locked: bool, metadata: record, signer_roles: list, cc_roles: list, documents: list, custom_fields: list, named_form_fields: list, accounts: list, attachments: list>, list_info: record<num_pages: int, num_results: int, page: int, page_size: int>, warnings: table<warning_msg: string, warning_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_id" $account_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/template/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove User from Template
#
# POST /template/remove_user/{template_id}
# operationId: templateRemoveUser
export def "template-remove-user templateRemoveUser" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string # The id or email address of the Account to remove access to the Template. The account id prevails if both are provided.
  --email-address: string # The id or email address of the Account to remove access to the Template. The account id prevails if both are provided. (format: email)
]: any -> record<template: record<template_id: string, title: string, message: string, updated_at: int, is_embedded: bool, is_creator: bool, can_edit: bool, is_locked: bool, metadata: record, signer_roles: list<record>, cc_roles: list<record>, documents: list<record>, custom_fields: list<record>, named_form_fields: list<record>, accounts: list<record>, attachments: list<record>>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/remove_user/($template_id)")
  let body = {account_id: $account_id, email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Template Files
#
# POST /template/update_files/{template_id}
# operationId: templateUpdateFiles
export def "template-update-files templateUpdateFiles" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Client id of the app you're using to update this template.
  --files: list # Use `files[]` to indicate the uploaded file(s) to use for the template.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to use for the template.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --message: string # The new default template email message.
  --subject: string # The new default template email subject.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
]: any -> record<template: record<template_id: string, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/template/update_files/($template_id)")
  let body = {client_id: $client_id, files: $files, file_urls: $file_urls, message: $message, subject: $subject, test_mode: $test_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Unclaimed Draft
#
# POST /unclaimed_draft/create
# operationId: unclaimedDraftCreate
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --signers item shape: {email_address: string, name: string, order?: int}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "unclaimed-draft-create unclaimedDraftCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-email-addresses: list # The email addresses that should be CCed.
  --client-id: string # Client id of the app used to create the draft. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --hide-text-tags: oneof<nothing, bool> # Send with a value of `true` if you wish to enable automatic Text Tag removal. Defaults to `false`. When using Text Tags it is preferred that you set this to `false` and hide your tags with white text or something similar because the automatic removal system can cause unwanted clipping. See the [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) walkthrough for more details. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --show-progress-stepper: oneof<nothing, bool> # When only one step remains in the signature request process and this parameter is set to `false` then the progress stepper will be hidden. (default: true)
  --signers: list # Add Signers to your Unclaimed Draft Signature Request. — item shape: {email_address: string, name: string, order?: int}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  type: string@type-completer # The type of unclaimed draft to create. Use `send_document` to create a claimable file, and `request_signature` for a claimable signature request. If the type is `request_signature` then signers name and email_address are not optional.
  --use-preexisting-fields: oneof<nothing, bool> # Set `use_text_tags` to `true` to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document (defaults to disabled, or `false`). Alternatively, if your PDF contains pre-defined fields, enable the detection of these fields by setting the `use_preexisting_fields` to `true` (defaults to disabled, or `false`). Currently we only support use of either `use_text_tags` or `use_preexisting_fields` parameter, not both. (default: false)
  --use-text-tags: oneof<nothing, bool> # Set `use_text_tags` to `true` to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document (defaults to disabled, or `false`). Alternatively, if your PDF contains pre-defined fields, enable the detection of these fields by setting the `use_preexisting_fields` to `true` (defaults to disabled, or `false`). Currently we only support use of either `use_text_tags` or `use_preexisting_fields` parameter, not both. (default: false)
  --expires-at: int # When the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details.  **NOTE:** This does not correspond to the **expires_at** returned in the response. (nullable)
]: any -> record<unclaimed_draft: record<signature_request_id: string, claim_url: string, signing_redirect_url: string, requesting_redirect_url: string, expires_at: int, test_mode: bool>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unclaimed_draft/create")
  let body = {files: $files, file_urls: $file_urls, allow_decline: $allow_decline, attachments: $attachments, cc_email_addresses: $cc_email_addresses, client_id: $client_id, custom_fields: $custom_fields, field_options: $field_options, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, hide_text_tags: $hide_text_tags, message: $message, metadata: $metadata, show_progress_stepper: $show_progress_stepper, signers: $signers, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, subject: $subject, test_mode: $test_mode, type: $type, use_preexisting_fields: $use_preexisting_fields, use_text_tags: $use_text_tags, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Embedded Unclaimed Draft
#
# POST /unclaimed_draft/create_embedded
# operationId: unclaimedDraftCreateEmbedded
# --attachments item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --editor_options shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --form_field_groups item shape: {group_id: string, group_label: string, requirement: string}
# --form_field_rules item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
# --form_fields_per_document item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
# --signers item shape: {email_address: string, name: string, order?: int}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "unclaimed-draft-create-embedded unclaimedDraftCreateEmbedded" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --files: list # Use `files[]` to indicate the uploaded file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --file-urls: list # Use `file_urls[]` to have Dropbox Sign download the file(s) to send for signature.  This endpoint requires either **files** or **file_urls[]**, but not both.
  --allow-ccs: oneof<nothing, bool> # This allows the requester to specify whether the user is allowed to provide email addresses to CC when claiming the draft. (default: true)
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan and higher. (default: false)
  --attachments: list # A list describing the attachments — item shape: {instructions?: string, name: string, required?: bool, signer_index: int}
  --cc-email-addresses: list # The email addresses that should be CCed.
  client_id: string # Client id of the app used to create the draft. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # When used together with merge fields, `custom_fields` allows users to add pre-filled data to their signature requests.  Pre-filled data can be used with "send-once" signature requests by adding merge fields with `form_fields_per_document` or [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) while passing values back with `custom_fields` together in one API call.  For using pre-filled on repeatable signature requests, merge fields are added to templates in the Dropbox Sign UI or by calling [/template/create_embedded_draft](/api/reference/operation/templateCreateEmbeddedDraft) and then passing `custom_fields` on subsequent signature requests referencing that template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --editor-options: record # This allows the requester to specify editor options when a preparing a document — shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --force-signer-page: oneof<nothing, bool> # Provide users the ability to review/edit the signers. (default: false)
  --force-subject-message: oneof<nothing, bool> # Provide users the ability to review/edit the subject and message. (default: false)
  --form-field-groups: list # Group information for fields defined in `form_fields_per_document`. String-indexed JSON array with `group_label` and `requirement` keys. `form_fields_per_document` must contain fields referencing a group defined in `form_field_groups`. — item shape: {group_id: string, group_label: string, requirement: string}
  --form-field-rules: list # Conditional Logic rules for fields defined in `form_fields_per_document`. — item shape: {id: string, trigger_operator: string, triggers: list, actions: list}
  --form-fields-per-document: list # The fields that should appear on the document, expressed as an array of objects. (For more details you can read about it here: [Using Form Fields per Document](/docs/openapi/form-fields-per-document).)  **NOTE:** Fields like **text**, **dropdown**, **checkbox**, **radio**, and **hyperlink** have additional required and optional parameters. Check out the list of [additional parameters](/api/reference/constants/#form-fields-per-document) for these field types.  * Text Field use `SubFormFieldsPerDocumentText` * Dropdown Field use `SubFormFieldsPerDocumentDropdown` * Hyperlink Field use `SubFormFieldsPerDocumentHyperlink` * Checkbox Field use `SubFormFieldsPerDocumentCheckbox` * Radio Field use `SubFormFieldsPerDocumentRadio` * Signature Field use `SubFormFieldsPerDocumentSignature` * Date Signed Field use `SubFormFieldsPerDocumentDateSigned` * Initials Field use `SubFormFieldsPerDocumentInitials` * Text Merge Field use `SubFormFieldsPerDocumentTextMerge` * Checkbox Merge Field use `SubFormFieldsPerDocumentCheckboxMerge` — item shape: {document_index: int, api_id: string, height: int, name?: string, page?: int, required: bool, signer: string, type: "text"|"dropdown"|"hyperlink"|"checkbox"|"radio"|"signature"|"date_signed"|"initials"|"text-merge"|"checkbox-merge", width: int, x: int, y: int}
  --hide-text-tags: oneof<nothing, bool> # Send with a value of `true` if you wish to enable automatic Text Tag removal. Defaults to `false`. When using Text Tags it is preferred that you set this to `false` and hide your tags with white text or something similar because the automatic removal system can cause unwanted clipping. See the [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) walkthrough for more details. (default: false)
  --hold-request: oneof<nothing, bool> # The request from this draft will not automatically send to signers post-claim if set to `true`. Requester must [release](/api/reference/operation/signatureRequestReleaseHold/) the request from hold when ready to send. Defaults to `false`. (default: false)
  --is-for-embedded-signing: oneof<nothing, bool> # The request created from this draft will also be signable in embedded mode if set to `true`. Defaults to `false`. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  requester_email_address: string # The email address of the user that should be designated as the requester of this draft, if the draft type is `request_signature`. (format: email)
  --requesting-redirect-url: string # The URL you want signers redirected to after they successfully request a signature.
  --show-preview: oneof<nothing, bool> # This allows the requester to enable the editor/preview experience.  - `show_preview=true`: Allows requesters to enable the editor/preview experience. - `show_preview=false`: Allows requesters to disable the editor/preview experience.
  --show-progress-stepper: oneof<nothing, bool> # When only one step remains in the signature request process and this parameter is set to `false` then the progress stepper will be hidden. (default: true)
  --signers: list # Add Signers to your Unclaimed Draft Signature Request. — item shape: {email_address: string, name: string, order?: int}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --skip-me-now: oneof<nothing, bool> # Disables the "Me (Now)" option for the person preparing the document. Does not work with type `send_document`. Defaults to `false`. (default: false)
  --subject: string # The subject in the email that will be sent to the signers.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --type: string@type-completer # The type of the draft. By default this is `request_signature`, but you can set it to `send_document` if you want to self sign a document and download it. (default: request_signature)
  --use-preexisting-fields: oneof<nothing, bool> # Set `use_text_tags` to `true` to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document (defaults to disabled, or `false`). Alternatively, if your PDF contains pre-defined fields, enable the detection of these fields by setting the `use_preexisting_fields` to `true` (defaults to disabled, or `false`). Currently we only support use of either `use_text_tags` or `use_preexisting_fields` parameter, not both. (default: false)
  --use-text-tags: oneof<nothing, bool> # Set `use_text_tags` to `true` to enable [Text Tags](https://app.hellosign.com/api/textTagsWalkthrough#TextTagIntro) parsing in your document (defaults to disabled, or `false`). Alternatively, if your PDF contains pre-defined fields, enable the detection of these fields by setting the `use_preexisting_fields` to `true` (defaults to disabled, or `false`). Currently we only support use of either `use_text_tags` or `use_preexisting_fields` parameter, not both. (default: false)
  --populate-auto-fill-fields: oneof<nothing, bool> # Controls whether [auto fill fields](https://faq.hellosign.com/hc/en-us/articles/360051467511-Auto-Fill-Fields) can automatically populate a signer's information during signing.  **NOTE:** Keep your signer's information safe by ensuring that the _signer on your signature request is the intended party_ before using this feature. (default: false)
  --expires-at: int # When the signature request will expire. Unsigned signatures will be moved to the expired status, and no longer signable. See [Signature Request Expiration Date](https://developers.hellosign.com/docs/signature-request/expiration/) for details.  **NOTE:** This does not correspond to the **expires_at** returned in the response. (nullable)
]: any -> record<unclaimed_draft: record<signature_request_id: string, claim_url: string, signing_redirect_url: string, requesting_redirect_url: string, expires_at: int, test_mode: bool>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unclaimed_draft/create_embedded")
  let body = {files: $files, file_urls: $file_urls, allow_ccs: $allow_ccs, allow_decline: $allow_decline, allow_reassign: $allow_reassign, attachments: $attachments, cc_email_addresses: $cc_email_addresses, client_id: $client_id, custom_fields: $custom_fields, editor_options: $editor_options, field_options: $field_options, force_signer_page: $force_signer_page, force_subject_message: $force_subject_message, form_field_groups: $form_field_groups, form_field_rules: $form_field_rules, form_fields_per_document: $form_fields_per_document, hide_text_tags: $hide_text_tags, hold_request: $hold_request, is_for_embedded_signing: $is_for_embedded_signing, message: $message, metadata: $metadata, requester_email_address: $requester_email_address, requesting_redirect_url: $requesting_redirect_url, show_preview: $show_preview, show_progress_stepper: $show_progress_stepper, signers: $signers, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, skip_me_now: $skip_me_now, subject: $subject, test_mode: $test_mode, type: $type, use_preexisting_fields: $use_preexisting_fields, use_text_tags: $use_text_tags, populate_auto_fill_fields: $populate_auto_fill_fields, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Embedded Unclaimed Draft with Template
#
# POST /unclaimed_draft/create_embedded_with_template
# operationId: unclaimedDraftCreateEmbeddedWithTemplate
# --ccs item shape: {role: string, email_address: string}
# --custom_fields item shape: {editor?: string, name: string, required?: bool, value?: string}
# --editor_options shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
# --field_options shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
# --signers item shape: {role: string, name: string, email_address: string}
# --signing_options shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
export def "unclaimed-draft-create-embedded-with-template unclaimedDraftCreateEmbeddedWithTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allow-decline: oneof<nothing, bool> # Allows signers to decline to sign a document if `true`. Defaults to `false`. (default: false)
  --allow-reassign: oneof<nothing, bool> # Allows signers to reassign their signature requests to other signers if set to `true`. Defaults to `false`.  **NOTE:** Only available for Premium plan and higher. (default: false)
  --ccs: list # Add CC email recipients. Required when a CC role exists for the Template. — item shape: {role: string, email_address: string}
  client_id: string # Client id of the app used to create the draft. Used to apply the branding and callback url defined for the app.
  --custom-fields: list # An array defining values and options for custom fields. Required when a custom field exists in the Template. — item shape: {editor?: string, name: string, required?: bool, value?: string}
  --editor-options: record # This allows the requester to specify editor options when a preparing a document — shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
  --field-options: record # This allows the requester to specify field options for a signature request. — shape: {date_format: "MM / DD / YYYY"|"MM - DD - YYYY"|"DD / MM / YYYY"|"DD - MM - YYYY"|"YYYY / MM / DD"|"YYYY - MM - DD"}
  --files: list # Use `files[]` to append additional files to the signature request being created from the template. Dropbox Sign will parse the files for [text tags](https://app.hellosign.com/api/textTagsWalkthrough) and append it to the signature request. Text tags for signers not on the template(s) will be ignored.  **files** or **file_urls[]** is required, but not both.
  --file-urls: list # Use file_urls[] to append additional files to the signature request being created from the template. Dropbox Sign will download the file, then parse it for [text tags](https://app.hellosign.com/api/textTagsWalkthrough), and append to the signature request. Text tags for signers not on the template(s) will be ignored.  **files** or **file_urls[]** is required, but not both.
  --force-signer-roles: oneof<nothing, bool> # Provide users the ability to review/edit the template signer roles. (default: false)
  --force-subject-message: oneof<nothing, bool> # Provide users the ability to review/edit the template subject and message. (default: false)
  --hold-request: oneof<nothing, bool> # The request from this draft will not automatically send to signers post-claim if set to 1. Requester must [release](/api/reference/operation/signatureRequestReleaseHold/) the request from hold when ready to send. Defaults to `false`. (default: false)
  --is-for-embedded-signing: oneof<nothing, bool> # The request created from this draft will also be signable in embedded mode if set to `true`. Defaults to `false`. (default: false)
  --message: string # The custom message in the email that will be sent to the signers.
  --metadata: record # Key-value data that should be attached to the signature request. This metadata is included in all API responses and events involving the signature request. For example, use the metadata field to store a signer's order number for look up when receiving events for the signature request.  Each request can include up to 10 metadata keys (or 50 nested metadata keys), with key names up to 40 characters long and values up to 1000 characters long.
  --preview-only: oneof<nothing, bool> # This allows the requester to enable the preview experience (i.e. does not allow the requester's end user to add any additional fields via the editor).  - `preview_only=true`: Allows requesters to enable the preview only experience. - `preview_only=false`: Allows requesters to disable the preview only experience.  **NOTE:** This parameter overwrites `show_preview=1` (if set). (default: false)
  requester_email_address: string # The email address of the user that should be designated as the requester of this draft. (format: email)
  --requesting-redirect-url: string # The URL you want signers redirected to after they successfully request a signature.
  --show-preview: oneof<nothing, bool> # This allows the requester to enable the editor/preview experience.  - `show_preview=true`: Allows requesters to enable the editor/preview experience. - `show_preview=false`: Allows requesters to disable the editor/preview experience. (default: false)
  --show-progress-stepper: oneof<nothing, bool> # When only one step remains in the signature request process and this parameter is set to `false` then the progress stepper will be hidden. (default: true)
  --signers: list # Add Signers to your Templated-based Signature Request. — item shape: {role: string, name: string, email_address: string}
  --signing-options: record # This allows the requester to specify the types allowed for creating a signature and specify another signing options.  **NOTE:** If `signing_options` are not defined in the request, the allowed types will default to those specified in the account settings.  **NOTE:** If `force_advanced_signature_details` is set, allowed types has to be defined too. — shape: {default_type: "draw"|"phone"|"type"|"upload", draw?: bool, phone?: bool, type?: bool, upload?: bool, force_advanced_signature_details?: bool}
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --skip-me-now: oneof<nothing, bool> # Disables the "Me (Now)" option for the person preparing the document. Does not work with type `send_document`. Defaults to `false`. (default: false)
  --subject: string # The subject in the email that will be sent to the signers.
  template_ids: list # Use `template_ids` to create a SignatureRequest from one or more templates, in the order in which the templates will be used.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
  --title: string # The title you want to assign to the SignatureRequest.
  --populate-auto-fill-fields: oneof<nothing, bool> # Controls whether [auto fill fields](https://faq.hellosign.com/hc/en-us/articles/360051467511-Auto-Fill-Fields) can automatically populate a signer's information during signing.  **NOTE:** Keep your signer's information safe by ensuring that the _signer on your signature request is the intended party_ before using this feature. (default: false)
  --allow-ccs: oneof<nothing, bool> # This allows the requester to specify whether the user is allowed to provide email addresses to CC when claiming the draft. (default: false)
]: any -> record<unclaimed_draft: record<signature_request_id: string, claim_url: string, signing_redirect_url: string, requesting_redirect_url: string, expires_at: int, test_mode: bool>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unclaimed_draft/create_embedded_with_template")
  let body = {allow_decline: $allow_decline, allow_reassign: $allow_reassign, ccs: $ccs, client_id: $client_id, custom_fields: $custom_fields, editor_options: $editor_options, field_options: $field_options, files: $files, file_urls: $file_urls, force_signer_roles: $force_signer_roles, force_subject_message: $force_subject_message, hold_request: $hold_request, is_for_embedded_signing: $is_for_embedded_signing, message: $message, metadata: $metadata, preview_only: $preview_only, requester_email_address: $requester_email_address, requesting_redirect_url: $requesting_redirect_url, show_preview: $show_preview, show_progress_stepper: $show_progress_stepper, signers: $signers, signing_options: $signing_options, signing_redirect_url: $signing_redirect_url, skip_me_now: $skip_me_now, subject: $subject, template_ids: $template_ids, test_mode: $test_mode, title: $title, populate_auto_fill_fields: $populate_auto_fill_fields, allow_ccs: $allow_ccs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Edit and Resend Unclaimed Draft
#
# POST /unclaimed_draft/edit_and_resend/{signature_request_id}
# operationId: unclaimedDraftEditAndResend
# --editor_options shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
export def "unclaimed-draft-edit-and-resend unclaimedDraftEditAndResend" [
  signature_request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # Client id of the app used to create the draft. Used to apply the branding and callback url defined for the app.
  --editor-options: record # This allows the requester to specify editor options when a preparing a document — shape: {allow_edit_signers?: bool, allow_edit_documents?: bool}
  --is-for-embedded-signing: oneof<nothing, bool> # The request created from this draft will also be signable in embedded mode if set to `true`.
  --requester-email-address: string # The email address of the user that should be designated as the requester of this draft. If not set, original requester's email address will be used. (format: email)
  --requesting-redirect-url: string # The URL you want signers redirected to after they successfully request a signature.
  --show-progress-stepper: oneof<nothing, bool> # When only one step remains in the signature request process and this parameter is set to `false` then the progress stepper will be hidden. (default: true)
  --signing-redirect-url: string # The URL you want signers redirected to after they successfully sign.
  --test-mode: oneof<nothing, bool> # Whether this is a test, the signature request created from this draft will not be legally binding if set to `true`. Defaults to `false`. (default: false)
]: any -> record<unclaimed_draft: record<signature_request_id: string, claim_url: string, signing_redirect_url: string, requesting_redirect_url: string, expires_at: int, test_mode: bool>, warnings: table<warning_msg: string, warning_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/unclaimed_draft/edit_and_resend/($signature_request_id)")
  let body = {client_id: $client_id, editor_options: $editor_options, is_for_embedded_signing: $is_for_embedded_signing, requester_email_address: $requester_email_address, requesting_redirect_url: $requesting_redirect_url, show_progress_stepper: $show_progress_stepper, signing_redirect_url: $signing_redirect_url, test_mode: $test_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
