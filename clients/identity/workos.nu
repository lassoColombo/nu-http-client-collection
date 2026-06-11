# Auto-generated client for WorkOS v1.0
# Source: https://raw.githubusercontent.com/workos/openapi-spec/main/spec/open-api-spec.yaml
# Auth: --token flag or $env.WORKOS_TOKEN

const BASE_URL = "https://api.workos.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WORKOS_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.workos.com" "https://api.workos-test.com" "https://auth.workos.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-completer [] { ["asc" "desc" "normal"] }
def type-completer [] { ["generic_otp" "sms" "totp"] }
def assignment-completer [] { ["direct" "indirect"] }
def connection-type-completer [] { ["ADFSSAML" "AdpOidc" "AppleOAuth" "Auth0SAML" "AzureSAML" "BitbucketOAuth" "CasSAML" "ClassLinkSAML" "CleverOIDC" "CloudflareSAML" "CyberArkSAML" "DiscordOAuth" "DuoSAML" "EntraIdOIDC" "GenericOIDC" "GenericSAML" "GitLabOAuth" "GithubOAuth" "GoogleOAuth" "GoogleOIDC" "GoogleSAML" "IntuitOAuth" "JumpCloudSAML" "KeycloakSAML" "LastPassSAML" "LinkedInOAuth" "LoginGovOidc" "MagicLink" "MicrosoftOAuth" "MiniOrangeSAML" "NetIqSAML" "OktaOIDC" "OktaSAML" "OneLoginSAML" "OracleSAML" "PingFederateSAML" "PingOneSAML" "RipplingSAML" "SalesforceOAuth" "SalesforceSAML" "ShibbolethGenericSAML" "ShibbolethSAML" "SimpleSamlPhpSAML" "SlackOAuth" "VMwareSAML" "VercelMarketplaceOAuth" "VercelOAuth" "XeroOAuth"] }
def intent-completer [] { ["audit_logs" "bring_your_own_key" "certificate_renewal" "domain_verification" "dsync" "log_streams" "sso"] }
def auth-method-completer [] { ["Authenticator" "Email_OTP" "Other" "Passkey" "Password" "SMS_OTP" "SSO" "Social"] }
def action-completer [] { ["sign-in" "sign-up"] }
def provider-completer [] { ["AppleOAuth" "BitbucketOAuth" "GitHubOAuth" "GitLabOAuth" "GoogleOAuth" "IntuitOAuth" "LinkedInOAuth" "MicrosoftOAuth" "SalesforceOAuth" "SlackOAuth" "VercelMarketplaceOAuth" "VercelOAuth" "XeroOAuth"] }
def screen-hint-completer [] { ["sign-in" "sign-up"] }
def provider-completer-1 [] { ["AppleOAuth" "BitbucketOAuth" "GitHubOAuth" "GitLabOAuth" "GoogleOAuth" "IntuitOAuth" "LinkedInOAuth" "MicrosoftOAuth" "SalesforceOAuth" "SlackOAuth" "VercelMarketplaceOAuth" "VercelOAuth" "XeroOAuth" "authkit"] }
def locale-completer [] { ["af" "am" "ar" "bg" "bn" "bs" "ca" "cs" "da" "de" "de-DE" "el" "en" "en-AU" "en-CA" "en-GB" "en-US" "es" "es-419" "es-ES" "es-US" "et" "fa" "fi" "fil" "fr" "fr-BE" "fr-CA" "fr-FR" "fy" "gl" "gu" "ha" "he" "hi" "hr" "hu" "hy" "id" "is" "it" "it-IT" "ja" "jv" "ka" "kk" "km" "kn" "ko" "lt" "lv" "mk" "ml" "mn" "mr" "ms" "my" "nb" "ne" "nl" "nl-BE" "nl-NL" "nn" "no" "pa" "pl" "pt" "pt-BR" "pt-PT" "ro" "ru" "sk" "sl" "sq" "sr" "sv" "sw" "ta" "te" "th" "tr" "uk" "ur" "uz" "vi" "zh" "zh-CN" "zh-HK" "zh-TW" "zu"] }
def order-completer-1 [] { ["asc" "desc"] }
def status-completer [] { ["disabled" "enabled"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-keys-validations validateApiKey" } } | get name | first)
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

# Validate API key
#
# POST /api_keys/validations
# operationId: ApiKeysController_validateApiKey
export def "api-keys-validations validateApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # The value for an API key. (e.g. sk_example_1234567890abcdef)
]: any -> record<api_key: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api_keys/validations")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an API key
#
# DELETE /api_keys/{id}
# operationId: ApiKeysController_delete
export def "api-keys delete" [
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
  let full_url = (build-url $base $"/api_keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Expire an API key
#
# POST /api_keys/{id}/expire
# operationId: ApiKeysController_expire
export def "api-keys-expire expire" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-at: string # When the API key should expire. If omitted or in the past, the key expires immediately. Use null to clear a scheduled future expiration. (nullable, format: date-time, e.g. 2030-01-01T00:00:00.000Z)
]: any -> record<object: string, id: string, owner: any, name: string, obfuscated_value: string, last_used_at: string, expires_at: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api_keys/($id)/expire")
  let body = {expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Actions
#
# GET /audit_logs/actions
# operationId: AuditLogValidatorsController_list
export def "audit-logs-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, list_metadata: record<before: string, after: string>, data: table<object: string, name: string, schema: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/audit_logs/actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Schema
#
# POST /audit_logs/actions/{actionName}/schemas
# operationId: AuditLogValidatorVersionsController_create
# --actor shape: {metadata: record}
# --targets item shape: {type: string, metadata?: record}
export def "audit-logs-actions-schemas create" [
  actionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actor: record # shape: {metadata: record}
  targets: list # The list of targets for the schema. — item shape: {type: string, metadata?: record}
  --metadata: record # Optional JSON schema for event metadata. (e.g. {type: object, properties: {transactionId: {type: string}}})
]: any -> record<object: string, version: int, actor: record<metadata: record>, targets: table<type: string, metadata: record>, metadata: record, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audit_logs/actions/($actionName)/schemas")
  let body = {actor: $actor, targets: $targets, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Schemas
#
# GET /audit_logs/actions/{actionName}/schemas
# operationId: AuditLogValidatorVersionsController_schemas
export def "audit-logs-actions-schemas schemas" [
  actionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, list_metadata: record<before: string, after: string>, data: table<object: string, version: int, actor: record, targets: list, metadata: record, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/audit_logs/actions/($actionName)/schemas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Event
#
# POST /audit_logs/events
# operationId: AuditLogEventsController_create
# --event shape: {action: string, occurred_at: string, actor: record, targets: list, context: record, metadata?: record, version?: int}
export def "audit-logs-events create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idempotency-key: string # A unique string to prevent duplicate requests. Each subsequent request matching this unique string will return the same response. We suggest using v4 UUIDs. Keys expire after 24 hours. (e.g. 884793cd-bef4-46cf-8790-e3d4957a09ce)
  organization_id: string # The unique ID of the Organization. (e.g. org_01EHWNCE74X7JSDV0X3SZ3KJNY)
  event: record # shape: {action: string, occurred_at: string, actor: record, targets: list, context: record, metadata?: record, version?: int}
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audit_logs/events")
  let body = {organization_id: $organization_id, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"idempotency-key": $idempotency_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Export
#
# POST /audit_logs/exports
# operationId: AuditLogExportsController_exports
@deprecated --flag actors
export def "audit-logs-exports exports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # The unique ID of the Organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  range_start: string # ISO-8601 value for start of the export range. (e.g. 2022-07-02T18:09:06.996Z)
  range_end: string # ISO-8601 value for end of the export range. (e.g. 2022-09-02T18:09:06.996Z)
  --actions: list # List of actions to filter against. (e.g. [user.signed_in])
  --actors: list # Deprecated. Use `actor_names` instead. (DEPRECATED, e.g. [Jon Smith])
  --actor-names: list # List of actor names to filter against. (e.g. [Jon Smith])
  --actor-ids: list # List of actor IDs to filter against. (e.g. [user_01GBZK5MP7TD1YCFQHFR22180V])
  --targets: list # List of target types to filter against. (e.g. [team])
]: any -> record<object: string, id: string, state: string, url: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/audit_logs/exports")
  let body = {organization_id: $organization_id, range_start: $range_start, range_end: $range_end, actions: $actions, actors: $actors, actor_names: $actor_names, actor_ids: $actor_ids, targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Export
#
# GET /audit_logs/exports/{auditLogExportId}
# operationId: AuditLogExportsController_export
export def "audit-logs-exports export" [
  auditLogExportId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, state: string, url: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/audit_logs/exports/($auditLogExportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Challenge
#
# POST /auth/challenges/{id}/verify
# operationId: AuthenticationChallengesController_verify
export def "auth-challenges-verify verify" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The one-time code to verify. (e.g. 123456)
]: any -> record<challenge: record<object: string, id: string, expires_at: string, code: string, authentication_factor_id: string, created_at: string, updated_at: string>, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/challenges/($id)/verify")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enroll Factor
#
# POST /auth/factors/enroll
# operationId: AuthenticationFactorsController_create
export def "auth-factors-enroll create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # The type of factor to enroll. (e.g. totp)
  --phone-number: string # Required when type is 'sms'. (e.g. +15555555555)
  --totp-issuer: string # Required when type is 'totp'. (e.g. Foo Corp)
  --totp-user: string # Required when type is 'totp'. (e.g. alan.turing@example.com)
  --user-id: string # The ID of the user to associate the factor with. (e.g. user_01E4ZCR3C56J083X43JQXF3JK5)
]: any -> record<object: string, id: string, type: string, user_id: string, sms: record<phone_number: string>, totp: record<issuer: string, user: string, secret: string, qr_code: string, uri: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/factors/enroll")
  let body = {type: $type, phone_number: $phone_number, totp_issuer: $totp_issuer, totp_user: $totp_user, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Factor
#
# GET /auth/factors/{id}
# operationId: AuthenticationFactorsController_get
export def "auth-factors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, type: string, user_id: string, sms: record<phone_number: string>, totp: record<issuer: string, user: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/factors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Factor
#
# DELETE /auth/factors/{id}
# operationId: AuthenticationFactorsController_delete
export def "auth-factors delete" [
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
  let full_url = (build-url $base $"/auth/factors/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Challenge Factor
#
# POST /auth/factors/{id}/challenge
# operationId: AuthenticationFactorsController_challenge
export def "auth-factors-challenge challenge" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sms-template: string # A custom template for the SMS message. Use the {{code}} placeholder to include the verification code. (e.g. Your verification code is {{code}}.)
]: any -> record<object: string, id: string, expires_at: string, code: string, authentication_factor_id: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/auth/factors/($id)/challenge")
  let body = {sms_template: $sms_template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete external authentication
#
# POST /authkit/oauth2/complete
# operationId: ExternalAuthController_completeLogin
# --user shape: {id: string, email: string, first_name?: string, last_name?: string, name?: string, metadata?: record}
# --user_consent_options item shape: {claim: string, type: string, label: string, choices: list}
export def "authkit-oauth2-complete completeLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_auth_id: string # Identifier provided when AuthKit redirected to your login page. (e.g. ext_auth_01HXYZ123456789ABCDEFGHIJ)
  user: record # shape: {id: string, email: string, first_name?: string, last_name?: string, name?: string, metadata?: record}
  --user-consent-options: list # Array of [User Consent Options](/reference/workos-connect/standalone/user-consent-options) to store with the session. — item shape: {claim: string, type: string, label: string, choices: list}
]: any -> record<redirect_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authkit/oauth2/complete")
  let body = {external_auth_id: $external_auth_id, user: $user, user_consent_options: $user_consent_options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check authorization
#
# POST /authorization/organization_memberships/{organization_membership_id}/check
# operationId: AuthorizationController_check
export def "authorization-organization-memberships-check check" [
  organization_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permission_slug: string # The slug of the permission to check. (e.g. posts:create)
]: any -> record<authorized: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/check")
  let body = {permission_slug: $permission_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List resources for organization membership
#
# GET /authorization/organization_memberships/{organization_membership_id}/resources
# operationId: AuthorizationController_listResourcesForMembership
export def "authorization-organization-memberships-resources listResourcesForMembership" [
  organization_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --permission-slug: string # The permission slug to filter by. Only child resources where the organization membership has this permission are returned. (e.g. project:read)
  --parent-resource-id: string # The WorkOS ID of the parent resource. Provide this or both `parent_resource_external_id` and `parent_resource_type_slug`, but not both. Mutually exclusive with `parent_resource_type_slug` and `parent_resource_external_id`. (e.g. authz_resource_01XYZ789)
  --parent-resource-type-slug: string # The slug of the parent resource type. Must be provided together with `parent_resource_external_id`. Required with `parent_resource_external_id`. Mutually exclusive with `parent_resource_id`. (e.g. project)
  --parent-resource-external-id: string # The application-specific external identifier of the parent resource. Must be provided together with `parent_resource_type_slug`. Required with `parent_resource_type_slug`. Mutually exclusive with `parent_resource_id`. (e.g. external_project_123)
]: nothing -> record<object: string, data: table<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "permission_slug" $permission_slug "scalar") (serialize-qp "parent_resource_id" $parent_resource_id "scalar") (serialize-qp "parent_resource_type_slug" $parent_resource_type_slug "scalar") (serialize-qp "parent_resource_external_id" $parent_resource_external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List effective permissions for an organization membership on a resource
#
# GET /authorization/organization_memberships/{organization_membership_id}/resources/{resource_id}/permissions
# operationId: AuthorizationController_listEffectivePermissions
export def "authorization-organization-memberships-resources-permissions listEffectivePermissions" [
  organization_membership_id: string
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, slug: string, name: string, description: string, system: bool, resource_type_slug: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/resources/($resource_id)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List effective permissions for an organization membership on a resource by external ID
#
# GET /authorization/organization_memberships/{organization_membership_id}/resources/{resource_type_slug}/{external_id}/permissions
# operationId: AuthorizationController_listEffectivePermissionsByExternalId
export def "authorization-organization-memberships-resources-permissions listEffectivePermissionsByExternalId" [
  organization_membership_id: string
  resource_type_slug: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, slug: string, name: string, description: string, system: bool, resource_type_slug: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/resources/($resource_type_slug)/($external_id)/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List role assignments
#
# GET /authorization/organization_memberships/{organization_membership_id}/role_assignments
# operationId: AuthorizationRoleAssignmentsController_listRoleAssignments
export def "authorization-organization-memberships-role-assignments listRoleAssignments" [
  organization_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --resource-id: string # Filter assignments by the ID of the resource. (e.g. authz_resource_01HXYZ123456789ABCDEFGH)
  --resource-external-id: string # Filter assignments by the external ID of the resource. (e.g. project-ext-456)
  --resource-type-slug: string # Filter assignments by the slug of the resource type. (e.g. project)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_membership_id: string, role: record, resource: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "resource_id" $resource_id "scalar") (serialize-qp "resource_external_id" $resource_external_id "scalar") (serialize-qp "resource_type_slug" $resource_type_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/role_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign a role
#
# POST /authorization/organization_memberships/{organization_membership_id}/role_assignments
# operationId: AuthorizationRoleAssignmentsController_assignRole
export def "authorization-organization-memberships-role-assignments assignRole" [
  organization_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_slug: string # The slug of the role to assign. (e.g. editor)
]: any -> record<object: string, id: string, organization_membership_id: string, role: record<slug: string>, resource: record<id: string, external_id: string, resource_type_slug: string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/role_assignments")
  let body = {role_slug: $role_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a role assignment
#
# DELETE /authorization/organization_memberships/{organization_membership_id}/role_assignments
# operationId: AuthorizationRoleAssignmentsController_removeRoleByCriteria
export def "authorization-organization-memberships-role-assignments removeRoleByCriteria" [
  organization_membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role_slug: string # The slug of the role to remove. (e.g. editor)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/role_assignments")
  let body = {role_slug: $role_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a role assignment by ID
#
# DELETE /authorization/organization_memberships/{organization_membership_id}/role_assignments/{role_assignment_id}
# operationId: AuthorizationRoleAssignmentsController_removeRoleById
export def "authorization-organization-memberships-role-assignments removeRoleById" [
  organization_membership_id: string
  role_assignment_id: string
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
  let full_url = (build-url $base $"/authorization/organization_memberships/($organization_membership_id)/role_assignments/($role_assignment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom role
#
# POST /authorization/organizations/{organizationId}/roles
# operationId: AuthorizationOrganizationRolesController_create
export def "authorization-organizations-roles create" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # A unique identifier for the role within the organization. When provided, must begin with 'org-' and contain only lowercase letters, numbers, hyphens, and underscores. When omitted, a slug is auto-generated from the role name and a random suffix. (e.g. org-billing-admin)
  name: string # A descriptive name for the role. (e.g. Billing Administrator)
  --description: string # An optional description of the role's purpose. (nullable, e.g. Can manage billing and invoices)
  --resource-type-slug: string # The slug of the resource type the role is scoped to. (e.g. organization)
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles")
  let body = {slug: $slug, name: $name, description: $description, resource_type_slug: $resource_type_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List custom roles
#
# GET /authorization/organizations/{organizationId}/roles
# operationId: AuthorizationOrganizationRolesController_list
export def "authorization-organizations-roles list" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, data: table<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a custom role
#
# GET /authorization/organizations/{organizationId}/roles/{slug}
# operationId: AuthorizationOrganizationRolesController_get
export def "authorization-organizations-roles get" [
  organizationId: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom role
#
# PATCH /authorization/organizations/{organizationId}/roles/{slug}
# operationId: AuthorizationOrganizationRolesController_update
export def "authorization-organizations-roles update" [
  organizationId: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A descriptive name for the role. (e.g. Finance Administrator)
  --description: string # An optional description of the role's purpose. (nullable, e.g. Can manage all financial operations)
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles/($slug)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom role
#
# DELETE /authorization/organizations/{organizationId}/roles/{slug}
# operationId: AuthorizationOrganizationRolesController_delete
export def "authorization-organizations-roles delete" [
  organizationId: string
  slug: string
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
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set permissions for a custom role
#
# PUT /authorization/organizations/{organizationId}/roles/{slug}/permissions
# operationId: AuthorizationOrganizationRolePermissionsController_setPermissions
export def "authorization-organizations-roles-permissions setPermissions" [
  organizationId: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # The permission slugs to assign to the role. (e.g. [billing:read, billing:write, invoices:manage, reports:view])
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles/($slug)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a permission to a custom role
#
# POST /authorization/organizations/{organizationId}/roles/{slug}/permissions
# operationId: AuthorizationOrganizationRolePermissionsController_addPermission
export def "authorization-organizations-roles-permissions addPermission" [
  organizationId: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-slug: string # The slug of the permission to add to the role. (e.g. reports:export)
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles/($slug)/permissions")
  let body = {slug: $body_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a permission from a custom role
#
# DELETE /authorization/organizations/{organizationId}/roles/{slug}/permissions/{permissionSlug}
# operationId: AuthorizationOrganizationRolePermissionsController_removePermission
export def "authorization-organizations-roles-permissions removePermission" [
  organizationId: string
  slug: string
  permissionSlug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organizationId)/roles/($slug)/permissions/($permissionSlug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a resource by external ID
#
# GET /authorization/organizations/{organization_id}/resources/{resource_type_slug}/{external_id}
# operationId: AuthorizationResourcesByExternalIdController_getByExternalId
export def "authorization-organizations-resources get" [
  organization_id: string
  resource_type_slug: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organization_id)/resources/($resource_type_slug)/($external_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a resource by external ID
#
# PATCH /authorization/organizations/{organization_id}/resources/{resource_type_slug}/{external_id}
# operationId: AuthorizationResourcesByExternalIdController_updateByExternalId
export def "authorization-organizations-resources updateByExternalId" [
  organization_id: string
  resource_type_slug: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A display name for the resource. (e.g. Updated Name)
  --description: string # An optional description of the resource. (nullable, e.g. Updated description)
]: any -> record<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/organizations/($organization_id)/resources/($resource_type_slug)/($external_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an authorization resource by external ID
#
# DELETE /authorization/organizations/{organization_id}/resources/{resource_type_slug}/{external_id}
# operationId: AuthorizationResourcesByExternalIdController_deleteByExternalId
export def "authorization-organizations-resources delete" [
  organization_id: string
  resource_type_slug: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cascade-delete: string@bool-completer # If true, deletes all descendant resources and role assignments. If not set and the resource has children or assignments, the request will fail. (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade_delete" $cascade_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organizations/($organization_id)/resources/($resource_type_slug)/($external_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List memberships for a resource by external ID
#
# GET /authorization/organizations/{organization_id}/resources/{resource_type_slug}/{external_id}/organization_memberships
# operationId: AuthorizationResourcesByExternalIdController_listOrganizationMembershipsForResourceByExternalId
export def "authorization-organizations-resources-organization-memberships listOrganizationMembershipsForResourceByExternalId" [
  organization_id: string
  resource_type_slug: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --permission-slug: string # The permission slug to filter by. Only users with this permission on the resource are returned. (e.g. project:read)
  --assignment: string@assignment-completer # Filter by assignment type. Use "direct" for direct assignments only, or "indirect" to include inherited assignments. (e.g. direct)
]: nothing -> record<object: string, data: table<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, user: record>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "permission_slug" $permission_slug "scalar") (serialize-qp "assignment" $assignment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organizations/($organization_id)/resources/($resource_type_slug)/($external_id)/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List role assignments for a resource by external ID
#
# GET /authorization/organizations/{organization_id}/resources/{resource_type_slug}/{external_id}/role_assignments
# operationId: AuthorizationRoleAssignmentsController_listRoleAssignmentsForResourceByExternalId
export def "authorization-organizations-resources-role-assignments listRoleAssignmentsForResourceByExternalId" [
  organization_id: string
  resource_type_slug: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --role-slug: string # Filter assignments by the slug of the role. (e.g. editor)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_membership_id: string, role: record, resource: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "role_slug" $role_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/organizations/($organization_id)/resources/($resource_type_slug)/($external_id)/role_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List permissions
#
# GET /authorization/permissions
# operationId: AuthorizationPermissionsController_list
export def "authorization-permissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, slug: string, name: string, description: string, system: bool, resource_type_slug: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a permission
#
# POST /authorization/permissions
# operationId: AuthorizationPermissionsController_create
export def "authorization-permissions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string # A unique key to reference the permission. Must be lowercase and contain only letters, numbers, hyphens, underscores, colons, periods, and asterisks. (e.g. documents:read)
  name: string # A descriptive name for the Permission. (e.g. View Documents)
  --description: string # An optional description of the Permission. (nullable, e.g. Allows viewing document contents)
  --resource-type-slug: string # The slug of the resource type this permission is scoped to. (e.g. document)
]: any -> record<object: string, id: string, slug: string, name: string, description: string, system: bool, resource_type_slug: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorization/permissions")
  let body = {slug: $slug, name: $name, description: $description, resource_type_slug: $resource_type_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a permission
#
# GET /authorization/permissions/{slug}
# operationId: AuthorizationPermissionsController_find
export def "authorization-permissions find" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, slug: string, name: string, description: string, system: bool, resource_type_slug: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/permissions/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a permission
#
# PATCH /authorization/permissions/{slug}
# operationId: AuthorizationPermissionsController_update
export def "authorization-permissions update" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A descriptive name for the Permission. (e.g. View Documents)
  --description: string # An optional description of the Permission. (nullable, e.g. Allows viewing document contents)
]: any -> record<object: string, id: string, slug: string, name: string, description: string, system: bool, resource_type_slug: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/permissions/($slug)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a permission
#
# DELETE /authorization/permissions/{slug}
# operationId: AuthorizationPermissionsController_delete
export def "authorization-permissions delete" [
  slug: string
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
  let full_url = (build-url $base $"/authorization/permissions/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List resources
#
# GET /authorization/resources
# operationId: AuthorizationResourcesController_list
export def "authorization-resources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --organization-id: string # Filter resources by organization ID. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --resource-type-slug: string # Filter resources by resource type slug. (e.g. project)
  --resource-external-id: string # Filter resources by external ID. (e.g. my-project-123)
  --parent-resource-id: string # Filter resources by parent resource ID. Mutually exclusive with `parent_resource_type_slug` and `parent_external_id`. (e.g. authz_resource_01HXYZ123456789ABCDEFGHIJ)
  --parent-resource-type-slug: string # Filter resources by parent resource type slug. Required with `parent_external_id`. Mutually exclusive with `parent_resource_id`. (e.g. workspace)
  --parent-external-id: string # Filter resources by parent external ID. Required with `parent_resource_type_slug`. Mutually exclusive with `parent_resource_id`. (e.g. ext-workspace-123)
]: nothing -> record<object: string, data: table<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "resource_type_slug" $resource_type_slug "scalar") (serialize-qp "resource_external_id" $resource_external_id "scalar") (serialize-qp "parent_resource_id" $parent_resource_id "scalar") (serialize-qp "parent_resource_type_slug" $parent_resource_type_slug "scalar") (serialize-qp "parent_external_id" $parent_external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an authorization resource
#
# POST /authorization/resources
# operationId: AuthorizationResourcesController_create
export def "authorization-resources create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_id: string # An external identifier for the resource. (e.g. my-workspace-01)
  name: string # A display name for the resource. (e.g. Acme Workspace)
  --description: string # An optional description of the resource. (nullable, e.g. Primary workspace for the Acme team)
  resource_type_slug: string # The slug of the resource type. (e.g. workspace)
  organization_id: string # The ID of the organization this resource belongs to. (e.g. org_01EHQMYV6MBK39QC5PZXHY59C3)
]: any -> record<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorization/resources")
  let body = {external_id: $external_id, name: $name, description: $description, resource_type_slug: $resource_type_slug, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a resource
#
# GET /authorization/resources/{resource_id}
# operationId: AuthorizationResourcesController_findById
export def "authorization-resources findById" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/resources/($resource_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a resource
#
# PATCH /authorization/resources/{resource_id}
# operationId: AuthorizationResourcesController_update
export def "authorization-resources update" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A display name for the resource. (e.g. Updated Name)
  --description: string # An optional description of the resource. (nullable, e.g. Updated description)
]: any -> record<object: string, name: string, description: string, organization_id: string, parent_resource_id: string, id: string, external_id: string, resource_type_slug: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/resources/($resource_id)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an authorization resource
#
# DELETE /authorization/resources/{resource_id}
# operationId: AuthorizationResourcesController_delete
export def "authorization-resources delete" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cascade-delete: string@bool-completer # If true, deletes all descendant resources and role assignments. If not set and the resource has children or assignments, the request will fail. (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade_delete" $cascade_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/resources/($resource_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization memberships for resource
#
# GET /authorization/resources/{resource_id}/organization_memberships
# operationId: AuthorizationResourcesController_listOrganizationMembershipsForResource
export def "authorization-resources-organization-memberships listOrganizationMembershipsForResource" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --permission-slug: string # The permission slug to filter by. Only users with this permission on the resource are returned. (e.g. document:edit)
  --assignment: string@assignment-completer # Filter by assignment type. Use `direct` for direct assignments only, or `indirect` to include inherited assignments. (e.g. direct)
]: nothing -> record<object: string, data: table<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, user: record>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "permission_slug" $permission_slug "scalar") (serialize-qp "assignment" $assignment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/resources/($resource_id)/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List role assignments for a resource
#
# GET /authorization/resources/{resource_id}/role_assignments
# operationId: AuthorizationRoleAssignmentsController_listRoleAssignmentsForResource
export def "authorization-resources-role-assignments listRoleAssignmentsForResource" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --role-slug: string # Filter assignments by the slug of the role. (e.g. editor)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_membership_id: string, role: record, resource: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "role_slug" $role_slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/authorization/resources/($resource_id)/role_assignments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an environment role
#
# POST /authorization/roles
# operationId: AuthorizationRolesController_create
export def "authorization-roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string # A unique slug for the role. (e.g. editor)
  name: string # A descriptive name for the role. (e.g. Editor)
  --description: string # An optional description of the role. (nullable, e.g. Can edit resources)
  --resource-type-slug: string # The slug of the resource type the role is scoped to. (e.g. organization)
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorization/roles")
  let body = {slug: $slug, name: $name, description: $description, resource_type_slug: $resource_type_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List environment roles
#
# GET /authorization/roles
# operationId: AuthorizationRolesController_list
export def "authorization-roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, data: table<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authorization/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an environment role
#
# GET /authorization/roles/{slug}
# operationId: AuthorizationRolesController_get
export def "authorization-roles get" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/roles/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an environment role
#
# PATCH /authorization/roles/{slug}
# operationId: AuthorizationRolesController_update
export def "authorization-roles update" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # A descriptive name for the role. (e.g. Super Administrator)
  --description: string # An optional description of the role. (nullable, e.g. Full administrative access to all resources)
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/roles/($slug)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set permissions for an environment role
#
# PUT /authorization/roles/{slug}/permissions
# operationId: AuthorizationRolePermissionsController_setPermissions
export def "authorization-roles-permissions setPermissions" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  permissions: list # The permission slugs to assign to the role. (e.g. [billing:read, billing:write, invoices:manage, reports:view])
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/roles/($slug)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a permission to an environment role
#
# POST /authorization/roles/{slug}/permissions
# operationId: AuthorizationRolePermissionsController_addPermission
export def "authorization-roles-permissions addPermission" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-slug: string # The slug of the permission to add to the role. (e.g. reports:export)
]: any -> record<slug: string, object: string, id: string, name: string, description: string, type: string, resource_type_slug: string, permissions: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/authorization/roles/($slug)/permissions")
  let body = {slug: $body_slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Connect Applications
#
# GET /connect/applications
# operationId: ApplicationsController_list
export def "connect-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --organization-id: string # Filter Connect Applications by organization ID. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: nothing -> record<object: string, data: table<object: string, id: string, client_id: string, description: string, name: string, scopes: list, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connect/applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Connect Application
#
# POST /connect/applications
# operationId: ApplicationsController_create
# --redirect_uris item shape: {uri: string, default?: bool}
export def "connect-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the application. (e.g. My Application)
  --application-type: string # The type of application to create.
  --description: string # A description for the application. (nullable, e.g. An application for managing user access)
  --scopes: list # The OAuth scopes granted to the application. (nullable, e.g. [openid, profile, email])
  --redirect-uris: list # Redirect URIs for the application. (nullable, e.g. [{uri: https://example.com/callback, default: true}]) — item shape: {uri: string, default?: bool}
  --uses-pkce: string@bool-completer # Whether the application uses PKCE (Proof Key for Code Exchange). (nullable, e.g. true)
  --is-first-party: string@bool-completer # Whether this is a first-party application. Third-party applications require an organization_id. (e.g. true)
  --organization-id: string # The organization ID this application belongs to. Required when is_first_party is false. (nullable, e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: any -> record<object: string, id: string, client_id: string, description: string, name: string, scopes: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/connect/applications")
  let body = {name: $name, application_type: $application_type, description: $description, scopes: $scopes, redirect_uris: $redirect_uris, uses_pkce: $uses_pkce, is_first_party: $is_first_party, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Connect Application
#
# GET /connect/applications/{id}
# operationId: ApplicationsController_find
export def "connect-applications find" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, client_id: string, description: string, name: string, scopes: list<string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connect/applications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Connect Application
#
# PUT /connect/applications/{id}
# operationId: ApplicationsController_update
# --redirect_uris item shape: {uri: string, default?: bool}
export def "connect-applications update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the application. (e.g. My Application)
  --description: string # A description for the application. (nullable, e.g. An application for managing user access)
  --scopes: list # The OAuth scopes granted to the application. (nullable, e.g. [openid, profile, email])
  --redirect-uris: list # Updated redirect URIs for the application. OAuth applications only. (nullable, e.g. [{uri: https://example.com/callback, default: true}]) — item shape: {uri: string, default?: bool}
]: any -> record<object: string, id: string, client_id: string, description: string, name: string, scopes: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connect/applications/($id)")
  let body = {name: $name, description: $description, scopes: $scopes, redirect_uris: $redirect_uris} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Connect Application
#
# DELETE /connect/applications/{id}
# operationId: ApplicationsController_delete
export def "connect-applications delete" [
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
  let full_url = (build-url $base $"/connect/applications/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Client Secrets for a Connect Application
#
# GET /connect/applications/{id}/client_secrets
# operationId: ApplicationCredentialsController_list
export def "connect-applications-client-secrets list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<object: string, id: string, secret_hint: string, last_used_at: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connect/applications/($id)/client_secrets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new client secret for a Connect Application
#
# POST /connect/applications/{id}/client_secrets
# operationId: ApplicationCredentialsController_create
export def "connect-applications-client-secrets create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<object: string, id: string, secret_hint: string, last_used_at: string, created_at: string, updated_at: string, secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connect/applications/($id)/client_secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Client Secret
#
# DELETE /connect/client_secrets/{id}
# operationId: ApplicationCredentialsController_delete
export def "connect-client-secrets delete" [
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
  let full_url = (build-url $base $"/connect/client_secrets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Connections
#
# GET /connections
# operationId: ConnectionsController_list
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
  --connection-type: string@connection-type-completer # Filter Connections by their type. (e.g. GithubOAuth)
  --domain: string # Filter Connections by their associated domain. (e.g. foo-corp.com)
  --organization-id: string # Filter Connections by their associated organization. (e.g. org_01EHWNCE74X7JSDV0X3SZ3KJNY)
  --search: string # Searchable text to match against Connection names. (e.g. Foo Corp)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_id: string, connection_type: string, name: string, state: string, status: string, domains: list, options: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "connection_type" $connection_type "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Connection
#
# GET /connections/{id}
# operationId: ConnectionsController_find
export def "connections find" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, organization_id: string, connection_type: string, name: string, state: string, status: string, domains: table<id: string, object: string, domain: string>, options: record<signing_cert: string>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Connection
#
# DELETE /connections/{id}
# operationId: ConnectionsController_delete
export def "connections delete" [
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
  let full_url = (build-url $base $"/connections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get authorization URL
#
# POST /data-integrations/{slug}/authorize
# operationId: DataIntegrationsController_getDataIntegrationAuthorizeUrl
export def "data-integrations-authorize post" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The ID of the user to authorize. (e.g. user_01EHZNVPK3SFK441A1RGBFSHRT)
  --organization-id: string # An organization ID to scope the authorization to a specific organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --return-to: string # The URL to redirect the user to after authorization. (format: uri, e.g. https://example.com/callback)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-integrations/($slug)/authorize")
  let body = {user_id: $user_id, organization_id: $organization_id, return_to: $return_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an access token for a connected account
#
# POST /data-integrations/{slug}/token
# operationId: DataIntegrationsController_getUserlandUserToken
export def "data-integrations-token post" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # A [User](/reference/authkit/user) identifier. (e.g. user_01EHZNVPK3SFK441A1RGBFSHRT)
  --organization-id: string # An [Organization](/reference/organization) identifier. Optional parameter to scope the connection to a specific organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data-integrations/($slug)/token")
  let body = {user_id: $user_id, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Directories
#
# GET /directories
# operationId: DirectoriesController_list
@deprecated --flag domain
export def "directories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
  --organization-id: string # Filter Directories by their associated organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --search: string # Searchable text to match against Directory names. (e.g. Foo Corp)
  --domain: string # Filter Directories by their associated domain. (DEPRECATED, e.g. foo-corp.com)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_id: string, external_key: string, type: string, state: string, name: string, domain: string, metadata: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/directories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Directory
#
# GET /directories/{id}
# operationId: DirectoriesController_find
export def "directories find" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, organization_id: string, external_key: string, type: string, state: string, name: string, domain: string, metadata: record<users: record<active: int, inactive: int>, groups: int>, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directories/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Directory
#
# DELETE /directories/{id}
# operationId: DirectoriesController_deleteDirectory
export def "directories delete" [
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
  let full_url = (build-url $base $"/directories/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Directory Groups
#
# GET /directory_groups
# operationId: DirectoryGroupsController_list
export def "directory-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --directory: string # Unique identifier of the WorkOS Directory. This value can be obtained from the WorkOS dashboard or from the WorkOS API. (e.g. directory_01ECAZ4NV9QMV47GW873HDCX74)
  --user: string # Unique identifier of the WorkOS Directory User. This value can be obtained from the WorkOS API. (e.g. directory_user_01E1JG7J09H96KYP8HM9B0G5SJ)
]: nothing -> record<object: string, data: table<object: string, id: string, idp_id: string, directory_id: string, organization_id: string, name: string, raw_attributes: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "directory" $directory "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/directory_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Directory Group
#
# GET /directory_groups/{id}
# operationId: DirectoryGroupsController_find
export def "directory-groups find" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, idp_id: string, directory_id: string, organization_id: string, name: string, raw_attributes: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directory_groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Directory Users
#
# GET /directory_users
# operationId: DirectoryUsersController_list
export def "directory-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --directory: string # Unique identifier of the WorkOS Directory. This value can be obtained from the WorkOS dashboard or from the WorkOS API. (e.g. directory_01ECAZ4NV9QMV47GW873HDCX74)
  --group: string # Unique identifier of the WorkOS Directory Group. This value can be obtained from the WorkOS API. (e.g. directory_group_01E64QTDNS0EGJ0FMCVY9BWGZT)
]: nothing -> record<object: string, data: table<object: string, id: string, directory_id: string, organization_id: string, idp_id: string, email: string, first_name: string, last_name: string, name: string, emails: list, job_title: string, username: string, state: string, raw_attributes: record, custom_attributes: record, role: record, roles: list, created_at: string, updated_at: string, groups: list>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "directory" $directory "scalar") (serialize-qp "group" $group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/directory_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Directory User
#
# GET /directory_users/{id}
# operationId: DirectoryUsersController_find
export def "directory-users find" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, directory_id: string, organization_id: string, idp_id: string, email: string, first_name: string, last_name: string, name: string, emails: table<primary: bool, type: string, value: string>, job_title: string, username: string, state: string, raw_attributes: record, custom_attributes: record, role: record<slug: string>, roles: table<slug: string>, created_at: string, updated_at: string, groups: table<object: string, id: string, idp_id: string, directory_id: string, organization_id: string, name: string, raw_attributes: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/directory_users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List events
#
# GET /events
# operationId: EventsController_list
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --events: list # Filter events by one or more event types (e.g. `dsync.user.created`). (e.g. [dsync.user.created, dsync.user.updated])
  --range-start: string # ISO-8601 date string to filter events created after this date. (e.g. 2025-01-01T00:00:00Z)
  --range-end: string # ISO-8601 date string to filter events created before this date. (e.g. 2025-12-31T23:59:59Z)
  --organization-id: string # Filter events by the [Organization](/reference/organization) that the event is associated with. (e.g. org_01EHQMYV6MBK39QC5PZXHY59C3)
]: nothing -> record<object: string, data: table<object: string, id: string, event: string, data: record, created_at: string, context: record>, list_metadata: record<after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "events" $events "csv") (serialize-qp "range_start" $range_start "scalar") (serialize-qp "range_end" $range_end "scalar") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List feature flags
#
# GET /feature-flags
# operationId: FeatureFlagsController_list
export def "feature-flags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, slug: string, name: string, description: string, owner: any, tags: list, enabled: bool, default_value: bool, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feature-flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a feature flag
#
# GET /feature-flags/{slug}
# operationId: FeatureFlagsController_findBySlug
export def "feature-flags findBySlug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, slug: string, name: string, description: string, owner: any, tags: list<string>, enabled: bool, default_value: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/feature-flags/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable a feature flag
#
# PUT /feature-flags/{slug}/disable
# operationId: FeatureFlagsController_disableFlag
export def "feature-flags-disable disableFlag" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, slug: string, name: string, description: string, owner: any, tags: list<string>, enabled: bool, default_value: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/feature-flags/($slug)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable a feature flag
#
# PUT /feature-flags/{slug}/enable
# operationId: FeatureFlagsController_enableFlag
export def "feature-flags-enable enableFlag" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, slug: string, name: string, description: string, owner: any, tags: list<string>, enabled: bool, default_value: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/feature-flags/($slug)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a feature flag target
#
# POST /feature-flags/{slug}/targets/{resourceId}
# operationId: FlagTargetsController_createTarget
export def "feature-flags-targets createTarget" [
  resourceId: string
  slug: string
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
  let full_url = (build-url $base $"/feature-flags/($slug)/targets/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a feature flag target
#
# DELETE /feature-flags/{slug}/targets/{resourceId}
# operationId: FlagTargetsController_deleteTarget
export def "feature-flags-targets delete" [
  resourceId: string
  slug: string
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
  let full_url = (build-url $base $"/feature-flags/($slug)/targets/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Organization Domain
#
# POST /organization_domains
# operationId: OrganizationDomainsController_create
export def "organization-domains create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # The domain to add to the organization. (e.g. foo-corp.com)
  organization_id: string # The ID of the organization to add the domain to. (e.g. org_01EHQMYV6MBK39QC5PZXHY59C3)
]: any -> record<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization_domains")
  let body = {domain: $domain, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Organization Domain
#
# GET /organization_domains/{id}
# operationId: OrganizationDomainsController_get
export def "organization-domains get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization_domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Organization Domain
#
# DELETE /organization_domains/{id}
# operationId: OrganizationDomainsController_delete
export def "organization-domains delete" [
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
  let full_url = (build-url $base $"/organization_domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify an Organization Domain
#
# POST /organization_domains/{id}/verify
# operationId: OrganizationDomainsController_verify
export def "organization-domains-verify verify" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization_domains/($id)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Organizations
#
# GET /organizations
# operationId: OrganizationsController_list
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --domains: list # The domains of an Organization. Any Organization with a matching domain will be returned. (e.g. [foo-corp.com])
  --search: string # Searchable text for an Organization. Matches against the organization name. (e.g. Acme Corp)
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, domains: list, metadata: record, external_id: string, stripe_customer_id: string, created_at: string, updated_at: string, allow_profiles_outside_organization: bool>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "domains" $domains "csv") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Organization
#
# POST /organizations
# operationId: OrganizationsController_create
# --domain_data item shape: {domain: string, state: "pending"|"verified"}
export def "organizations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the organization. (e.g. Foo Corp)
  --allow-profiles-outside-organization: string@bool-completer # Whether the organization allows profiles from outside the organization to sign in. (e.g. false)
  --domains: list # The domains associated with the organization. Deprecated in favor of `domain_data`. (e.g. [example.com])
  --domain-data: list # The domains associated with the organization, including verification state. — item shape: {domain: string, state: "pending"|"verified"}
  --metadata: record # Object containing [metadata](/authkit/metadata) key/value pairs associated with the Organization. (nullable, e.g. {tier: diamond})
  --external-id: string # An external identifier for the Organization. (nullable, e.g. ext_12345)
]: any -> record<object: string, id: string, name: string, domains: table<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string>, metadata: record, external_id: string, stripe_customer_id: string, created_at: string, updated_at: string, allow_profiles_outside_organization: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {name: $name, allow_profiles_outside_organization: $allow_profiles_outside_organization, domains: $domains, domain_data: $domain_data, metadata: $metadata, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Organization by External ID
#
# GET /organizations/external_id/{external_id}
# operationId: OrganizationsController_getByExternalId
export def "organizations-external-id get" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: string, domains: table<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string>, metadata: record, external_id: string, stripe_customer_id: string, created_at: string, updated_at: string, allow_profiles_outside_organization: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/external_id/($external_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Organization
#
# GET /organizations/{id}
# operationId: OrganizationsController_find
export def "organizations find" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, name: string, domains: table<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string>, metadata: record, external_id: string, stripe_customer_id: string, created_at: string, updated_at: string, allow_profiles_outside_organization: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an Organization
#
# PUT /organizations/{id}
# operationId: OrganizationsController_updateOrganization
# --domain_data item shape: {domain: string, state: "pending"|"verified"}
@deprecated --flag domains
export def "organizations updateOrganization" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the organization. (e.g. Foo Corp)
  --allow-profiles-outside-organization: string@bool-completer # Whether the organization allows profiles from outside the organization to sign in. (e.g. false)
  --domains: list # The domains associated with the organization. Deprecated in favor of `domain_data`. (DEPRECATED, e.g. [foo-corp.com])
  --domain-data: list # The domains associated with the organization, including verification state. — item shape: {domain: string, state: "pending"|"verified"}
  --stripe-customer-id: string # The Stripe customer ID associated with the organization. (e.g. cus_R9qWAGMQ6nGE7V)
  --metadata: record # Object containing [metadata](/authkit/metadata) key/value pairs associated with the Organization. (nullable, e.g. {tier: diamond})
  --external-id: string # An external identifier for the Organization. (nullable, e.g. 2fe01467-f7ea-4dd2-8b79-c2b4f56d0191)
]: any -> record<object: string, id: string, name: string, domains: table<object: string, id: string, organization_id: string, domain: string, state: string, verification_prefix: string, verification_token: string, verification_strategy: string, created_at: string, updated_at: string>, metadata: record, external_id: string, stripe_customer_id: string, created_at: string, updated_at: string, allow_profiles_outside_organization: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let body = {name: $name, allow_profiles_outside_organization: $allow_profiles_outside_organization, domains: $domains, domain_data: $domain_data, stripe_customer_id: $stripe_customer_id, metadata: $metadata, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Organization
#
# DELETE /organizations/{id}
# operationId: OrganizationsController_deleteOrganization
export def "organizations delete" [
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
  let full_url = (build-url $base $"/organizations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Audit Log Configuration
#
# GET /organizations/{id}/audit_log_configuration
# operationId: OrganizationsController_getAuditLogConfiguration
export def "organizations-audit-log-configuration get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organization_id: string, retention_period_in_days: int, state: string, log_stream: record<id: string, type: string, state: string, last_synced_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/audit_log_configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Retention
#
# GET /organizations/{id}/audit_logs_retention
# operationId: AuditLogsRetentionController_auditLogsRetention
export def "organizations-audit-logs-retention auditLogsRetention" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<retention_period_in_days: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/audit_logs_retention")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Retention
#
# PUT /organizations/{id}/audit_logs_retention
# operationId: AuditLogsRetentionController_updateAuditLogsRetention
export def "organizations-audit-logs-retention updateAuditLogsRetention" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  retention_period_in_days: int # The number of days Audit Log events will be retained. Valid values are `30` and `365`. (e.g. 30)
]: any -> record<retention_period_in_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)/audit_logs_retention")
  let body = {retention_period_in_days: $retention_period_in_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List API keys for an organization
#
# GET /organizations/{organizationId}/api_keys
# operationId: OrganizationApiKeysController_list
export def "organizations-api-keys list" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, owner: record, name: string, obfuscated_value: string, last_used_at: string, expires_at: string, permissions: list, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API key for an organization
#
# POST /organizations/{organizationId}/api_keys
# operationId: OrganizationApiKeysController_create
export def "organizations-api-keys create" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name for the API key. (e.g. Production API Key)
  --permissions: list # The permission slugs to assign to the API key. (e.g. [posts:read, posts:write])
  --expires-at: string # The timestamp when the API key should expire. Must be a future timestamp. If omitted, the key does not expire. (format: date-time, e.g. 2030-01-01T00:00:00.000Z)
]: any -> record<object: string, id: string, owner: record<type: string, id: string>, name: string, obfuscated_value: string, last_used_at: string, expires_at: string, permissions: list<string>, created_at: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/api_keys")
  let body = {name: $name, permissions: $permissions, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List enabled feature flags for an organization
#
# GET /organizations/{organizationId}/feature-flags
# operationId: OrganizationFeatureFlagsController_list
export def "organizations-feature-flags list" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, slug: string, name: string, description: string, owner: any, tags: list, enabled: bool, default_value: bool, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/feature-flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a group
#
# POST /organizations/{organizationId}/groups
# operationId: GroupsController_create
export def "organizations-groups create" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the Group. (e.g. Engineering)
  --description: string # An optional description of the Group. (nullable, e.g. The engineering team)
]: any -> record<object: string, id: string, organization_id: string, name: string, description: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/groups")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List groups
#
# GET /organizations/{organizationId}/groups
# operationId: GroupsController_list
export def "organizations-groups list" [
  organizationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_id: string, name: string, description: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a group
#
# GET /organizations/{organizationId}/groups/{groupId}
# operationId: GroupsController_get
export def "organizations-groups get" [
  organizationId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, organization_id: string, name: string, description: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a group
#
# PATCH /organizations/{organizationId}/groups/{groupId}
# operationId: GroupsController_update
export def "organizations-groups update" [
  organizationId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the Group. (e.g. Engineering)
  --description: string # An optional description of the Group. (nullable, e.g. The engineering team)
]: any -> record<object: string, id: string, organization_id: string, name: string, description: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/groups/($groupId)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a group
#
# DELETE /organizations/{organizationId}/groups/{groupId}
# operationId: GroupsController_delete
export def "organizations-groups delete" [
  organizationId: string
  groupId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a member to a Group
#
# POST /organizations/{organizationId}/groups/{groupId}/organization-memberships
# operationId: GroupMembershipsController_addMember
export def "organizations-groups-organization-memberships addMember" [
  organizationId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_membership_id: string # The ID of the Organization Membership to add to the group. (e.g. om_01HXYZ123456789ABCDEFGHIJ)
]: any -> record<object: string, id: string, organization_id: string, name: string, description: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($organizationId)/groups/($groupId)/organization-memberships")
  let body = {organization_membership_id: $organization_membership_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Group members
#
# GET /organizations/{organizationId}/groups/{groupId}/organization-memberships
# operationId: GroupMembershipsController_listMembers
export def "organizations-groups-organization-memberships listMembers" [
  organizationId: string
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($organizationId)/groups/($groupId)/organization-memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a member from a Group
#
# DELETE /organizations/{organizationId}/groups/{groupId}/organization-memberships/{omId}
# operationId: GroupMembershipsController_removeMember
export def "organizations-groups-organization-memberships removeMember" [
  organizationId: string
  groupId: string
  omId: string
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
  let full_url = (build-url $base $"/organizations/($organizationId)/groups/($groupId)/organization-memberships/($omId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Portal Link
#
# POST /portal/generate_link
# operationId: PortalSessionsController_create
# --intent_options shape: {sso?: record, domain_verification?: record}
export def "portal-generate-link create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-url: string # The URL to go to when an admin clicks on your logo in the Admin Portal. If not specified, the return URL configured on the [Redirects](https://dashboard.workos.com/redirects) page will be used. (e.g. https://example.com/admin-portal/return)
  --success-url: string # The URL to redirect the admin to when they finish setup. If not specified, the success URL configured on the [Redirects](https://dashboard.workos.com/redirects) page will be used. (e.g. https://example.com/admin-portal/success)
  organization: string # An [Organization](/reference/organization) identifier. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --intent: string@intent-completer #        The intent of the Admin Portal.         - `sso` - Launch Admin Portal for creating SSO connections         - `dsync` - Launch Admin Portal for creating Directory Sync connections         - `audit_logs` - Launch Admin Portal for viewing Audit Logs         - `log_streams` - Launch Admin Portal for creating Log Streams         - `domain_verification` - Launch Admin Portal for Domain Verification         - `certificate_renewal` - Launch Admin Portal for renewing SAML Certificates         - `bring_your_own_key` - Launch Admin Portal for configuring Bring Your Own Key (e.g. sso)
  --intent-options: record # shape: {sso?: record, domain_verification?: record}
  --it-contact-emails: list # The email addresses of the IT contacts to grant access to the Admin Portal for the given organization. Accepts up to 20 emails. (e.g. [it-contact@example.com])
]: any -> record<link: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portal/generate_link")
  let body = {return_url: $return_url, success_url: $success_url, organization: $organization, intent: $intent, intent_options: $intent_options, it_contact_emails: $it_contact_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an attempt
#
# POST /radar/attempts
# operationId: RadarStandaloneController_assess
export def "radar-attempts assess" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ip_address: string # The IP address of the request to assess. (e.g. 49.78.240.97)
  user_agent: string # The user agent string of the request to assess. (e.g. Mozilla/5.0)
  email: string # The email address of the user making the request. (format: email, e.g. user@example.com)
  auth_method: string@auth-method-completer # The authentication method being used. (e.g. Password)
  action: string@action-completer # The action being performed. (e.g. sign-in)
]: any -> record<verdict: string, reason: string, attempt_id: string, control: string, blocklist_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/radar/attempts")
  let body = {ip_address: $ip_address, user_agent: $user_agent, email: $email, auth_method: $auth_method, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Radar attempt
#
# PUT /radar/attempts/{id}
# operationId: RadarStandaloneController_updateRadarAttempt
export def "radar-attempts updateRadarAttempt" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --challenge-status: string # Set to `"success"` to mark the challenge as completed. (e.g. success)
  --attempt-status: string # Set to `"success"` to mark the authentication attempt as successful. (e.g. success)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radar/attempts/($id)")
  let body = {challenge_status: $challenge_status, attempt_status: $attempt_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add an entry to a Radar list
#
# POST /radar/lists/{type}/{action}
# operationId: RadarStandaloneController_updateRadarList
export def "radar-lists updateRadarList" [
  type: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entry: string # The value to add to the list. Must match the format of the list type (e.g. a valid IP address for `ip_address`, a valid email for `email`). (e.g. 198.51.100.42)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radar/lists/($type)/($action)")
  let body = {entry: $entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an entry from a Radar list
#
# DELETE /radar/lists/{type}/{action}
# operationId: RadarStandaloneController_deleteRadarListEntry
export def "radar-lists delete" [
  type: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entry: string # The value to remove from the list. Must match an existing entry. (e.g. 198.51.100.42)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radar/lists/($type)/($action)")
  let body = {entry: $entry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initiate SSO
#
# GET /sso/authorize
# operationId: SsoController_authorize
@deprecated --flag domain
export def "sso-authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provider-scopes: list # Additional scopes to request from the identity provider. Applicable when using OAuth or OpenID Connect connections. (e.g. [openid, profile, email])
  --provider-query-params: record # Key/value pairs of query parameters to pass to the OAuth provider. Only applicable when using OAuth connections. (e.g. {hd: example.com, access_type: offline})
  --client-id: string # The unique identifier of the WorkOS environment client. (e.g. client_01HZBC6N1EB1ZY7KG32X)
  --domain: string # Deprecated. Use `connection` or `organization` instead. Used to initiate SSO for a connection by domain. The domain must be associated with a connection in your WorkOS environment. (DEPRECATED, e.g. example.com)
  --provider: string@provider-completer # Used to initiate OAuth authentication with various providers. (e.g. GoogleOAuth)
  --redirect-uri: string # Where to redirect the user after they complete the authentication process. You must use one of the redirect URIs configured via the [Redirects](https://dashboard.workos.com/redirects) page on the dashboard. (format: uri, e.g. https://example.com/callback)
  --response-type: string # The only valid option for the response type parameter is `"code"`.  The `"code"` parameter value initiates an [authorization code grant type](https://tools.ietf.org/html/rfc6749#section-4.1). This grant type allows you to exchange an authorization code for an access token during the redirect that takes place after a user has authenticated with an identity provider. (e.g. code)
  --state: string # An optional parameter that can be used to encode arbitrary information to help restore application state between redirects. If included, the redirect URI received from WorkOS will contain the exact `state` that was passed. (e.g. dj1kUXc0dzlXZ1hjUQ==)
  --connection: string # Used to initiate SSO for a connection. The value should be a WorkOS connection ID.  You can persist the WorkOS connection ID with application user or team identifiers. WorkOS will use the connection indicated by the connection parameter to direct the user to the corresponding IdP for authentication. (e.g. conn_01E4ZCR3C56J083X43JQXF3JK5)
  --organization: string # Used to initiate SSO for an organization. The value should be a WorkOS organization ID.  You can persist the WorkOS organization ID with application user or team identifiers. WorkOS will use the organization ID to determine the appropriate connection and the IdP to direct the user to for authentication. (e.g. org_01EHQMYV6MBK39QC5PZXHY59C3)
  --domain-hint: string # Can be used to pre-fill the domain field when initiating authentication with Microsoft OAuth or with a Google SAML connection type. (e.g. example.com)
  --login-hint: string # Can be used to pre-fill the username/email address field of the IdP sign-in page for the user, if you know their username ahead of time. Currently supported for OAuth, OpenID Connect, Okta, Entra ID, and custom SAML connections. (e.g. user@example.com)
  --nonce: string # A random string generated by the client that is used to mitigate replay attacks. (e.g. abc123def456)
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "provider_scopes" $provider_scopes "csv") (serialize-qp "provider_query_params" $provider_query_params "multi") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "domain" $domain "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "connection" $connection "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "domain_hint" $domain_hint "scalar") (serialize-qp "login_hint" $login_hint "scalar") (serialize-qp "nonce" $nonce "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sso/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get JWKS
#
# GET /sso/jwks/{clientId}
# operationId: SsoController_jsonWebKeySet
export def "sso-jwks jsonWebKeySet" [
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<alg: string, kty: string, use: string, x5c: list, n: string, e: string, kid: string, x5t_S256: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sso/jwks/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logout Redirect
#
# GET /sso/logout
# operationId: SsoController_logout
export def "sso-logout logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # The logout token returned from the [Logout Authorize](/reference/sso/logout/authorize) endpoint. (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwcm9maWxlX2lkIjoicHJvZl8wMUdXUTFHMEgyRk02QVNFRjBIUzEzSENXOS0zMDRrZzAzZyIsImV4cCI6IjE1MTYyMzkwMjIifQ.Wru9Qlnf5DpohtGCKhZU4cVOd3zpiu7QQ-XEX--5A_4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://auth.workos.com")
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sso/logout" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Logout Authorize
#
# POST /sso/logout/authorize
# operationId: SsoController_logoutAuthorize
export def "sso-logout-authorize logoutAuthorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  profile_id: string # The unique ID of the profile to log out. (e.g. prof_01HXYZ123456789ABCDEFGHIJ)
]: any -> record<logout_url: string, logout_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://auth.workos.com")
  let full_url = (build-url $base "/sso/logout/authorize")
  let body = {profile_id: $profile_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a User Profile
#
# GET /sso/profile
# operationId: SsoController_getProfile
export def "sso-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, organization_id: string, connection_id: string, connection_type: string, idp_id: string, email: string, first_name: string, last_name: string, name: string, role: any, roles: any, groups: list<string>, custom_attributes: record, raw_attributes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sso/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Profile and Token
#
# POST /sso/token
# operationId: SsoController_token
export def "sso-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # The client ID of the WorkOS environment. (e.g. client_01HZBC6N1EB1ZY7KG32X)
  --client-secret: string # The client secret of the WorkOS environment. (e.g. sk_example_123456789)
  --code: string # The authorization code received from the authorization callback. (e.g. authorization_code_value)
  --grant-type: string # The grant type for the token request. (e.g. authorization_code)
  client_id: string # The client ID of the WorkOS environment. (e.g. client_01HZBC6N1EB1ZY7KG32X)
  client_secret: string # The client secret of the WorkOS environment. (e.g. sk_example_123456789)
  code: string # The authorization code received from the authorization callback. (e.g. authorization_code_value)
  grant_type: string # The grant type for the token request. (e.g. authorization_code)
]: any -> record<token_type: string, access_token: string, expires_in: int, profile: record<object: string, id: string, organization_id: string, connection_id: string, connection_type: string, idp_id: string, email: string, first_name: string, last_name: string, name: string, role: any, roles: any, groups: list<string>, custom_attributes: record, raw_attributes: record>, oauth_tokens: record<provider: string, refresh_token: string, access_token: string, expires_at: int, scopes: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "grant_type" $grant_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sso/token" $qp)
  let body = {client_id: $client_id, client_secret: $client_secret, code: $code, grant_type: $grant_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /user_management/authenticate
# operationId: UserlandSessionsController_authenticate[0]
export def "user-management-authenticate authenticate0" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # The client ID of the application. (e.g. client_01HXYZ123456789ABCDEFGHIJ)
  --client-secret: string # The client secret of the application. (e.g. sk_test_....)
  --grant-type: string
  --code: string # The authorization code received from the redirect. (e.g. vBqZKaPpsnJlPfXiDqN7b6VTz)
  --code-verifier: string # The PKCE code verifier used to derive the code challenge passed to the authorization URL. (e.g. dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk)
  --invitation-token: string # An invitation token to accept during authentication. (e.g. inv_tok_01HXYZ123456789ABCDEFGHIJ)
  --ip-address: string # The IP address of the user's request. (e.g. 203.0.113.42)
  --device-id: string # A unique identifier for the device. (e.g. device_01HXYZ123456789ABCDEFGHIJ)
  --user-agent: string # The user agent string from the user's browser. (e.g. Mozilla/5.0)
  --email: string # The user's email address. (e.g. user@example.com)
  --password: string # The user's password. (e.g. strong_password_123!)
  --refresh-token: string # The refresh token to exchange for new tokens. (e.g. yAjhKk23hJMM3DaR...)
  --organization-id: string # The ID of the organization to scope the session to. (e.g. org_01EHQMYV6MBK39QC5PZXHY59C3)
  --pending-authentication-token: string # The pending authentication token from a previous authentication attempt. (e.g. cTDQJTTkTkkVYxbn...)
  --authentication-challenge-id: string # The ID of the MFA authentication challenge. (e.g. auth_challenge_01HXYZ123456789ABCDEFGHIJ)
  --device-code: string # The device verification code. (e.g. Ao4fMrDS...)
]: any -> record<user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>, organization_id: string, authkit_authorization_code: string, access_token: string, refresh_token: string, authentication_method: string, impersonator: record<email: string, reason: string>, oauth_tokens: record<provider: string, refresh_token: string, access_token: string, expires_at: int, scopes: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/authenticate")
  let body = {client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, code: $code, code_verifier: $code_verifier, invitation_token: $invitation_token, ip_address: $ip_address, device_id: $device_id, user_agent: $user_agent, email: $email, password: $password, refresh_token: $refresh_token, organization_id: $organization_id, pending_authentication_token: $pending_authentication_token, authentication_challenge_id: $authentication_challenge_id, device_code: $device_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an authorization URL
#
# GET /user_management/authorize
# operationId: UserlandSsoController_authorize
export def "user-management-authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code-challenge-method: string # The only valid PKCE code challenge method is `"S256"`. Required when specifying a `code_challenge`. (e.g. S256)
  --code-challenge: string # Code challenge derived from the code verifier used for the PKCE flow. (e.g. E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM)
  --domain-hint: string # A domain hint for SSO connection lookup. (e.g. example.com)
  --connection-id: string # The ID of an SSO connection to use for authentication. (e.g. conn_01EHQMYV6MBK39QC5PZXHY59C3)
  --provider-query-params: record # Key/value pairs of query parameters to pass to the OAuth provider. (e.g. {hd: example.com, access_type: offline})
  --provider-scopes: list # Additional OAuth scopes to request from the identity provider. (e.g. [openid, profile, email])
  --invitation-token: string # A token representing a user invitation to redeem during authentication. (e.g. inv_token_abc123)
  --screen-hint: string@screen-hint-completer # Used to specify which screen to display when the provider is `authkit`. (default: sign-in, e.g. sign-in)
  --login-hint: string # A hint to the authorization server about the login identifier the user might use. (e.g. user@example.com)
  --provider: string@provider-completer-1 # The OAuth provider to authenticate with (e.g., GoogleOAuth, MicrosoftOAuth, GitHubOAuth). (e.g. GoogleOAuth)
  --prompt: string # Controls the authentication flow behavior for the user. (e.g. login)
  --state: string # An opaque value used to maintain state between the request and the callback. (e.g. eyJyZXR1cm5UbyI6ICIvZGFzaGJvYXJkIn0=)
  --organization-id: string # The ID of the organization to authenticate the user against. (e.g. org_01EHQMYV6MBK39QC5PZXHY59C3)
  --response-type: string # The response type of the application. (e.g. code)
  --redirect-uri: string # The callback URI where the authorization code will be sent after authentication. (format: uri, e.g. https://example.com/callback)
  --client-id: string # The unique identifier of the WorkOS environment client. (e.g. client_01HZBC6N1EB1ZY7KG32X)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code_challenge_method" $code_challenge_method "scalar") (serialize-qp "code_challenge" $code_challenge "scalar") (serialize-qp "domain_hint" $domain_hint "scalar") (serialize-qp "connection_id" $connection_id "scalar") (serialize-qp "provider_query_params" $provider_query_params "multi") (serialize-qp "provider_scopes" $provider_scopes "csv") (serialize-qp "invitation_token" $invitation_token "scalar") (serialize-qp "screen_hint" $screen_hint "scalar") (serialize-qp "login_hint" $login_hint "scalar") (serialize-qp "provider" $provider "scalar") (serialize-qp "prompt" $prompt "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_management/authorize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get device authorization URL
#
# POST /user_management/authorize/device
# operationId: UserlandSsoController_deviceAuthorization
export def "user-management-authorize-device deviceAuthorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The WorkOS client ID for your application. (e.g. client_01HZBC6N1EB1ZY7KG32X)
]: any -> record<device_code: string, user_code: string, verification_uri: string, verification_uri_complete: string, expires_in: float, interval: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/authorize/device")
  let body = {client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a CORS origin
#
# POST /user_management/cors_origins
# operationId: CorsOriginsController_createCorsOrigin
export def "user-management-cors-origins createCorsOrigin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  origin: string # The origin URL to allow for CORS requests. (e.g. https://example.com)
]: any -> record<object: string, id: string, origin: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/cors_origins")
  let body = {origin: $origin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an email verification code
#
# GET /user_management/email_verification/{id}
# operationId: UserlandUsersController_getEmailVerification
export def "user-management-email-verification get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, user_id: string, email: string, expires_at: string, created_at: string, updated_at: string, code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/email_verification/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List invitations
#
# GET /user_management/invitations
# operationId: UserlandUserInvitesController_list
export def "user-management-invitations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --organization-id: string # The ID of the [organization](/reference/organization) that the recipient will join. (e.g. org_01E4ZCR3C56J083X43JQXF3JK5)
  --email: string # The email address of the recipient. (format: email, e.g. marcelina.davis@example.com)
]: nothing -> record<object: string, list_metadata: record<before: string, after: string>, data: table<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_management/invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send an invitation
#
# POST /user_management/invitations
# operationId: UserlandUserInvitesController_create
export def "user-management-invitations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the recipient. (format: email, e.g. marcelina.davis@example.com)
  --organization-id: string # The ID of the [organization](/reference/organization) that the recipient will join. (e.g. org_01E4ZCR3C56J083X43JQXF3JK5)
  --role-slug: string # The [role](/authkit/roles) that the recipient will receive when they join the organization in the invitation. (e.g. admin)
  --expires-in-days: int # How many days the invitations will be valid for. Must be between 1 and 30 days. Defaults to 7 days if not specified. (e.g. 7)
  --inviter-user-id: string # The ID of the [user](/reference/authkit/user) who invites the recipient. The invitation email will mention the name of this user. (e.g. user_01HYGBX8ZGD19949T3BM4FW1C3)
  --locale: string@locale-completer # The locale to use when rendering the invitation email. See [supported locales](/authkit/hosted-ui/localization). (e.g. en)
]: any -> record<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/invitations")
  let body = {email: $email, organization_id: $organization_id, role_slug: $role_slug, expires_in_days: $expires_in_days, inviter_user_id: $inviter_user_id, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find an invitation by token
#
# GET /user_management/invitations/by_token/{token}
# operationId: UserlandUserInvitesController_getByToken
export def "user-management-invitations-by-token get" [
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/invitations/by_token/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an invitation
#
# GET /user_management/invitations/{id}
# operationId: UserlandUserInvitesController_get
export def "user-management-invitations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/invitations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept an invitation
#
# POST /user_management/invitations/{id}/accept
# operationId: UserlandUserInvitesController_accept
export def "user-management-invitations-accept accept" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/invitations/($id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend an invitation
#
# POST /user_management/invitations/{id}/resend
# operationId: UserlandUserInvitesController_resend
export def "user-management-invitations-resend resend" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string@locale-completer # The locale to use when rendering the invitation email. See [supported locales](/authkit/hosted-ui/localization). (e.g. en)
]: any -> record<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/invitations/($id)/resend")
  let body = {locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke an invitation
#
# POST /user_management/invitations/{id}/revoke
# operationId: UserlandUserInvitesController_revoke
export def "user-management-invitations-revoke revoke" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, email: string, state: string, accepted_at: string, revoked_at: string, expires_at: string, organization_id: string, inviter_user_id: string, accepted_user_id: string, role_slug: string, created_at: string, updated_at: string, token: string, accept_invitation_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/invitations/($id)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get JWT template
#
# GET /user_management/jwt_template
# operationId: JwtTemplatesController_getJwtTemplate
export def "user-management-jwt-template get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, content: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/jwt_template")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update JWT template
#
# PUT /user_management/jwt_template
# operationId: JwtTemplatesController_updateJwtTemplate
export def "user-management-jwt-template updateJwtTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The JWT template content as a Liquid template string. (e.g. {"urn:myapp:full_name": "{{user.first_name}} {{user.last_name}}", "urn:myapp:email": "{{user.email}}"})
]: any -> record<object: string, content: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/jwt_template")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Magic Auth code
#
# POST /user_management/magic_auth
# operationId: UserlandMagicAuthController_sendMagicAuthCodeAndReturn
export def "user-management-magic-auth sendMagicAuthCodeAndReturn" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address to send the magic code to. (format: email, e.g. marcelina.davis@example.com)
  --invitation-token: string # The invitation token to associate with this magic code. (e.g. Z1Y2X3W4V5U6T7S8R9Q0P1O2N3)
]: any -> record<object: string, id: string, user_id: string, email: string, expires_at: string, created_at: string, updated_at: string, code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/magic_auth")
  let body = {email: $email, invitation_token: $invitation_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Magic Auth code details
#
# GET /user_management/magic_auth/{id}
# operationId: UserlandMagicAuthController_get
export def "user-management-magic-auth get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, user_id: string, email: string, expires_at: string, created_at: string, updated_at: string, code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/magic_auth/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization memberships
#
# GET /user_management/organization_memberships
# operationId: UserlandUserOrganizationMembershipsController_list
export def "user-management-organization-memberships list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --organization-id: string # The ID of the [organization](/reference/organization) which the user belongs to. (e.g. org_01E4ZCR3C56J083X43JQXF3JK5)
  --statuses: list # Filter by the status of the organization membership. Array including any of `active`, `inactive`, or `pending`. (e.g. [active])
  --user-id: string # The ID of the [user](/reference/authkit/user). (e.g. user_01E4ZCR3C5A4QZ2Z2JQXGKZJ9E)
]: nothing -> record<object: string, list_metadata: record<before: string, after: string>, data: table<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, role: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "statuses" $statuses "csv") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_management/organization_memberships" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an organization membership
#
# POST /user_management/organization_memberships
# operationId: UserlandUserOrganizationMembershipsController_create
export def "user-management-organization-memberships create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The ID of the [user](/reference/authkit/user). (e.g. user_01E4ZCR3C5A4QZ2Z2JQXGKZJ9E)
  organization_id: string # The ID of the [organization](/reference/organization) which the user belongs to. (e.g. org_01E4ZCR3C56J083X43JQXF3JK5)
]: any -> record<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, role: record<slug: string>, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/organization_memberships")
  let body = {user_id: $user_id, organization_id: $organization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an organization membership
#
# GET /user_management/organization_memberships/{id}
# operationId: UserlandUserOrganizationMembershipsController_get
export def "user-management-organization-memberships get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, role: record<slug: string>, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/organization_memberships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an organization membership
#
# DELETE /user_management/organization_memberships/{id}
# operationId: UserlandUserOrganizationMembershipsController_delete
export def "user-management-organization-memberships delete" [
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
  let full_url = (build-url $base $"/user_management/organization_memberships/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization membership
#
# PUT /user_management/organization_memberships/{id}
# operationId: UserlandUserOrganizationMembershipsController_update
export def "user-management-organization-memberships update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role-slug: string # A single role identifier. Defaults to `member` or the explicit default role. Mutually exclusive with `role_slugs`. (e.g. admin)
  --role-slugs: list # An array of role identifiers. Limited to one role when Multiple Roles is disabled. Mutually exclusive with `role_slug`. (e.g. [admin])
]: any -> record<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, role: record<slug: string>, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/organization_memberships/($id)")
  let body = {role_slug: $role_slug, role_slugs: $role_slugs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate an organization membership
#
# PUT /user_management/organization_memberships/{id}/deactivate
# operationId: UserlandUserOrganizationMembershipsController_deactivate
export def "user-management-organization-memberships-deactivate deactivate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, role: record<slug: string>, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/organization_memberships/($id)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivate an organization membership
#
# PUT /user_management/organization_memberships/{id}/reactivate
# operationId: UserlandUserOrganizationMembershipsController_reactivate
export def "user-management-organization-memberships-reactivate reactivate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, user_id: string, organization_id: string, status: string, directory_managed: bool, organization_name: string, custom_attributes: record, created_at: string, updated_at: string, role: record<slug: string>, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/organization_memberships/($id)/reactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List groups
#
# GET /user_management/organization_memberships/{omId}/groups
# operationId: OrganizationMembershipGroupsController_listGroups
export def "user-management-organization-memberships-groups listGroups" [
  omId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, organization_id: string, name: string, description: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/organization_memberships/($omId)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a password reset token
#
# POST /user_management/password_reset
# operationId: UserlandUsersController_createPasswordResetToken
export def "user-management-password-reset createPasswordResetToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the user requesting a password reset. (format: email, e.g. marcelina.davis@example.com)
]: any -> record<object: string, id: string, user_id: string, email: string, expires_at: string, created_at: string, password_reset_token: string, password_reset_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/password_reset")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the password
#
# POST /user_management/password_reset/confirm
# operationId: UserlandUsersController_resetPassword[0]
export def "user-management-password-reset-confirm resetPassword0" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The password reset token. (e.g. Z1Y2X3W4V5U6T7S8R9Q0P1O2N3)
  new_password: string # The new password to set for the user. (e.g. strong_password_123!)
]: any -> record<user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/password_reset/confirm")
  let body = {token: $body_token, new_password: $new_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a password reset token
#
# GET /user_management/password_reset/{id}
# operationId: UserlandUsersController_getPasswordReset
export def "user-management-password-reset get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, user_id: string, email: string, expires_at: string, created_at: string, password_reset_token: string, password_reset_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/password_reset/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a redirect URI
#
# POST /user_management/redirect_uris
# operationId: RedirectUrisController_create
export def "user-management-redirect-uris create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  uri: string # The redirect URI to create. (e.g. https://example.com/callback)
]: any -> record<object: string, id: string, uri: string, default: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/redirect_uris")
  let body = {uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Logout
#
# GET /user_management/sessions/logout
# operationId: UserlandSessionsController_logout
export def "user-management-sessions-logout logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session-id: string # The ID of the session. This can be extracted from the `sid` claim of the access token. (e.g. session_01H93ZY4F80QPBEZ1R5B2SHQG8)
  --return-to: string # The URL to redirect the user to after logout. (e.g. https://example.com)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "session_id" $session_id "scalar") (serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_management/sessions/logout" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke Session
#
# POST /user_management/sessions/revoke
# operationId: UserlandSessionsController_revokeSession
export def "user-management-sessions-revoke revokeSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  session_id: string # The ID of the session to revoke. This can be extracted from the `sid` claim of the access token. (e.g. session_01H93ZY4F80QPBEZ1R5B2SHQG8)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/sessions/revoke")
  let body = {session_id: $session_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /user_management/users
# operationId: UserlandUsersController_list[0]
@deprecated --flag organization
export def "user-management-users list0" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
  --organization: string # Filter users by the organization they are a member of. Deprecated in favor of `organization_id`. (DEPRECATED, e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --organization-id: string # Filter users by the organization they are a member of. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --email: string # Filter users by their email address. (e.g. user@example.com)
]: nothing -> record<object: string, data: table<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user_management/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /user_management/users
# operationId: UserlandUsersController_create[0]
export def "user-management-users create0" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the user. (format: email, e.g. marcelina.davis@example.com)
  --first-name: string # The first name of the user. (nullable, e.g. Marcelina)
  --last-name: string # The last name of the user. (nullable, e.g. Davis)
  --name: string # The user's full name. (nullable, e.g. Marcelina Davis)
  --email-verified: string@bool-completer # Whether the user's email has been verified. (nullable, e.g. true)
  --metadata: record # Object containing metadata key/value pairs associated with the user. (nullable, e.g. {timezone: America/New_York})
  --external-id: string # The external ID of the user. (nullable, e.g. f1ffa2b2-c20b-4d39-be5c-212726e11222)
]: any -> record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_management/users")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, name: $name, email_verified: $email_verified, metadata: $metadata, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user by external ID
#
# GET /user_management/users/external_id/{external_id}
# operationId: UserlandUsersController_getByExternalId
export def "user-management-users-external-id get" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/external_id/($external_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /user_management/users/{id}
# operationId: UserlandUsersController_update[0]
export def "user-management-users update0" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the user. (format: email, e.g. marcelina.davis@example.com)
  --first-name: string # The first name of the user. (e.g. Marcelina)
  --last-name: string # The last name of the user. (e.g. Davis)
  --name: string # The user's full name. (e.g. Marcelina Davis)
  --email-verified: string@bool-completer # Whether the user's email has been verified. (e.g. true)
  --metadata: record # Object containing metadata key/value pairs associated with the user. (nullable, e.g. {timezone: America/New_York})
  --external-id: string # The external ID of the user. (nullable, e.g. f1ffa2b2-c20b-4d39-be5c-212726e11222)
  --locale: string # The user's preferred locale. (nullable, e.g. en-US)
]: any -> record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, name: $name, email_verified: $email_verified, metadata: $metadata, external_id: $external_id, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a user
#
# GET /user_management/users/{id}
# operationId: UserlandUsersController_get[0]
export def "user-management-users get0" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /user_management/users/{id}
# operationId: UserlandUsersController_delete[0]
export def "user-management-users delete0" [
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
  let full_url = (build-url $base $"/user_management/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirm email change
#
# POST /user_management/users/{id}/email_change/confirm
# operationId: UserlandUsersController_confirmEmailChange
export def "user-management-users-email-change-confirm confirmEmailChange" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The one-time code used to confirm the email change. (e.g. 123456)
]: any -> record<object: string, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)/email_change/confirm")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send email change code
#
# POST /user_management/users/{id}/email_change/send
# operationId: UserlandUsersController_sendEmailChange
export def "user-management-users-email-change-send sendEmailChange" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  new_email: string # The new email address to change to. (e.g. new.email@example.com)
]: any -> record<object: string, user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>, new_email: string, expires_at: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)/email_change/send")
  let body = {new_email: $new_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify email
#
# POST /user_management/users/{id}/email_verification/confirm
# operationId: UserlandUsersController_emailVerification[0]
export def "user-management-users-email-verification-confirm emailVerification0" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # The one-time email verification code. (e.g. 123456)
]: any -> record<user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)/email_verification/confirm")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send verification email
#
# POST /user_management/users/{id}/email_verification/send
# operationId: UserlandUsersController_sendVerificationEmail[0]
export def "user-management-users-email-verification-send sendVerificationEmail0" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<object: string, id: string, first_name: string, last_name: string, name: string, profile_picture_url: string, email: string, email_verified: bool, external_id: string, metadata: record, last_sign_in_at: string, locale: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)/email_verification/send")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user identities
#
# GET /user_management/users/{id}/identities
# operationId: UserlandUserIdentitiesController_get
export def "user-management-users-identities get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<idp_id: string, type: string, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($id)/identities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List sessions
#
# GET /user_management/users/{id}/sessions
# operationId: UserlandUserSessionsController_list
export def "user-management-users-sessions list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, list_metadata: record<before: string, after: string>, data: table<object: string, id: string, impersonator: record, ip_address: string, organization_id: string, user_agent: string, user_id: string, auth_method: string, status: string, expires_at: string, ended_at: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List API keys for a user
#
# GET /user_management/users/{userId}/api_keys
# operationId: UserApiKeysController_list
export def "user-management-users-api-keys list" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
  --organization-id: string # The ID of the organization to filter user API keys by. When provided, only API keys created against that organization membership are returned. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: nothing -> record<object: string, data: table<object: string, id: string, owner: record, name: string, obfuscated_value: string, last_used_at: string, expires_at: string, permissions: list, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($userId)/api_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API key for a user
#
# POST /user_management/users/{userId}/api_keys
# operationId: UserApiKeysController_create
export def "user-management-users-api-keys create" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # A descriptive name for the API key. (e.g. Production API Key)
  organization_id: string # The ID of the organization the user API key is associated with. The user must have an active membership in this organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --permissions: list # The permission slugs to assign to the API key. Each permission must be enabled for user API keys. (e.g. [posts:read, posts:write])
  --expires-at: string # The timestamp when the API key should expire. Must be a future timestamp. If omitted, the key does not expire. (format: date-time, e.g. 2030-01-01T00:00:00.000Z)
]: any -> record<object: string, id: string, owner: record<type: string, id: string, organization_id: string>, name: string, obfuscated_value: string, last_used_at: string, expires_at: string, permissions: list<string>, created_at: string, updated_at: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($userId)/api_keys")
  let body = {name: $name, organization_id: $organization_id, permissions: $permissions, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List enabled feature flags for a user
#
# GET /user_management/users/{userId}/feature-flags
# operationId: UserlandUserFeatureFlagsController_list
export def "user-management-users-feature-flags list" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, slug: string, name: string, description: string, owner: any, tags: list, enabled: bool, default_value: bool, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($userId)/feature-flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List authorized applications
#
# GET /user_management/users/{user_id}/authorized_applications
# operationId: AuthorizedApplicationsController_list
export def "user-management-users-authorized-applications list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, granted_scopes: list, oauth_resource: string, application: record>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($user_id)/authorized_applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an authorized application
#
# DELETE /user_management/users/{user_id}/authorized_applications/{application_id}
# operationId: AuthorizedApplicationsController_delete
export def "user-management-users-authorized-applications delete" [
  application_id: string
  user_id: string
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
  let full_url = (build-url $base $"/user_management/users/($user_id)/authorized_applications/($application_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a connected account
#
# GET /user_management/users/{user_id}/connected_accounts/{slug}
# operationId: DataIntegrationsUserManagementController_getUserDataInstallation
export def "user-management-users-connected-accounts get" [
  user_id: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string # An [Organization](/reference/organization) identifier. Optional parameter if the connection is scoped to an organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: nothing -> record<object: string, id: string, user_id: string, organization_id: string, scopes: list<string>, state: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($user_id)/connected_accounts/($slug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a connected account
#
# DELETE /user_management/users/{user_id}/connected_accounts/{slug}
# operationId: DataIntegrationsUserManagementController_deleteUserDataInstallation
export def "user-management-users-connected-accounts delete" [
  user_id: string
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string # An [Organization](/reference/organization) identifier. Optional parameter if the connection is scoped to an organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($user_id)/connected_accounts/($slug)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List providers
#
# GET /user_management/users/{user_id}/data_providers
# operationId: DataIntegrationsUserManagementController_getUserDataIntegrations
export def "user-management-users-data-providers get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string # An [Organization](/reference/organization) identifier. Optional parameter to filter connections for a specific organization. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
]: nothing -> record<object: string, data: table<object: string, id: string, name: string, description: string, slug: string, integration_type: string, credentials_type: string, scopes: any, ownership: string, created_at: string, updated_at: string, integrationType: string, credentialsType: string, createdAt: string, updatedAt: string, connected_account: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($user_id)/data_providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enroll an authentication factor
#
# POST /user_management/users/{userlandUserId}/auth_factors
# operationId: UserlandUserAuthenticationFactorsController_create[0]
export def "user-management-users-auth-factors create0" [
  userlandUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string # The type of the factor to enroll. (e.g. totp)
  --totp-issuer: string # Your application or company name displayed in the user's authenticator app. (e.g. WorkOS)
  --totp-user: string # The user's account name displayed in their authenticator app. (e.g. user@example.com)
  --totp-secret: string # The Base32-encoded shared secret for TOTP factors. This can be provided when creating the auth factor, otherwise it will be generated. The algorithm used to derive TOTP codes is SHA-1, the code length is 6 digits, and the timestep is 30 seconds – the secret must be compatible with these parameters. (e.g. JBSWY3DPEHPK3PXP)
]: any -> record<authentication_factor: record<object: string, id: string, type: string, user_id: string, sms: record<phone_number: string>, totp: record<issuer: string, user: string, secret: string, qr_code: string, uri: string>, created_at: string, updated_at: string>, authentication_challenge: record<object: string, id: string, expires_at: string, code: string, authentication_factor_id: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/user_management/users/($userlandUserId)/auth_factors")
  let body = {type: $type, totp_issuer: $totp_issuer, totp_user: $totp_user, totp_secret: $totp_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List authentication factors
#
# GET /user_management/users/{userlandUserId}/auth_factors
# operationId: UserlandUserAuthenticationFactorsController_list[0]
export def "user-management-users-auth-factors list0" [
  userlandUserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. (e.g. obj_1234567890)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, type: string, user_id: string, sms: record, totp: record, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/user_management/users/($userlandUserId)/auth_factors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a data key
#
# POST /vault/v1/keys/data-key
# operationId: JumpWireWeb.KeyController.create_data_key
export def "vault-keys-data-key key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  context: record # Map of values used to determine the encryption key. (e.g. {organization_id: org_01K8ZYT4AWJ6XP0E0S8CTBHE3P})
]: any -> record<context: record, data_key: string, encrypted_keys: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vault/v1/keys/data-key")
  let body = {context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Decrypt a data key
#
# POST /vault/v1/keys/decrypt
# operationId: JumpWireWeb.KeyController.decrypt
export def "vault-keys-decrypt JumpWireWebKeyControllerdecrypt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  keys: string # Base64-encoded encrypted data key to decrypt. (e.g. V09TLkVLTS52MQBiZjUxY2NlYy03OGI0LTUyMDAtYjM4My0zNTczMGU3MWVmNjEBATEBJGJmNjVlMzI2LTQzYTAtNGIyMC04OGM0LTA3ZmYzZGU1NDM0YwF0YmY2NWUzMjYtNDNhMC00YjIwLTg4YzQtMDdmZjNkZTU0MzRj)
]: any -> record<data_key: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vault/v1/keys/decrypt")
  let body = {keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Re-encrypt a data key
#
# POST /vault/v1/keys/rekey
# operationId: JumpWireWeb.KeyController.rekey
export def "vault-keys-rekey JumpWireWebKeyControllerrekey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  context: record # Map of values used to determine the new encryption key. (e.g. {organization_id: org_01K8ZYT4AWJ6XP0E0S8CTBHE3P})
  encrypted_keys: string # Base64-encoded encrypted data key blob to re-encrypt. (e.g. V09TLkVLTS52MQBiZjUxY2NlYy03OGI0LTUyMDAtYjM4My0zNTczMGU3MWVmNjEBATEBJGJmNjVlMzI2LTQzYTAtNGIyMC04OGM0LTA3ZmYzZGU1NDM0YwF0YmY2NWUzMjYtNDNhMC00YjIwLTg4YzQtMDdmZjNkZTU0MzRj)
]: any -> record<context: record, data_key: string, encrypted_keys: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vault/v1/keys/rekey")
  let body = {context: $context, encrypted_keys: $encrypted_keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List objects
#
# GET /vault/v1/kv
# operationId: JumpWireWeb.DataVaultController.index
export def "vault-kv JumpWireWebDataVaultControllerindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Upper limit on the number of objects to return. (default: 10, e.g. 10)
  --before: string # Cursor for the previous page of results. (e.g. b21f3a8c-7e4d-4b1a-9c5e-2d8f6a7b3c4e)
  --after: string # Cursor for the next page of results. (e.g. a10e2b7d-6c3f-4a2b-8d1e-3f9a5b8c7d6e)
  --order: string@order-completer-1 # Sort direction for results. (e.g. desc)
  --search: string # Filter results by name or structured search JSON. (e.g. my-secret)
  --updatedAfter: string # ISO 8601 timestamp to filter by last modified time. (format: date-time, e.g. 2024-01-01T00:00:00Z)
]: nothing -> record<data: table<id: string, name: string, updated_at: string>, list_metadata: record<after: string, before: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "updatedAfter" $updatedAfter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/v1/kv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an object
#
# POST /vault/v1/kv
# operationId: JumpWireWeb.DataVaultController.create
export def "vault-kv JumpWireWebDataVaultControllercreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key_context: record # Map of values used to determine the encryption key. (e.g. {organization_id: org_01K8ZYT4AWJ6XP0E0S8CTBHE3P})
  name: string # Unique name for the object. (e.g. my-secret)
  value: string # Plaintext data to encrypt and store. (e.g. s3cr3t-v4lu3)
]: any -> record<context: record, environment_id: string, id: string, key_id: string, updated_at: string, updated_by: record<id: string, name: string>, version_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vault/v1/kv")
  let body = {key_context: $key_context, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Read an object by name
#
# GET /vault/v1/kv/name/{name}
# operationId: JumpWireWeb.DataVaultController.show_by_name
export def "vault-kv-name name" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metadata: record<context: record, environment_id: string, id: string, key_id: string, updated_at: string, updated_by: record<id: string, name: string>, version_id: string>, name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vault/v1/kv/name/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an object
#
# DELETE /vault/v1/kv/{id}
# operationId: JumpWireWeb.DataVaultController.delete
export def "vault-kv JumpWireWebDataVaultControllerdelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --version-check: string # Expected current version for optimistic locking. (e.g. c3d4e5f6-7890-abcd-ef12-34567890abcd)
]: nothing -> record<name: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version_check" $version_check "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vault/v1/kv/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Read an object by ID
#
# GET /vault/v1/kv/{id}
# operationId: JumpWireWeb.DataVaultController.show_by_id
export def "vault-kv id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metadata: record<context: record, environment_id: string, id: string, key_id: string, updated_at: string, updated_by: record<id: string, name: string>, version_id: string>, name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vault/v1/kv/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an object
#
# PUT /vault/v1/kv/{id}
# operationId: JumpWireWeb.DataVaultController.update
export def "vault-kv JumpWireWebDataVaultControllerupdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # New plaintext value. (e.g. upd4t3d-v4lu3)
  --version-check: string # ID of the expected current version for optimistic locking. (nullable, e.g. c3d4e5f6-7890-abcd-ef12-34567890abcd)
]: any -> record<id: string, metadata: record<context: record, environment_id: string, id: string, key_id: string, updated_at: string, updated_by: record<id: string, name: string>, version_id: string>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vault/v1/kv/($id)")
  let body = {value: $value, version_check: $version_check} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Describe an object
#
# GET /vault/v1/kv/{id}/metadata
# operationId: JumpWireWeb.DataVaultController.describe
export def "vault-kv-metadata JumpWireWebDataVaultControllerdescribe" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, metadata: record<context: record, environment_id: string, id: string, key_id: string, updated_at: string, updated_by: record<id: string, name: string>, version_id: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vault/v1/kv/($id)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List object versions
#
# GET /vault/v1/kv/{id}/versions
# operationId: JumpWireWeb.DataVaultController.versions
export def "vault-kv-versions JumpWireWebDataVaultControllerversions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<created_at: string, current_version: bool, etag: string, id: string, size: int>, list_metadata: record<after: string, before: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vault/v1/kv/($id)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webhook Endpoints
#
# GET /webhook_endpoints
# operationId: WebhookEndpointsController_list
export def "webhook-endpoints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `before="obj_123"` to fetch a new batch of objects before `"obj_123"`. (e.g. xxx_01HXYZ123456789ABCDEFGHIJ)
  --after: string # An object ID that defines your place in the list. When the ID is not present, you are at the end of the list. For example, if you make a list request and receive 100 objects, ending with `"obj_123"`, your subsequent call can include `after="obj_123"` to fetch a new batch of objects after `"obj_123"`. (e.g. xxx_01HXYZ987654321KJIHGFEDCBA)
  --limit: int # Upper limit on the number of objects to return, between `1` and `100`. (default: 10, e.g. 10)
  --order: string@order-completer # Order the results by the creation time. Supported values are `"asc"` (ascending), `"desc"` (descending), and `"normal"` (descending with reversed cursor semantics where `before` fetches older records and `after` fetches newer records). (default: desc, e.g. desc)
]: nothing -> record<object: string, data: table<object: string, id: string, endpoint_url: string, secret: string, status: string, events: list, created_at: string, updated_at: string>, list_metadata: record<before: string, after: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook_endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Webhook Endpoint
#
# POST /webhook_endpoints
# operationId: WebhookEndpointsController_create
export def "webhook-endpoints create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endpoint_url: string # The HTTPS URL where webhooks will be sent. (e.g. https://example.com/webhooks)
  events: list # The events that the Webhook Endpoint is subscribed to. (e.g. [user.created, dsync.user.created])
]: any -> record<object: string, id: string, endpoint_url: string, secret: string, status: string, events: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_endpoints")
  let body = {endpoint_url: $endpoint_url, events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a Webhook Endpoint
#
# PATCH /webhook_endpoints/{id}
# operationId: WebhookEndpointsController_update
export def "webhook-endpoints update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpoint-url: string # The HTTPS URL where webhooks will be sent. (e.g. https://example.com/webhooks)
  --status: string@status-completer # Whether the Webhook Endpoint is enabled or disabled. (e.g. enabled)
  --events: list # The events that the Webhook Endpoint is subscribed to. (e.g. [user.created, dsync.user.created])
]: any -> record<object: string, id: string, endpoint_url: string, secret: string, status: string, events: list<string>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhook_endpoints/($id)")
  let body = {endpoint_url: $endpoint_url, status: $status, events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Webhook Endpoint
#
# DELETE /webhook_endpoints/{id}
# operationId: WebhookEndpointsController_delete
export def "webhook-endpoints delete" [
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
  let full_url = (build-url $base $"/webhook_endpoints/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a widget token
#
# POST /widgets/token
# operationId: WidgetsPublicController_issueWidgetSessionToken
export def "widgets-token issueWidgetSessionToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # The ID of the organization to scope the widget session to. (e.g. org_01EHZNVPK3SFK441A1RGBFSHRT)
  --user-id: string # The ID of the user to issue the widget session token for. (e.g. user_01E4ZCR3C56J083X43JQXF3JK5)
  --scopes: list # The scopes to grant the widget session. (e.g. [widgets:users-table:manage])
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/widgets/token")
  let body = {organization_id: $organization_id, user_id: $user_id, scopes: $scopes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
